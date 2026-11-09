"""Native profile-group workflows in an isolated Tern/X11 session."""

import json
import os
import re
import subprocess
import tempfile
from pathlib import Path

import pytest

from test_workflows import TIMEOUT, Tern


def click_node(tern, node, button=None):
    x, y, width, height = node["rect"]
    args = ["click", str(x + width / 2), str(y + height / 2)]
    if button:
        args.append(button)
    tern.ctl(*args)


def profile_buttons(tern):
    return tern.ctl("tree", ".spaces-profiles button")["nodes"]


def profile_button(tern, name):
    return tern.until(
        lambda: next(
            (node for node in profile_buttons(tern) if node["text"] == name), None
        )
    )


def profile_is_current(tern, name):
    selected = tern.ctl("tree", ".profile-current button")["nodes"]
    if not selected:
        selected = tern.ctl("tree", ".profile-current")["nodes"]
    return any(node.get("text") == name for node in selected)


def select_profile(tern, name):
    click_node(tern, profile_button(tern, name))
    tern.until(lambda: profile_is_current(tern, name))


def fill_prompt(tern, value, previous_value=None):
    def matching_input():
        nodes = tern.ctl("tree", "input")["nodes"]
        if previous_value is None:
            return nodes[0] if nodes else None
        return next(
            (node for node in nodes if node.get("value") != previous_value), None
        )

    node = tern.until(matching_input)
    old_value = node.get("value") or ""
    if old_value:
        tern.ctl("select-text", "0", str(len(old_value.encode())))
    tern.ctl("type", json.dumps(value))
    tern.keys("Return")


def choose(tern, label):
    tern.until(lambda: tern.ctl("tree", "input")["nodes"])
    tern.ctl("type", json.dumps(label))
    tern.keys("Return")


def create_profile(tern, name, cwd):
    tern.ctl("plugins", "run", "plugin.spaces.new_profile")
    fill_prompt(tern, name)
    fill_prompt(tern, str(cwd), previous_value=name)
    profile_button(tern, name)
    tern.until(lambda: profile_is_current(tern, name))
    tern.until(lambda: tern.terminal().get("cwd") == str(cwd))
    return tern.current()["id"]


def create_space(tern, name, cwd):
    before = {session["id"] for session in tern.snapshot()["sessions"]}
    tern.keys("ctrl+b", "shift+n")

    def new_current_session():
        session = tern.current()
        return session if session["id"] not in before else None

    session = tern.until(new_current_session)
    session_id = session["id"]
    tern.lua(f'cx.sessions:rename({session_id}, "{name}")')
    tern.until(lambda: tern.current()["name"] == name)
    tern.until(lambda: tern.terminal().get("cwd") == str(cwd))
    return session_id


def sidebar_names(tern):
    return [node["text"] for node in tern.ctl("tree", ".space-name button")["nodes"]]


def assert_sidebar_names(tern, names):
    tern.until(lambda: sorted(sidebar_names(tern)) == sorted(names))


def sidebar_button(tern, name):
    def matching_button():
        return next(
            (
                node
                for node in tern.ctl("tree", ".space-name button")["nodes"]
                if node["text"] == name
            ),
            None,
        )

    return tern.until(matching_button)


def tabs_for(tern, session_id):
    return [tab for tab in tern.snapshot()["tabs"] if tab["session"] == session_id]


def session_exists(tern, session_id):
    return any(session["id"] == session_id for session in tern.snapshot()["sessions"])


def process_pid(tern, pane, marker):
    def reported_pid():
        match = re.search(rf"{re.escape(marker)} PID=(\d+)", tern.read_terminal(pane))
        return int(match.group(1)) if match else None

    return tern.until(reported_pid)


def process_is_alive(pid):
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    return True


def start_long_process(tern, marker):
    pane = tern.terminal()["pane"]
    tern.run(f'sh -c \'printf "{marker} PID=%s\\n" "$$"; exec sleep infinity\'')
    return pane, process_pid(tern, pane, marker)


def visible_windows(tern):
    result = subprocess.run(
        ["xdotool", "search", "--onlyvisible", "--class", "tern"],
        env=tern.env,
        capture_output=True,
        text=True,
        check=True,
        timeout=TIMEOUT,
    )
    return set(result.stdout.splitlines())


def start_profile_tern(tern):
    tern.start()
    profile_button(tern, "Default")
    tern.until(lambda: profile_is_current(tern, "Default"))


