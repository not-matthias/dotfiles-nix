"""Real Tern windows on X11, isolated from the user's config, sessions and daemon."""

import json
import os
import re
import shutil
import signal
import socket
import subprocess
import tempfile
import time
from contextlib import contextmanager
from pathlib import Path

PLUGIN = Path(__file__).resolve().parents[1]
MULTIPLEXER = PLUGIN.parent / "multiplexer"
PLUGIN_ID = "spaces"
TIMEOUT = 15
LINK_TIMEOUT = 30
HOST_MARKERS = ("▾ ", "▸ ")
PROBE_ATTEMPTS = 3
PROBE_RETRY_MS = 200
PROBE_OUT_OF_TIME = "lua exceeded hard slice budget"
HOOK_FAILURE = re.compile(
    rf'plugin (?:handler failed|hook exceeded).*plugin="{PLUGIN_ID}"'
)


class Tern:
    """One machine: a session daemon and a window with both plugins linked."""

    def __init__(self, root):
        self.root = root
        self.control = str(root / "control.sock")
        # A test started from a Tern pane must not inherit that pane's window or identity.
        self.env = {
            key: value
            for key, value in os.environ.items()
            if not key.startswith("TERN_") or key == "TERN_BIN"
        }
        self.env.pop("WAYLAND_DISPLAY", None)
        self.env.update(
            TERN_CONFIG_DIR=str(root / "config"),
            TERN_DAEMON_SOCKET=str(root / "daemon.sock"),
            XDG_STATE_HOME=str(root / "state"),
            TERN_PROFILES_DIR=str(root / "profiles"),
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
        sources = self.root / "sources"
        shutil.copytree(MULTIPLEXER, sources / "multiplexer")
        # Only what the plugin loads: tests and benchmarks stay out of the copy.
        (sources / PLUGIN_ID).mkdir()
        shutil.copy(PLUGIN / "plugin.toml", sources / PLUGIN_ID)
        shutil.copytree(PLUGIN / "src", sources / PLUGIN_ID / "src")
        for name in (PLUGIN_ID, "multiplexer"):
            (plugins / f"{name}.path").write_text(str(sources / name))
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
            [
                "xdotool",
                "search",
                "--sync",
                "--onlyvisible",
                "--pid",
                str(self.processes[-1].pid),
                "--class",
                "tern",
            ],
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
        for attempt in range(PROBE_ATTEMPTS):
            if attempt:
                self.ctl("wait", str(PROBE_RETRY_MS))
            self.ctl("carly", "lua", json.dumps(code))
            result = self.ctl("state")["carly"]["last_tool"]
            self.ctl("carly", "close")
            # The probe shares the window's thread: a busy frame can use up its own time slice.
            if PROBE_OUT_OF_TIME not in result["text"]:
                break
        assert not result["error"], (
            f"{result['text']}\n{self.root.joinpath('process.log').read_text()}"
        )
        return result["text"]

    def lua_json(self, expression):
        # Carly abbreviates large returned strings. A local file keeps snapshots lossless.
        target = self.root / "query.json"
        self.lua(
            f"tern.fs.write({json.dumps(str(target))}, tern.json.encode({expression}))"
        )
        return json.loads(target.read_text())

    def snapshot(self):
        result = self.lua_json(
            "{sessions=cx.sessions:list(), tabs=cx.session:tabs(), "
            "panes=cx.session:panes(), focused=cx.session:focused(), "
            "panels=cx.canvas:list(), hosts=cx.hosts:list()}"
        )
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

    def reload(self, plugin=None):
        subprocess.run(
            [self.binary, "plugin", "reload", *([plugin] if plugin else [])],
            env=self.env,
            check=True,
            capture_output=True,
            timeout=TIMEOUT,
        )

    def until(self, predicate, timeout=TIMEOUT):
        deadline = time.monotonic() + timeout
        last = None
        while time.monotonic() < deadline:
            for process in self.processes:
                if process.poll() is not None:
                    raise AssertionError(self.root.joinpath("process.log").read_text())
            last = predicate()
            if last:
                return last
            if Path(self.control).exists():
                self.ctl("wait", "100")
            else:
                time.sleep(0.1)
        raise AssertionError(
            f"Workflow did not settle within {timeout}s; last result: {last}\n"
            + self.root.joinpath("process.log").read_text()
        )

    def tabs(self, session):
        return [tab for tab in self.snapshot()["tabs"] if tab["session"] == session]

    def current(self):
        return next(row for row in self.snapshot()["sessions"] if row["current"])

    def terminal(self):
        state = self.snapshot()
        return next(pane for pane in state["panes"] if pane["pane"] == state["focused"])

    def read_terminal(self, pane):
        return "\n".join(self.lua_json(f"cx.session:read({pane})")["lines"])

    def panel_tree(self):
        return self.ctl("tree", ".spaces-sidebar")["nodes"]

    def click(self, node, button=None):
        x, y, width, height = node["rect"]
        self.ctl(
            "click",
            str(x + width / 2),
            str(y + height / 2),
            *([button] if button else []),
        )

    def space_names(self):
        return [
            node["text"] for node in self.ctl("tree", ".space-name button")["nodes"]
        ]

    def host_names(self):
        """Machines the visible sidebar lists, without their fold markers."""
        return [
            node["text"][len(marker) :]
            for node in self.ctl("tree", ".spaces-sidebar button")["nodes"]
            for marker in HOST_MARKERS
            if node["text"].startswith(marker)
        ]

    def panels(self, state=None):
        """Sidebar panels by tab; a parked panel has tab None."""
        state = state or self.snapshot()
        owned = {p["pane"] for p in state["panels"] if p["owner"] == PLUGIN_ID}
        result = {}
        for pane in state["panes"]:
            if pane["pane"] in owned:
                result.setdefault(pane.get("tab"), []).append(pane["pane"])
        return result

    def panel_records(self):
        """Who drew each sidebar and when, as the plugin recorded it."""
        return {
            panel["pane"]: panel.get("about")
            for panel in self.snapshot()["panels"]
            if panel["owner"] == PLUGIN_ID
        }

    def windows(self):
        result = subprocess.run(
            ["xdotool", "search", "--onlyvisible", "--class", "tern"],
            env=self.env,
            capture_output=True,
            text=True,
            timeout=TIMEOUT,
        )
        return set(result.stdout.split())

    def extend_plugin(self, luau):
        """Appends code to this machine's copy of the plugin and loads it."""
        entry = self.root / "sources" / PLUGIN_ID / "src" / "window.luau"
        entry.write_text(f"{entry.read_text()}\n{luau}")
        self.reload(PLUGIN_ID)

    def hook_failures(self):
        self.log.flush()
        log = self.root.joinpath("process.log").read_text()
        return [line for line in log.splitlines() if HOOK_FAILURE.search(line)]

    def panel_problems(self):
        panels = self.panels()
        problems = [
            f"tab {tab} has sidebars {panes}"
            for tab, panes in panels.items()
            if tab is not None and len(panes) > 1
        ]
        if None in panels:
            problems.append(f"sidebars {panels[None]} are parked")
        return problems

    def assert_healthy(self, windows=1):
        """What must hold once any workflow settles, whatever it did."""
        for process in self.processes:
            assert process.poll() is None, self.root.joinpath("process.log").read_text()
        self.until(lambda: not self.panel_problems() or None)
        assert not self.hook_failures(), "\n".join(self.hook_failures())
        assert len(self.windows()) == windows, self.windows()

    # Remoting: this machine serves its daemon, or attaches to one that does.

    def serve(self):
        """Serves this machine's sessions over the network; returns what `attach` needs."""
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as probe:
            probe.bind(("127.0.0.1", 0))
            port = probe.getsockname()[1]
        state_dir = str(self.root / "config")
        host_key = subprocess.run(
            [self.binary, "remote", "host-key", "--state-dir", state_dir],
            env=self.env,
            capture_output=True,
            text=True,
            check=True,
            timeout=TIMEOUT,
        )
        self.processes.append(
            self.spawn(
                "remote",
                "serve",
                "--user",
                "--listen",
                f"127.0.0.1:{port}",
                "--state-dir",
                state_dir,
                "--authorized-keys",
                str(self.root / "authorized_keys"),
                "--relay",
                "none",
            )
        )
        return {
            "address": f"127.0.0.1:{port}",
            "fingerprint": json.loads(host_key.stdout)["fingerprint"],
        }

    def use_fresh_identity(self, server):
        """Gives this machine a throwaway home and login key the server accepts."""
        home = self.root / "home"
        (home / ".ssh").mkdir(parents=True)
        key = home / ".ssh" / "id_ed25519"
        subprocess.run(
            [
                "ssh-keygen",
                "-q",
                "-t",
                "ed25519",
                "-N",
                "",
                "-C",
                "tern@test",
                "-f",
                key,
            ],
            check=True,
            timeout=TIMEOUT,
        )
        (server.root / "authorized_keys").write_text(
            key.with_suffix(".pub").read_text()
        )
        self.env["HOME"] = str(home)
        self.env.pop("SSH_AUTH_SOCK", None)

    def attach(self, endpoint):
        """Connects to a served machine and returns its host row."""
        self.lua(f'cx.hosts:add("{endpoint["address"]}")')

        def remote(*states):
            for host in self.lua_json("cx.hosts:list()"):
                if host["kind"] == "remote" and host["state"] in states:
                    return host
            return None

        host = self.until(lambda: remote("verify", "connected"), timeout=LINK_TIMEOUT)
        if host["state"] == "verify":
            self.lua(f'cx.hosts:trust({host["id"]}, "{endpoint["fingerprint"]}")')
        return self.until(lambda: remote("connected"), timeout=LINK_TIMEOUT)


@contextmanager
def running(prefix="tern-test-", started=None):
    """A started machine, checked for health when the workflow is over."""
    assert os.environ.get("DISPLAY"), "Run these tests inside xvfb-run"
    # Unix-domain socket paths have a small fixed limit; pytest test names exceed it.
    with tempfile.TemporaryDirectory(prefix=prefix, dir="/tmp") as directory:
        instance = Tern(Path(directory))
        try:
            if started:
                started(instance)
            else:
                instance.start()
            yield instance
            instance.assert_healthy()
        finally:
            instance.close()


@contextmanager
def linked():
    """Two machines: `desk` serves its sessions, `laptop` shows its own and desk's."""
    assert os.environ.get("DISPLAY"), "Run these tests inside xvfb-run"
    with tempfile.TemporaryDirectory(prefix="tern-pair-", dir="/tmp") as directory:
        root = Path(directory)
        machines = []
        try:
            for name in ("desk", "laptop"):
                (root / name).mkdir()
                machines.append(Tern(root / name))
            desk, laptop = machines
            laptop.use_fresh_identity(desk)
            desk.start()
            endpoint = desk.serve()
            laptop.start()
            laptop.attach(endpoint)
            yield desk, laptop
            for machine in machines:
                machine.assert_healthy(windows=len(machines))
        finally:
            for machine in reversed(machines):
                machine.close()
