"""Real Tern/X11 workflows, isolated from the user's config and session daemon.

Run from the repository root with Tern 0.9.10+ on PATH:
  nix-shell pkgs/tern-plugins/tests/shell.nix --run \
    'xvfb-run -a uv run --no-project --with pytest python -m pytest pkgs/tern-plugins/tests -v'
"""

import json
import os
import shutil
import signal
import subprocess
import tempfile
import time
from pathlib import Path

import pytest

PLUGIN_ROOT = Path(__file__).resolve().parents[1]
TIMEOUT = 15


class Tern:
    def __init__(self, root):
        self.root = root
        self.control = str(root / "control.sock")
        self.env = os.environ.copy()
        self.env.pop("WAYLAND_DISPLAY", None)
        for key in ("TERN_PANE", "TERN_WINDOW_KEY"):
            self.env.pop(key, None)
        self.env.update(
            TERN_CONFIG_DIR=str(root / "config"),
            TERN_DAEMON_SOCKET=str(root / "daemon.sock"),
            XDG_STATE_HOME=str(root / "state"),
            XDG_SESSION_TYPE="x11",
            STENCIL_GPU="cpu",
        )
        self.binary = shutil.which(os.environ.get("TERN_BIN", "tern"))
        assert self.binary, "Tern must be installed before running these tests"
        self.processes = []
        self.log = (root / "process.log").open("w+")
        self.window = None

    def start(self):
        plugins = self.root / "config" / "plugins"
        plugins.mkdir(parents=True)
        for name in ("spaces", "multiplexer"):
            source = self.root / "sources" / name
            shutil.copytree(PLUGIN_ROOT / name, source)
            (plugins / f"{name}.path").write_text(str(source))
        # Start the daemon ourselves so teardown owns its exact process, not a PID search.
        self.processes.append(
            self.spawn("daemon", "--socket", self.env["TERN_DAEMON_SOCKET"])
        )
        self.until(lambda: Path(self.env["TERN_DAEMON_SOCKET"]).exists())
        self.processes.append(self.spawn("--control", self.control, str(self.root)))
        self.until(lambda: Path(self.control).exists())
        self.ctl("account", "signed-in", "workflow-test")
        self.ctl("plugins", "run", "plugin.multiplexer.use_herdr")
        result = subprocess.run(
            ["xdotool", "search", "--sync", "--onlyvisible", "--class", "tern"],
            env=self.env,
            capture_output=True,
            text=True,
            check=True,
            timeout=TIMEOUT,
        )
        self.window = result.stdout.splitlines()[-1]
        self.until(lambda: self.snapshot()["tabs"])

    def spawn(self, *args):
        return subprocess.Popen(
            [self.binary, *args],
            env=self.env,
            stdout=self.log,
            stderr=self.log,
            start_new_session=True,
        )

    def close(self):
        for process in reversed(self.processes):
            if process.poll() is None:
                os.killpg(process.pid, signal.SIGTERM)
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    os.killpg(process.pid, signal.SIGKILL)
                    process.wait(timeout=5)
        self.log.close()

    def ctl(self, *args):
        result = subprocess.run(
            [self.binary, "ctl", "--control", self.control, *args],
            env=self.env,
            capture_output=True,
            text=True,
            check=True,
            timeout=TIMEOUT,
        )
        result = json.loads(result.stdout)
        assert result.get("ok"), result
        return result

    def lua(self, code):
        self.ctl("carly", "lua", json.dumps(code))
        result = self.ctl("state")["carly"]["last_tool"]
        self.ctl("carly", "close")
        assert not result["error"], result["text"]
        return result["text"]

    def snapshot(self):
        result = self.lua(
            "return tern.json.encode({sessions=cx.sessions:list(), "
            "tabs=cx.session:tabs(), panes=cx.session:panes(), "
            "focused=cx.session:focused(), panels=cx.canvas:list(), hosts=cx.hosts:list()})"
        )
        result = json.loads(result.split("→ ", 1)[1])
        # Empty Luau tables can encode as objects.
        for key in ("sessions", "tabs", "panes", "panels", "hosts"):
            result[key] = result[key] or []
        return result

    def keys(self, *keys):
        subprocess.run(
            [
                "xdotool",
                "windowfocus",
                "--sync",
                self.window,
                "key",
                "--clearmodifiers",
                *keys,
            ],
            env=self.env,
            check=True,
            timeout=TIMEOUT,
        )

    def run(self, command):
        self.ctl("run", json.dumps(command))

    def until(self, predicate):
        deadline = time.monotonic() + TIMEOUT
        last = None
        while time.monotonic() < deadline:
            for process in self.processes:
                if process.poll() is not None:
                    raise AssertionError(self.root.joinpath("process.log").read_text())
            last = predicate()
            if last:
                return last
            time.sleep(0.1)
        raise AssertionError(
            f"Workflow did not settle within {TIMEOUT}s; last result: {last}"
        )

    def tabs(self, session):
        return [tab for tab in self.snapshot()["tabs"] if tab["session"] == session]

    def current(self):
        return next(row for row in self.snapshot()["sessions"] if row["current"])

    def terminal(self):
        state = self.snapshot()
        return next(pane for pane in state["panes"] if pane["pane"] == state["focused"])

    def read_terminal(self, pane):
        text = self.lua(f"return tern.json.encode(cx.session:read({pane}))")
        return "\n".join(json.loads(text.split("→ ", 1)[1])["lines"])

    def panel_tree(self):
        return self.ctl("tree", ".spaces-sidebar")["nodes"]