@pytest.fixture
def profile_tern():
    assert os.environ.get("DISPLAY"), "Run these tests inside xvfb-run"
    with tempfile.TemporaryDirectory(prefix="tern-profiles-", dir="/tmp") as directory:
        tern = Tern(Path(directory))
        try:
            start_profile_tern(tern)
            yield tern
        finally:
            tern.close()


def test_groups_switch_in_one_window_and_keep_membership_after_reload(profile_tern):
    tern = profile_tern
    original = tern.current()["id"]
    original_cwd = tern.terminal()["cwd"]
    tern.lua(f'cx.sessions:rename({original}, "Default original")')
    tern.until(lambda: tern.current()["name"] == "Default original")
    original_pane, original_pid = start_long_process(tern, "DEFAULT_GROUP_PROCESS")

    default_second = create_space(tern, "Default second", Path(original_cwd))
    starting_directory = tern.root / "profile work directory"
    starting_directory.mkdir()
    profile_first = create_profile(tern, "Personal", starting_directory)
    assert profile_first != original
    assert visible_windows(tern) == {tern.window}
    assert {session["id"] for session in tern.snapshot()["sessions"]} >= {
        original,
        default_second,
        profile_first,
    }

    profile_second = create_space(tern, "Personal second", starting_directory)
    profile_first_name = next(
        session["name"]
        for session in tern.snapshot()["sessions"]
        if session["id"] == profile_first
    )
    assert_sidebar_names(tern, [profile_first_name, "Personal second"])
    tern.keys("ctrl+b", "w", "1")
    tern.until(lambda: tern.current()["id"] == profile_first)
    assert tern.current()["id"] != original
    assert_sidebar_names(tern, [profile_first_name, "Personal second"])
    tern.keys("ctrl+b", "w", "2")
    tern.until(lambda: tern.current()["id"] == profile_second)

    select_profile(tern, "Default")
    tern.until(lambda: tern.current()["id"] == default_second)
    assert_sidebar_names(tern, ["Default original", "Default second"])
    select_profile(tern, "Personal")
    tern.until(lambda: tern.current()["id"] == profile_second)
    select_profile(tern, "Default")
    click_node(tern, sidebar_button(tern, "Default original"))
    tern.until(lambda: tern.current()["id"] == original)
    assert tern.terminal()["pane"] == original_pane
    assert "DEFAULT_GROUP_PROCESS" in tern.read_terminal(original_pane)
    assert process_is_alive(original_pid)

    tern.ctl("plugins", "run", "plugin.spaces.rename_profile")
    choose(tern, "Personal")
    fill_prompt(tern, "Renamed personal")
    profile_button(tern, "Renamed personal")
    subprocess.run(
        [tern.binary, "plugin", "reload", "spaces"],
        env=tern.env,
        check=True,
        timeout=TIMEOUT,
    )
    tern.until(lambda: profile_is_current(tern, "Default"))
    tern.until(lambda: tern.current()["id"] == original)
    select_profile(tern, "Renamed personal")
    tern.until(lambda: tern.current()["id"] == profile_second)
    assert_sidebar_names(tern, [profile_first_name, "Personal second"])
    assert visible_windows(tern) == {tern.window}
    select_profile(tern, "Default")
    click_node(tern, sidebar_button(tern, "Default original"))
    tern.until(lambda: tern.current()["id"] == original)
    assert tern.terminal()["pane"] == original_pane
    assert process_is_alive(original_pid)


def test_move_profile_space_preserves_native_pane_and_process(profile_tern):
    tern = profile_tern
    default_session = tern.current()["id"]
    tern.lua(f'cx.sessions:rename({default_session}, "Default space")')
    tern.until(lambda: tern.current()["name"] == "Default space")
    profile_cwd = tern.root / "move source"
    profile_cwd.mkdir()
    moving = create_profile(tern, "Personal", profile_cwd)
    tern.lua(f'cx.sessions:rename({moving}, "Moving space")')
    tern.until(lambda: tern.current()["name"] == "Moving space")
    pane, pid = start_long_process(tern, "MOVED_GROUP_PROCESS")
    sibling = create_space(tern, "Personal sibling", profile_cwd)
    assert_sidebar_names(tern, ["Moving space", "Personal sibling"])

    click_node(tern, sidebar_button(tern, "Moving space"), "right")
    action = tern.until(
        lambda: next(
            (
                node
                for node in tern.ctl("tree", ".pop .mi")["nodes"]
                if node["text"] == "Move to profile"
            ),
            None,
        )
    )
    click_node(tern, action)
    choose(tern, "Default")
    tern.until(lambda: profile_is_current(tern, "Personal"))
    assert_sidebar_names(tern, ["Personal sibling"])
    assert session_exists(tern, moving)

    select_profile(tern, "Default")
    click_node(tern, sidebar_button(tern, "Moving space"))
    tern.until(lambda: tern.current()["id"] == moving)
    assert session_exists(tern, default_session)
    assert session_exists(tern, sibling)
    assert tern.terminal()["pane"] == pane
    assert "MOVED_GROUP_PROCESS" in tern.read_terminal(pane)
    assert process_is_alive(pid)
    assert_sidebar_names(tern, ["Default space", "Moving space"])