@pytest.fixture
def tern():
    assert os.environ.get("DISPLAY"), "Run these tests inside xvfb-run"
    # Unix-domain socket paths have a small fixed limit; pytest test names exceed it.
    with tempfile.TemporaryDirectory(prefix="tern-test-", dir="/tmp") as directory:
        instance = Tern(Path(directory))
        try:
            instance.start()
            yield instance
        finally:
            instance.close()


def test_space_inherits_cwd_and_only_its_name_follows_cd(tern):
    alpha, beta = tern.root / "alpha", tern.root / "beta"
    alpha.mkdir()
    beta.mkdir()
    tern.run(f"cd {alpha}")
    tern.until(lambda: tern.current()["name"] == "alpha")
    first = tern.current()["id"]
    first_tabs = {tab["id"] for tab in tern.tabs(first)}
    tern.keys("ctrl+b", "shift+n")
    tern.until(lambda: tern.current()["id"] != first)
    second = tern.current()["id"]
    tern.until(lambda: tern.terminal().get("cwd") == str(alpha))
    assert tern.current()["name"] == "alpha"
    assert not tern.ctl("tree", "input")["nodes"]
    tern.run(f"cd {beta}")
    tern.until(lambda: tern.current()["name"] == "beta")
    state = tern.snapshot()
    assert next(s for s in state["sessions"] if s["id"] == first)["name"] == "alpha"
    assert {tab["id"] for tab in state["tabs"] if tab["session"] == first} == first_tabs
    assert tern.current()["id"] == second


def test_custom_space_name_survives_cd_and_plugin_reload(tern):
    first = tern.current()["id"]
    first_name = tern.current()["name"]
    first_pane = tern.terminal()["pane"]
    tern.keys("ctrl+b", "shift+n")
    tern.until(lambda: tern.current()["id"] != first)
    second = tern.current()["id"]

    def rename_prompt(name):
        row = next(
            node
            for node in tern.ctl("tree", ".space-name button")["nodes"]
            if node["text"] == name
        )
        x, y, width, height = row["rect"]
        tern.ctl("click", str(x + width / 2), str(y + height / 2), "right")
        menu = tern.until(
            lambda: [
                node
                for node in tern.ctl("tree", ".pop .mi")["nodes"]
                if node["text"] == "Rename"
            ]
        )[0]
        x, y, width, height = menu["rect"]
        tern.ctl("click", str(x + width / 2), str(y + height / 2))
        tern.until(lambda: tern.ctl("tree", "input")["nodes"])
        assert tern.current()["id"] == second

    rename_prompt(first_name)
    tern.keys("Escape")
    assert (
        next(s for s in tern.snapshot()["sessions"] if s["id"] == first)["name"]
        == first_name
    )
    rename_prompt(first_name)
    tern.ctl("select-text", "0", str(len(first_name.encode())))
    tern.ctl("type", json.dumps("  Release workspace  "))
    tern.keys("Return")
    tern.until(lambda: "Release workspace" in tern.panel_tree()[0]["text"])
    assert tern.current()["id"] == second
    subprocess.run(
        [tern.binary, "plugin", "reload", "spaces"],
        env=tern.env,
        check=True,
        timeout=TIMEOUT,
    )
    tern.lua(f"cx.sessions:switch({first}); cx.layout:focus({first_pane})")
    tern.until(lambda: tern.current()["id"] == first)
    target = tern.root / "different-directory"
    target.mkdir()
    tern.run(f"cd {target}")
    tern.until(lambda: tern.terminal().get("cwd") == str(target))
    assert tern.current()["name"] == "Release workspace"
    assert (
        next(s for s in tern.snapshot()["sessions"] if s["id"] == second)["name"]
        != "Release workspace"
    )


@pytest.mark.parametrize(
    "sidebar_close",
    [("ctrl+shift+w",), ("ctrl+b", "x"), ("ctrl+b", "ctrl+x")],
    ids=["direct", "prefix-released", "prefix-held"],
)
def test_close_from_sidebar_preserves_other_spaces_and_falls_back(tern, sidebar_close):
    first = tern.current()["id"]
    tern.run("printf 'SURVIVING_TERMINAL\\n'")
    survivor = tern.terminal()["pane"]
    tern.keys("ctrl+b", "c")
    tern.until(lambda: len(tern.tabs(first)) == 2)
    original = {tab["id"] for tab in tern.tabs(first)}
    tern.keys("ctrl+b", "shift+n")
    tern.until(lambda: tern.current()["id"] != first)
    second = tern.current()["id"]
    tern.keys("ctrl+b", "c")
    tern.until(lambda: len(tern.tabs(second)) == 2)
    second_tabs = tern.tabs(second)
    tern.keys("ctrl+b", "v")
    tern.until(
        lambda: (
            sum(
                p.get("kind") == "terminal" and p["tab"] == second_tabs[1]["id"]
                for p in tern.snapshot()["panes"]
            )
            == 2
        )
    )
    split_terminals = {
        p["pane"]
        for p in tern.snapshot()["panes"]
        if p.get("kind") == "terminal" and p["tab"] == second_tabs[1]["id"]
    }
    tern.keys("ctrl+b", "1")
    tern.until(lambda: tern.terminal()["pane"] == second_tabs[0]["pane"])
    tern.keys("ctrl+b", "w", "1")
    tern.until(lambda: tern.current()["id"] == first)
    tern.keys("ctrl+b", "w", "2")
    tern.until(lambda: tern.current()["id"] == second)
    focused_tab = tern.terminal()["tab"]
    state = tern.snapshot()
    panel_ids = {p["pane"] for p in state["panels"] if p["owner"] == "spaces"}
    panel = next(
        p["pane"]
        for p in state["panes"]
        if p["tab"] == focused_tab and p["pane"] in panel_ids
    )
    tern.lua(f"cx.layout:focus({panel})")
    tern.keys(*sidebar_close)
    tern.until(lambda: len(tern.tabs(second)) == 1)
    assert {tab["id"] for tab in tern.tabs(second)} == {
        tab["id"] for tab in second_tabs if tab["id"] != focused_tab
    }
    assert {tab["id"] for tab in tern.tabs(first)} == original
    assert "SURVIVING_TERMINAL" in tern.read_terminal(survivor)
    tern.keys("ctrl+b", "x")
    tern.until(lambda: tern.current()["id"] == first)
    assert not tern.tabs(second)
    tern.until(lambda: second not in {s["id"] for s in tern.snapshot()["sessions"]})
    assert not split_terminals.intersection(p["pane"] for p in tern.snapshot()["panes"])
    assert {tab["id"] for tab in tern.tabs(first)} == original
    assert "SURVIVING_TERMINAL" in tern.read_terminal(survivor)


def test_shell_exit_removes_orphan_panel_without_recreating_empty_tabs(tern):
    session = tern.current()["id"]
    tern.keys("ctrl+b", "c")
    tern.until(lambda: len(tern.tabs(session)) == 2)
    tern.keys("ctrl+d")
    tern.until(lambda: len(tern.tabs(session)) == 1)
    tern.keys("ctrl+d")
    tern.until(lambda: not tern.snapshot()["tabs"])
    tern.ctl("wait", "1500")
    state = tern.snapshot()
    assert not state["tabs"]
    assert not state["panels"]
    assert len(state["sessions"]) == 1
    assert state["sessions"][0]["tabs"] == 0


def test_machine_collapse_and_plugin_reload_preserve_terminals(tern):
    tern.keys("ctrl+b", "c")
    session = tern.current()["id"]
    tern.until(lambda: len(tern.tabs(session)) == 2)
    before = tern.snapshot()
    terminals = {p["pane"] for p in before["panes"] if p.get("kind") == "terminal"}
    tern.until(lambda: tern.panel_tree())
    expanded = tern.panel_tree()[0]["text"]
    buttons = tern.ctl("tree", ".spaces-sidebar .sf-button")["nodes"]
    x, y, width, height = buttons[0]["rect"]
    tern.ctl("click", str(x + width / 2), str(y + height / 2))
    tern.until(lambda: "▸" in tern.panel_tree()[0]["text"])
    assert "▾" not in tern.panel_tree()[0]["text"]
    assert not tern.ctl("tree", ".space-name")["nodes"]
    tern.ctl("click", str(x + width / 2), str(y + height / 2))
    tern.until(lambda: tern.panel_tree()[0]["text"] == expanded)
    subprocess.run(
        ["xdotool", "type", "--clearmodifiers", "printf '%s_%s\\n' HEADER_FOCUS OK"],
        env=tern.env,
        check=True,
        timeout=TIMEOUT,
    )
    tern.keys("Return")
    tern.until(
        lambda: "HEADER_FOCUS_OK" in tern.read_terminal(before["focused"]).splitlines()
    )
    subprocess.run(
        [tern.binary, "plugin", "reload"], env=tern.env, check=True, timeout=TIMEOUT
    )
    for number in (1, 2, 1, 2):
        tern.keys("ctrl+b", str(number))
        tern.ctl("wait", "1100")
    state = tern.snapshot()
    assert {
        p["pane"] for p in state["panes"] if p.get("kind") == "terminal"
    } == terminals
    assert {tab["id"] for tab in state["tabs"]} == {tab["id"] for tab in before["tabs"]}
    panels = {p["pane"] for p in state["panels"] if p["owner"] == "spaces"}
    for tab in state["tabs"]:
        assert (
            sum(p["tab"] == tab["id"] and p["pane"] in panels for p in state["panes"])
            == 1
        )