def test_closing_space_uses_same_group_fallback_and_keeps_empty_anchor(profile_tern):
    tern = profile_tern
    default_first = tern.current()["id"]
    tern.lua(f'cx.sessions:rename({default_first}, "Default anchor")')
    tern.until(lambda: tern.current()["name"] == "Default anchor")
    default_second = create_space(tern, "Default adjacent", tern.root)

    profile_cwd = tern.root / "single profile space"
    profile_cwd.mkdir()
    profile_anchor = create_profile(tern, "Solo", profile_cwd)
    tern.lua(f'cx.sessions:rename({profile_anchor}, "Solo anchor")')
    tern.until(lambda: tern.current()["name"] == "Solo anchor")

    select_profile(tern, "Default")
    tern.until(lambda: tern.current()["id"] == default_second)
    tern.keys("ctrl+b", "x")
    tern.until(lambda: not session_exists(tern, default_second))
    assert tern.current()["id"] == default_first
    assert profile_is_current(tern, "Default")
    assert_sidebar_names(tern, ["Default anchor"])

    select_profile(tern, "Solo")
    tern.until(lambda: tern.current()["id"] == profile_anchor)
    assert_sidebar_names(tern, ["Solo anchor"])
    tern.keys("ctrl+b", "x")
    tern.until(
        lambda: (
            session_exists(tern, profile_anchor) and not tabs_for(tern, profile_anchor)
        )
    )
    assert tern.current()["id"] == profile_anchor

    tern.keys("ctrl+alt+p")
    choose(tern, "Default")
    tern.until(lambda: profile_is_current(tern, "Default"))
    tern.until(lambda: tern.current()["id"] == default_first)
    tern.keys("ctrl+alt+p")
    choose(tern, "Solo")
    tern.until(lambda: profile_is_current(tern, "Solo"))
    tern.until(lambda: tern.current()["id"] == profile_anchor)

    select_profile(tern, "Default")
    # Reconcile two emptied sessions together, with the older one selected.
    tern.lua(
        'cx:command("close_tab"); '
        'cx.sessions:create({name="Empty sibling"}); '
        'cx:command("close_tab"); '
        f"cx.sessions:switch({default_first})"
    )
    tern.until(
        lambda: (
            tern.current()["id"] == default_first and not tabs_for(tern, default_first)
        )
    )
    assert tabs_for(tern, profile_anchor)


def test_hidden_picker_and_profile_configuration_are_group_local(profile_tern):
    tern = profile_tern
    default_session = tern.current()["id"]
    default_cwd = tern.terminal()["cwd"]
    starting_directory = tern.root / "configured personal directory"
    starting_directory.mkdir()
    personal_cwd = tern.root / "initial personal directory"
    personal_cwd.mkdir()
    personal = create_profile(tern, "Personal", personal_cwd)

    tern.ctl("plugins", "run", "plugin.spaces.toggle_sidebar")
    tern.until(lambda: not tern.ctl("tree", ".spaces-sidebar")["nodes"])
    tern.keys("ctrl+alt+p")
    choose(tern, "Default")
    tern.until(lambda: tern.current()["id"] == default_session)
    tern.keys("ctrl+alt+p")
    choose(tern, "Personal")
    tern.until(lambda: tern.current()["id"] == personal)

    tern.ctl("plugins", "run", "plugin.spaces.configure_profile")
    choose(tern, "Personal")
    fill_prompt(tern, str(starting_directory))
    tern.keys("ctrl+b", "x")
    tern.until(lambda: not tabs_for(tern, personal))
    tern.keys("ctrl+alt+p")
    choose(tern, "Default")
    tern.until(lambda: tern.current()["id"] == default_session)
    tern.keys("ctrl+alt+p")
    choose(tern, "Personal")
    tern.until(
        lambda: (
            tern.current()["id"] == personal
            and tern.terminal().get("cwd") == str(starting_directory)
        )
    )
    create_space(tern, "Configured personal space", starting_directory)
    assert tern.terminal()["cwd"] == str(starting_directory)

    tern.lua('cx.settings:set("tabs", "Vertical")')
    tern.keys("ctrl+alt+p")
    choose(tern, "Default")
    tern.until(lambda: tern.current()["id"] == default_session)
    assert tern.terminal()["cwd"] == default_cwd
    default_follow_up = create_space(
        tern, "Default after profile config", Path(default_cwd)
    )
    tern.until(lambda: tern.current()["id"] == default_follow_up)
    value = tern.lua('return tern.json.encode(cx.settings:get("tabs"))')
    assert json.loads(value.split("→ ", 1)[1]) == "Vertical"
    assert not tern.ctl("tree", ".spaces-sidebar")["nodes"]