def test_profile_upgrade_preserves_user_overrides_and_updates_managed_keys(tern):
    profile = tern.root / "sources" / "multiplexer" / "profiles.luau"
    updated_profile = profile.read_text()
    profile.write_text("""
return {
  default = "herdr",
  styles = {herdr = {
    ["ctrl+b>c"] = "new_tab",
    ["ctrl+b>x"] = "close_pane",
    ["ctrl+b>n"] = "next_tab",
    ["ctrl+b>w"] = "plugin.multiplexer.choose_agent",
  }},
  personal = {},
}
""")
    subprocess.run(
        [tern.binary, "plugin", "reload"], env=tern.env, check=True, timeout=TIMEOUT
    )
    tern.ctl("plugins", "run", "plugin.multiplexer.use_herdr")
    tern.lua('cx.settings:bind("ctrl+b>n", "previous_tab")')
    profile.write_text(updated_profile)
    subprocess.run(
        [tern.binary, "plugin", "reload"], env=tern.env, check=True, timeout=TIMEOUT
    )
    tern.ctl("wait", "300")
    first = tern.current()["id"]
    tern.keys("ctrl+b", "c")
    tern.until(lambda: len(tern.tabs(first)) == 2)
    tern.keys("ctrl+b", "c")
    tern.until(lambda: len(tern.tabs(first)) == 3)
    tabs = tern.tabs(first)
    tern.keys("ctrl+b", "2")
    tern.until(lambda: tern.terminal()["pane"] == tabs[1]["pane"])
    tern.keys("ctrl+b", "n")
    tern.until(lambda: tern.terminal()["pane"] == tabs[0]["pane"])
    tern.keys("ctrl+b", "2")
    tern.until(lambda: tern.terminal()["pane"] == tabs[1]["pane"])
    state = tern.snapshot()
    panels = {p["pane"] for p in state["panels"] if p["owner"] == "spaces"}
    panel = next(
        p["pane"]
        for p in state["panes"]
        if p["tab"] == tabs[1]["id"] and p["pane"] in panels
    )
    tern.lua(f"cx.layout:focus({panel})")
    tern.keys("ctrl+b", "x")
    tern.until(lambda: len(tern.tabs(first)) == 2)
    assert {tab["id"] for tab in tern.tabs(first)} == {tabs[0]["id"], tabs[2]["id"]}
    tern.keys("ctrl+b", "2")
    tern.until(lambda: tern.terminal()["pane"] == tabs[2]["pane"])
    tern.keys("ctrl+b", "x")
    tern.until(lambda: len(tern.tabs(first)) == 1)
    assert tern.tabs(first)[0]["id"] == tabs[0]["id"]
    tern.keys("ctrl+b", "shift+n")
    tern.until(lambda: tern.current()["id"] != first)
    second = tern.current()["id"]
    tern.keys("ctrl+b", "w", "1")
    tern.until(lambda: tern.current()["id"] == first)
    tern.keys("ctrl+shift+w")
    tern.until(lambda: tern.current()["id"] == second)
    assert not tern.tabs(first)
    assert len(tern.tabs(second)) == 1
    tern.ctl("plugins", "run", "plugin.multiplexer.restore")
    restored = json.loads(
        tern.lua("return tern.json.encode(cx.settings:keybinds())").split("→ ", 1)[1]
    )
    subprocess.run(
        [tern.binary, "plugin", "reload"], env=tern.env, check=True, timeout=TIMEOUT
    )
    assert (
        json.loads(
            tern.lua("return tern.json.encode(cx.settings:keybinds())").split("→ ", 1)[
                1
            ]
        )
        == restored
    )


def test_loading_plugin_removes_existing_empty_spaces_only(tern):
    original = {tab["id"] for tab in tern.snapshot()["tabs"]}
    survivor = tern.current()["id"]
    subprocess.run(
        [tern.binary, "plugin", "unlink", "spaces"],
        env=tern.env,
        check=True,
        timeout=TIMEOUT,
    )
    tern.lua('cx.sessions:create({name="Empty space"})')
    tern.until(lambda: tern.current()["id"] != survivor)
    empty = tern.current()["id"]
    tern.ctl("plugins", "run", "close_tab")
    tern.until(lambda: tern.current()["tabs"] == 0)
    subprocess.run(
        [tern.binary, "plugin", "link", str(tern.root / "sources" / "spaces")],
        env=tern.env,
        check=True,
        timeout=TIMEOUT,
    )
    tern.until(lambda: empty not in {s["id"] for s in tern.snapshot()["sessions"]})
    assert tern.current()["id"] == survivor
    assert {tab["id"] for tab in tern.snapshot()["tabs"]} == original


def test_space_shows_branch_below_name_without_terminal_count(tern):
    repo = tern.root / "repo"
    branch = "feature/sidebar"
    subprocess.run(
        ["git", "init", "--initial-branch", branch, str(repo)],
        check=True,
        capture_output=True,
        timeout=TIMEOUT,
    )
    tern.run(f"cd {repo}")
    tern.until(lambda: tern.ctl("tree", ".space-branch")["nodes"])
    label = tern.ctl("tree", ".space-branch")["nodes"][0]
    title = tern.ctl("tree", ".space-name button")["nodes"][0]
    assert label["text"] == branch
    assert title["text"] == tern.current()["name"]
    assert label["rect"][1] >= title["rect"][1] + title["rect"][3]
    assert str(repo) not in tern.panel_tree()[0]["text"]
    renamed = "feature/renamed"
    subprocess.run(
        ["git", "-C", str(repo), "symbolic-ref", "HEAD", f"refs/heads/{renamed}"],
        check=True,
        timeout=TIMEOUT,
    )
    tern.until(lambda: tern.ctl("tree", ".space-branch")["nodes"][0]["text"] == renamed)
    tern.run(f"cd {tern.root}")
    tern.until(lambda: not tern.ctl("tree", ".space-branch")["nodes"])


def test_long_space_and_branch_names_stay_inside_sidebar(tern):
    branch = "feature/" + "long-branch-name-" * 6
    name = "long-workspace-name-" * 6
    repo = tern.root / "repo"
    subprocess.run(
        ["git", "init", "--initial-branch", branch, str(repo)],
        check=True,
        capture_output=True,
        timeout=TIMEOUT,
    )
    tern.run(f"cd {repo}")
    tern.until(lambda: tern.ctl("tree", ".space-branch")["nodes"])
    tern.lua(f"cx.sessions:rename(cx.sessions:current().id,{json.dumps(name)})")
    tern.until(lambda: name in tern.panel_tree()[0]["text"])
    sidebar = tern.panel_tree()[0]["rect"]
    button_height = tern.ctl("tree", ".space-name button")["nodes"][0]["rect"][3]
    for selector in (
        ".space-name button",
        ".space-name .sf-btn-label",
        ".space-branch",
        ".space-branch .sf-text",
    ):
        nodes = tern.ctl("tree", selector)["nodes"]
        assert nodes, selector
        for node in nodes:
            x, _, width, _ = node["rect"]
            assert x >= sidebar[0], node
            assert x + width <= sidebar[0] + sidebar[2] + 1, node
            assert node["rect"][3] <= button_height + 1, node
    # Truncation must leave the full workspace name available for renaming.
    x, y, width, height = tern.ctl("tree", ".space-name button")["nodes"][0]["rect"]
    tern.ctl("click", str(x + width / 2), str(y + height / 2), "right")
    menu = tern.until(
        lambda: [
            node
            for node in tern.ctl("tree", ".pop .mi")["nodes"]
            if node["text"] == "Rename"
        ]
    )[0]
    x, y, width, height = menu["rect"]
    tern.ctl("click", str(x + width / 2), str(y + height / 2))
    tern.until(lambda: tern.ctl("tree", "input")["nodes"])
    assert tern.ctl("tree", "input")["nodes"][0]["value"] == name
    tern.keys("Escape")


def test_branch_survives_sidebar_focus_and_space_switching(tern):
    repo = tern.root / "repo"
    branch = "feature/stable-sidebar"
    subprocess.run(
        ["git", "init", "--initial-branch", branch, str(repo)],
        check=True,
        capture_output=True,
        timeout=TIMEOUT,
    )
    original_pane = tern.terminal()["pane"]
    tern.keys("ctrl+b", "v")
    tern.until(lambda: tern.terminal()["pane"] != original_pane)
    repo_pane = tern.terminal()["pane"]
    tern.run(f"cd {repo}")
    tern.until(lambda: tern.ctl("tree", ".space-branch")["nodes"])
    first = tern.current()["id"]
    x, y, _, _ = tern.panel_tree()[0]["rect"]
    tern.ctl("click", str(x + 1), str(y + 1))
    state = tern.snapshot()
    assert state["focused"] in {panel["pane"] for panel in state["panels"]}
    assert [node["text"] for node in tern.ctl("tree", ".space-branch")["nodes"]] == [
        branch
    ]
    x, y, width, height = tern.ctl("tree", ".space-branch")["nodes"][0]["rect"]
    tern.ctl("click", str(x + width / 2), str(y + height / 2))
    tern.until(lambda: tern.snapshot()["focused"] == repo_pane)
    assert [n["text"] for n in tern.ctl("tree", ".space-branch")["nodes"]] == [branch]
    header = next(
        n
        for n in tern.ctl("tree", ".spaces-sidebar .sf-button")["nodes"]
        if n["text"].startswith("▾ ")
    )
    x, y, width, height = header["rect"]
    tern.ctl("click", str(x + width / 2), str(y + height / 2))
    tern.until(lambda: not tern.ctl("tree", ".space-branch")["nodes"])
    tern.ctl("click", str(x + width / 2), str(y + height / 2))
    tern.until(lambda: tern.ctl("tree", ".space-branch")["nodes"])
    assert tern.snapshot()["focused"] == repo_pane
    assert [n["text"] for n in tern.ctl("tree", ".space-branch")["nodes"]] == [branch]
    x, y, _, _ = tern.panel_tree()[0]["rect"]
    tern.ctl("click", str(x + 1), str(y + 1))
    tern.keys("ctrl+b", "c")
    tern.until(lambda: len(tern.tabs(first)) == 2)
    tern.until(lambda: tern.terminal().get("cwd") == str(repo))
    tern.keys("ctrl+shift+w")
    tern.until(lambda: len(tern.tabs(first)) == 1)
    tern.keys("ctrl+b", "shift+n")
    tern.until(lambda: tern.current()["id"] != first)
    tern.run(f"cd {tern.root}")
    tern.until(lambda: tern.current()["name"] == tern.root.name)
    assert [node["text"] for node in tern.ctl("tree", ".space-branch")["nodes"]] == [
        branch
    ]
    tern.keys("ctrl+b", "w", "1")
    tern.until(lambda: tern.current()["id"] == first)
    assert [node["text"] for node in tern.ctl("tree", ".space-branch")["nodes"]] == [
        branch
    ]
    tern.lua(f"cx.layout:focus({original_pane})")
    tern.until(lambda: not tern.ctl("tree", ".space-branch")["nodes"])
    tern.lua(f"cx.layout:focus({repo_pane})")
    tern.until(lambda: tern.ctl("tree", ".space-branch")["nodes"])
    assert [n["text"] for n in tern.ctl("tree", ".space-branch")["nodes"]] == [branch]