def test_legacy_profiles_import_names_and_directories_without_touching_files():
    assert os.environ.get("DISPLAY"), "Run these tests inside xvfb-run"
    with tempfile.TemporaryDirectory(
        prefix="tern-profiles-legacy-", dir="/tmp"
    ) as directory:
        tern = Tern(Path(directory))
        legacy_root = Path(tern.env["TERN_PROFILES_DIR"])
        legacy_root.mkdir(parents=True)
        personal_config = tern.root / "legacy-personal-config"
        personal_config.mkdir()
        config_marker = personal_config / "sentinel"
        config_marker.write_text("keep config")
        personal_socket = tern.root / "legacy-personal.sock"
        personal_socket.write_text("not a live daemon socket")
        personal_cwd = tern.root / "legacy personal directory"
        personal_cwd.mkdir()
        updated_cwd = tern.root / "updated legacy directory"
        updated_cwd.mkdir()
        legacy_registry = {
            "profiles": [
                {
                    "id": "00000000000000000000000000000001",
                    "name": "Default",
                    "cwd": tern.env["HOME"],
                    "config": tern.env["TERN_CONFIG_DIR"],
                    "socket": tern.env["TERN_DAEMON_SOCKET"],
                    "original": True,
                },
                {
                    "id": "00000000000000000000000000000002",
                    "name": "Personal",
                    "cwd": str(personal_cwd),
                    "config": str(personal_config),
                    "socket": str(personal_socket),
                },
            ]
        }
        registry_path = legacy_root / "profiles.json"
        registry_path.write_text(json.dumps(legacy_registry, indent=2) + "\n")
        original_registry = registry_path.read_bytes()
        original_config_marker = config_marker.read_bytes()
        original_socket = personal_socket.read_bytes()
        try:
            start_profile_tern(tern)
            original = tern.current()["id"]
            assert profile_is_current(tern, "Default")
            assert profile_button(tern, "Personal")

            tern.ctl("plugins", "run", "plugin.spaces.configure_profile")
            choose(tern, "Default")
            prompt = tern.until(lambda: tern.ctl("tree", "input")["nodes"])
            assert prompt[0].get("value") == tern.env["HOME"]
            tern.keys("Escape")
            tern.ctl("plugins", "run", "plugin.spaces.configure_profile")
            choose(tern, "Personal")
            prompt = tern.until(lambda: tern.ctl("tree", "input")["nodes"])
            assert prompt[0].get("value") == str(personal_cwd)
            tern.keys("Escape")
            tern.ctl("plugins", "run", "plugin.spaces.configure_profile")
            choose(tern, "Personal")
            fill_prompt(tern, str(updated_cwd))
            subprocess.run(
                [tern.binary, "plugin", "reload", "spaces"],
                env=tern.env,
                check=True,
                timeout=TIMEOUT,
            )
            tern.ctl("plugins", "run", "plugin.spaces.configure_profile")
            choose(tern, "Personal")
            prompt = tern.until(lambda: tern.ctl("tree", "input")["nodes"])
            assert prompt[0].get("value") == str(updated_cwd)
            tern.keys("Escape")
            assert tern.current()["id"] == original
            assert profile_is_current(tern, "Default")

            select_profile(tern, "Personal")
            tern.until(
                lambda: (
                    tern.current()["id"] != original
                    and tern.terminal().get("cwd") == str(updated_cwd)
                )
            )
            assert session_exists(tern, original)
            assert visible_windows(tern) == {tern.window}

            assert registry_path.read_bytes() == original_registry
            assert config_marker.read_bytes() == original_config_marker
            assert personal_socket.read_bytes() == original_socket
        finally:
            tern.close()