def test_remote_spaces_group_collapse_and_navigate_without_losing_local_tabs(tern):
    local_session = tern.current()["id"]
    local_tabs = {tab["id"] for tab in tern.snapshot()["tabs"]}
    repo = tern.root / "repo"
    subprocess.run(
        ["git", "init", "--initial-branch", "local-only", str(repo)],
        check=True,
        capture_output=True,
        timeout=TIMEOUT,
    )
    tern.run(f"cd {repo}")
    tern.until(lambda: tern.current()["name"] == "repo")
    tern.lua('cx.sessions:rename(nil, "local-space")')
    tern.ctl("remote", "loopback", "build-server")
    tern.until(lambda: any(h["kind"] == "remote" for h in tern.snapshot()["hosts"]))
    tern.until(lambda: tern.current()["id"] != local_session)
    remote_session = tern.current()["id"]
    remote_host = tern.current()["host"]
    tern.run(f"cd {repo}")
    tern.until(lambda: tern.current()["name"] == "repo")
    tern.lua('cx.sessions:rename(nil, "remote-space")')
    tern.until(
        lambda: tern.panel_tree() and "remote-space" in tern.panel_tree()[0]["text"]
    )
    tern.until(lambda: tern.ctl("tree", ".space-branch")["nodes"])
    assert [node["text"] for node in tern.ctl("tree", ".space-branch")["nodes"]] == [
        "local-only"
    ]
    state = tern.snapshot()
    remote = next(host for host in state["hosts"] if host["id"] == remote_host)
    assert remote["kind"] == "remote"
    assert remote["state"] == "connected"
    buttons = tern.ctl("tree", ".spaces-sidebar button")["nodes"]
    labels = [node["text"] for node in buttons]
    assert labels.index("local-space") < labels.index("▾ " + remote["name"])
    assert labels.index("▾ " + remote["name"]) < labels.index("remote-space")
    header = next(node for node in buttons if node["text"] == "▾ " + remote["name"])
    x, y, width, height = header["rect"]
    tern.ctl("click", str(x + width / 2), str(y + height / 2))
    tern.until(lambda: "remote-space" not in tern.panel_tree()[0]["text"])
    assert "local-space" in tern.panel_tree()[0]["text"]
    assert tern.current()["id"] == remote_session
    assert (
        next(h for h in tern.snapshot()["hosts"] if h["id"] == remote_host)["state"]
        == "connected"
    )
    tern.ctl("click", str(x + width / 2), str(y + height / 2))
    tern.until(lambda: "remote-space" in tern.panel_tree()[0]["text"])
    tern.keys("ctrl+b", "w", "1")
    tern.until(lambda: tern.current()["id"] == local_session)
    tern.keys("ctrl+b", "w", "2")
    tern.until(lambda: tern.current()["id"] == remote_session)
    tern.keys("ctrl+b", "c")
    tern.until(lambda: len(tern.tabs(remote_session)) == 2)
    tern.keys("ctrl+shift+w")
    tern.until(lambda: len(tern.tabs(remote_session)) == 1)
    assert {tab["id"] for tab in tern.tabs(local_session)} == local_tabs
    tern.keys("ctrl+shift+w")
    tern.until(lambda: tern.current()["id"] == local_session)
    assert not tern.tabs(remote_session)
    assert {tab["id"] for tab in tern.tabs(local_session)} == local_tabs
    assert (
        next(h for h in tern.snapshot()["hosts"] if h["id"] == remote_host)["state"]
        == "connected"
    )


@pytest.mark.parametrize("remote", [False, True], ids=["local", "remote"])
def test_sidebar_width_follows_resize_across_spaces_tabs_and_reload(tern, remote):
    first = tern.current()["id"]
    original_pane = tern.terminal()["pane"]

    def width():
        nodes = tern.panel_tree()
        return nodes[0]["rect"][2] if nodes else 0

    initial = tern.until(width)
    if remote:
        tern.ctl("remote", "loopback", "width-server")
    else:
        tern.lua('cx.sessions:create({name="second-space"})')
    tern.until(lambda: tern.current()["id"] != first)
    second = tern.current()["id"]
    tern.until(lambda: abs(width() - initial) < 1)
    tern.lua(
        "local tab=cx.session:tab_of(cx.session:focused()) "
        "for _,p in cx.canvas:list() do "
        'if p.owner=="spaces" and cx.session:tab_of(p.pane)==tab then '
        'cx.layout:resize(p.pane,"right",5) end end'
    )
    resized = tern.until(lambda: width() if width() > initial + 5 else None)
    tern.lua(f"cx.sessions:switch({first})")
    tern.until(lambda: tern.current()["id"] == first)
    tern.until(lambda: abs(width() - resized) < 1)
    tern.keys("ctrl+b", "c")
    tern.until(lambda: len(tern.tabs(first)) == 2)
    tern.until(lambda: abs(width() - resized) < 1)
    tern.lua(f"cx.layout:focus({original_pane})")
    tern.until(lambda: tern.terminal()["pane"] == original_pane)
    tern.until(lambda: abs(width() - resized) < 1)
    subprocess.run(
        [tern.binary, "plugin", "reload"],
        env=tern.env,
        check=True,
        capture_output=True,
        timeout=TIMEOUT,
    )
    tern.lua(f"cx.sessions:switch({second})")
    tern.until(lambda: tern.current()["id"] == second)
    tern.until(lambda: abs(width() - resized) < 1)
    assert original_pane in {pane["pane"] for pane in tern.snapshot()["panes"]}


@pytest.mark.parametrize("remote", [False, True], ids=["local", "remote"])
def test_existing_native_spaces_and_tabs_stay_synchronized(tern, remote):
    registration = tern.root / "config" / "plugins" / "spaces.path"
    registration.unlink()

    def reload_plugins():
        subprocess.run(
            [tern.binary, "plugin", "reload"],
            env=tern.env,
            check=True,
            capture_output=True,
            timeout=TIMEOUT,
        )

    reload_plugins()
    for panel in tern.snapshot()["panels"]:
        if panel["owner"] == "spaces":
            tern.lua(f"cx.layout:close({panel['pane']})")
    if remote:
        tern.ctl("remote", "loopback", "existing-server")
        tern.until(
            lambda: any(
                host["kind"] == "remote" and host["current"]
                for host in tern.snapshot()["hosts"]
            )
        )

    session = tern.current()["id"]
    first = tern.tabs(session)[0]
    tern.lua(f'cx.layout:name_tab({first["id"]}, "Existing editor")')
    tern.ctl("plugins", "run", "new_tab")
    tern.until(lambda: len(tern.tabs(session)) == 2)
    second = next(tab for tab in tern.tabs(session) if tab["id"] != first["id"])
    tern.ctl("ready")
    tern.lua(
        f'cx.layout:name_tab({second["id"]}, "Existing logs"); '
        f'cx.sessions:rename({session}, "Existing space"); '
        'cx.sessions:create({name="Other space"})'
    )
    tern.ctl("ready")
    other = tern.current()["id"]
    tern.lua(f'cx.sessions:rename({other}, "Other space")')
    before = tern.snapshot()

    tern.ctl("tabs", "vertical")
    registration.write_text(str(tern.root / "sources" / "spaces"))
    reload_plugins()

    def tab_labels():
        return [
            node["title"].split("  Ctrl+", 1)[0].split("\n", 1)[0]
            for node in tern.ctl("tree", "[role=tab]")["nodes"]
        ]

    def selected_tab():
        return [tab["title"] for tab in tern.ctl("state")["tabs"] if tab["active"]]

    def click_tab(label):
        node = next(
            node
            for node in tern.ctl("tree", "[role=tab]")["nodes"]
            if node["title"].startswith(label + "  ")
        )
        x, y, width, height = node["rect"]
        tern.ctl("click", str(x + width / 2), str(y + height / 2))

    tern.until(
        lambda: tern.panel_tree() and "Existing space" in tern.panel_tree()[0]["text"]
    )
    assert "Other space" in tern.panel_tree()[0]["text"]
    assert tern.ctl("state")["tab_orientation"] == "horizontal"
    space = next(
        node
        for node in tern.ctl("tree", ".space-name button")["nodes"]
        if node["text"] == "Existing space"
    )
    x, y, width, height = space["rect"]
    tern.ctl("click", str(x + width / 2), str(y + height / 2))
    tern.until(lambda: tab_labels() == ["Existing editor", "Existing logs"])
    tab_top = tern.ctl("tree", "[role=tab]")["nodes"][0]["rect"][1]
    assert tab_top < tern.panel_tree()[0]["rect"][1]
    after = tern.snapshot()
    assert {tab["id"] for tab in after["tabs"]} == {tab["id"] for tab in before["tabs"]}
    assert {space["id"] for space in after["sessions"]} == {
        space["id"] for space in before["sessions"]
    }

    click_tab("Existing editor")
    tern.until(lambda: tern.current()["id"] == session)
    tern.until(lambda: tern.snapshot()["focused"] == first["pane"])
    click_tab("Existing logs")
    tern.until(lambda: tern.snapshot()["focused"] == second["pane"])
    tern.lua(f"cx.layout:focus({first['pane']})")
    tern.until(lambda: selected_tab() == ["Existing editor"])

    tern.lua(
        f'cx.layout:name_tab({second["id"]}, "Renamed logs"); '
        f"cx.layout:order_tab({second['id']}, 1); "
        f'cx.sessions:rename({session}, "Renamed space")'
    )
    tern.until(
        lambda: (
            "Renamed logs" in tab_labels()
            and "Renamed space" in tern.panel_tree()[0]["text"]
        )
    )
    assert "Existing logs" not in tab_labels()
    assert "Renamed space" in tern.panel_tree()[0]["text"]
    assert "Existing space" not in tern.panel_tree()[0]["text"]
    assert tab_labels().index("Renamed logs") < tab_labels().index("Existing editor")

    tern.ctl("plugins", "run", "close_tab")
    tern.until(lambda: "Existing editor" not in tab_labels())
    assert [tab["id"] for tab in tern.tabs(session)] == [second["id"]]
    tern.ctl("plugins", "run", "plugin.spaces.new_tab")
    tern.until(lambda: len(tern.tabs(session)) == 2)
    tern.ctl("rename", json.dumps("Created from sidebar"))
    tern.until(lambda: "Created from sidebar" in tab_labels())
    assert {tab["id"] for tab in tern.tabs(other)} == {
        tab["id"] for tab in before["tabs"] if tab["session"] == other
    }


def test_agent_indicator_tracks_terminal_process_across_spaces(tern):
    ordinary_session = tern.current()["id"]
    ordinary_pane = tern.terminal()["pane"]
    agent_process = tern.root / "omp"
    agent_process.write_text(
        "#!/usr/bin/env python3\n"
        "import ctypes\n"
        "import time\n"
        'ctypes.CDLL(None).prctl(15, ctypes.c_char_p(b"omp"), 0, 0, 0)\n'
        "time.sleep(30)\n"
    )
    agent_process.chmod(0o755)

    tern.run("sleep 30")
    tern.until(
        lambda: next(
            pane for pane in tern.snapshot()["panes"] if pane["pane"] == ordinary_pane
        ).get("busy")
    )
    assert not tern.ctl("tree", ".space-agent")["nodes"]

    tern.lua(
        "cx.sessions:create({"
        f"name={json.dumps('Agent workspace')}, cwd={json.dumps(str(tern.root))}"
        "})"
    )
    agent_session = tern.current()["id"]
    agent_pane = tern.terminal()["pane"]
    tern.run(str(agent_process))

    def agent_indicator():
        return tern.ctl(
            "tree",
            f'.space-agent[data-session="{agent_session}"]',
        )["nodes"]

    marker = tern.until(agent_indicator)[0]["rect"]
    sidebar = tern.panel_tree()[0]["rect"]
    assert marker[2] > 0 and marker[3] > 0
    assert sidebar[0] <= marker[0]
    assert marker[0] + marker[2] <= sidebar[0] + sidebar[2]
    tern.lua(f"cx.sessions:switch({ordinary_session})")
    tern.until(lambda: tern.current()["id"] == ordinary_session)
    assert tern.until(agent_indicator)
    assert not tern.ctl(
        "tree",
        f'.space-agent[data-session="{ordinary_session}"]',
    )["nodes"]
    assert next(
        pane for pane in tern.snapshot()["panes"] if pane["pane"] == ordinary_pane
    )["busy"]

    tern.lua(f"cx.sessions:switch({agent_session}); cx.layout:focus({agent_pane})")
    tern.keys("ctrl+c")
    tern.until(
        lambda: (
            not tern.ctl(
                "tree",
                f'.space-agent[data-session="{agent_session}"]',
            )["nodes"]
        )
    )
    tern.lua(
        f"cx.sessions:switch({ordinary_session}); cx.layout:focus({ordinary_pane})"
    )
    tern.keys("ctrl+c")
    tern.until(
        lambda: (
            not next(
                pane
                for pane in tern.snapshot()["panes"]
                if pane["pane"] == ordinary_pane
            ).get("busy")
        )
    )


def test_native_agent_activity_survives_parking_and_aggregates_split_agents(tern):
    session = tern.current()["id"]
    tern.ctl("agent-command", json.dumps("bash"))
    tern.ctl("block", "agent")
    first = tern.terminal()["pane"]

    def indicator(state):
        return tern.ctl(
            "tree",
            f'.space-agent-{state}[data-session="{session}"]',
        )["nodes"]

    tern.until(lambda: indicator("idle"))
    tern.ctl("running", json.dumps("omp"))
    tern.until(lambda: indicator("working"))
    name = "long-workspace-name-" * 6
    tern.lua(f"cx.sessions:rename({session},{json.dumps(name)})")
    tern.until(
        lambda: tern.ctl("tree", ".space-name button")["nodes"][0]["text"] == name
    )
    marker = tern.until(lambda: indicator("working"))[0]["rect"]
    button = tern.ctl("tree", ".space-name button")["nodes"][0]["rect"]
    sidebar = tern.panel_tree()[0]["rect"]
    assert button[0] + button[2] <= marker[0]
    assert marker[0] + marker[2] <= sidebar[0] + sidebar[2]
    assert abs(button[1] + button[3] / 2 - marker[1] - marker[3] / 2) < 1
    tern.lua(f"cx.layout:park({first})")
    tern.until(lambda: indicator("working"))
    assert next(pane for pane in tern.snapshot()["panes"] if pane["pane"] == first)[
        "parked"
    ]

    tern.ctl("block", "agent")
    second = tern.terminal()["pane"]
    assert second != first
    tern.until(lambda: indicator("working"))
    tern.lua(f"cx.layout:close({first})")
    tern.until(lambda: indicator("idle"))
    tern.lua(f"cx.layout:close({second})")
    tern.until(lambda: not tern.ctl("tree", ".space-agent")["nodes"])
