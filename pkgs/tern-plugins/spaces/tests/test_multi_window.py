"""Two machines showing the same sessions: `laptop` is attached to `desk`.

A tab's sidebar is stored with the tab, so both windows show the same one. It lists the
machines and spaces of whichever window was used last, and must work there.
"""

import json
import time

from harness import PLUGIN_ID
from test_robustness import shown_sidebar, space_button

IDLE_SECONDS = 5


def name_spaces(desk, laptop):
    """Names the one space each machine starts with."""
    local = next(h["id"] for h in laptop.snapshot()["hosts"] if h["kind"] == "local")
    own = next(s["id"] for s in laptop.snapshot()["sessions"] if s["host"] == local)
    desk.lua('cx.sessions:rename(nil, "desk-one")')
    laptop.lua(f'cx.sessions:rename({own}, "laptop-one")')
    for name in ("desk-one", "laptop-one"):
        session_named(laptop, name)


def session_named(machine, name):
    return machine.until(
        lambda: next(
            (s["id"] for s in machine.snapshot()["sessions"] if s["name"] == name),
            None,
        )
    )


def own_machines(machine):
    return sorted(host["name"] for host in machine.snapshot()["hosts"])


def use(machine):
    """Any action in a window makes it the one being looked at."""
    machine.ctl("plugins", "run", f"plugin.{PLUGIN_ID}.refresh")


def shows_own_machines(machine):
    return sorted(machine.host_names()) == own_machines(machine)


def shown_record(machine):
    """Who drew the sidebar on screen; windows on one tab agree once they have caught up."""
    return machine.panel_records().get(shown_sidebar(machine))


def open_space(machine, name):
    session = session_named(machine, name)
    machine.click(machine.until(lambda: space_button(machine, name)))
    machine.until(lambda: machine.current()["id"] == session)
    machine.until(lambda: shown_sidebar(machine))


def add_space(machine, name):
    """Adds a space with its shortcut, names it, and returns the window to where it was."""
    home = machine.current()["id"]
    machine.keys("ctrl+b", "shift+n")
    machine.until(lambda: machine.current()["id"] != home)
    added = machine.current()["id"]
    # A new space is named after its directory until its shell has reported one.
    machine.until(lambda: machine.terminal().get("cwd") == str(machine.root))
    machine.lua(f'cx.sessions:rename({added}, "{name}")')
    machine.lua(f"cx.sessions:switch({home})")
    machine.until(lambda: machine.current()["id"] == home)
    return added


def rename_from_sidebar(machine, old, new):
    machine.click(machine.until(lambda: space_button(machine, old)), "right")
    rename = machine.until(
        lambda: next(
            (
                node
                for node in machine.ctl("tree", ".pop .mi")["nodes"]
                if node["text"] == "Rename"
            ),
            None,
        )
    )
    machine.click(rename)
    machine.until(lambda: machine.ctl("tree", "input")["nodes"])
    machine.ctl("select-text", "0", str(len(old.encode())))
    machine.ctl("type", json.dumps(new))
    machine.keys("Return")


def share_a_tab(desk, laptop):
    """Points both windows at desk's space, with laptop the last one used."""
    name_spaces(desk, laptop)
    shared = session_named(laptop, "desk-one")
    laptop.lua(f"cx.sessions:switch({shared})")
    laptop.until(lambda: laptop.current()["id"] == shared)
    use(laptop)
    laptop.until(lambda: shown_sidebar(laptop))


def test_attached_window_lists_both_machines_and_opens_spaces_on_each(machines):
    desk, laptop = machines
    share_a_tab(desk, laptop)
    assert len(own_machines(laptop)) == 2
    laptop.until(lambda: shows_own_machines(laptop))
    laptop.until(lambda: {"laptop-one", "desk-one"} <= set(laptop.space_names()))

    open_space(laptop, "laptop-one")
    laptop.until(lambda: shows_own_machines(laptop))
    open_space(laptop, "desk-one")
    laptop.until(lambda: shows_own_machines(laptop))
    open_space(laptop, "laptop-one")
    assert {"laptop-one", "desk-one"} <= set(laptop.space_names())


def test_most_recently_used_window_owns_the_shared_sidebar(machines):
    desk, laptop = machines
    share_a_tab(desk, laptop)
    laptop.until(lambda: shows_own_machines(laptop))
    # Desk shows the same panel: for now it holds laptop's machines.
    desk.until(lambda: len(desk.host_names()) == 2)

    # The first click in a window that did not draw the sidebar redraws it for that window.
    desk.click(desk.until(lambda: space_button(desk, "desk-one")))
    desk.until(lambda: shows_own_machines(desk))
    assert "laptop-one" not in desk.space_names()
    desk_two = add_space(desk, "desk-two")
    open_space(desk, "desk-two")
    assert desk.current()["id"] == desk_two
    open_space(desk, "desk-one")

    # Laptop takes the shared tab back by using it, and sees the space desk added. Desk's many
    # uses in between must not outrank it: an idle desk would take the sidebar straight back.
    laptop.until(lambda: shown_record(laptop) == shown_record(desk))
    use(laptop)
    laptop.until(lambda: shows_own_machines(laptop))
    laptop.until(lambda: "desk-two" in laptop.space_names())
    open_space(laptop, "desk-two")
    open_space(laptop, "laptop-one")


def test_idle_windows_do_not_fight_over_the_shared_sidebar(machines):
    desk, laptop = machines
    share_a_tab(desk, laptop)
    laptop.until(lambda: shows_own_machines(laptop))
    desk.until(lambda: len(desk.host_names()) == 2)
    time.sleep(2)
    records = {machine: machine.panel_records() for machine in machines}
    names = laptop.space_names()
    deadline = time.monotonic() + IDLE_SECONDS
    while time.monotonic() < deadline:
        for machine in machines:
            assert machine.panel_records() == records[machine]
            assert machine.space_names() == names
            assert not machine.panel_problems()


def test_windows_on_different_tabs_keep_their_own_sidebars(machines):
    desk, laptop = machines
    name_spaces(desk, laptop)
    use(laptop)
    open_space(laptop, "laptop-one")
    use(desk)
    laptop.until(lambda: shows_own_machines(laptop))
    desk.until(lambda: shows_own_machines(desk))
    assert len(laptop.host_names()) == 2 and len(desk.host_names()) == 1

    # Laptop looks at a desk tab that desk is not showing; desk keeps its own.
    add_space(desk, "desk-two")
    open_space(laptop, "desk-two")
    laptop.until(lambda: shows_own_machines(laptop))
    desk.until(lambda: shows_own_machines(desk))
    open_space(desk, "desk-one")
    assert shows_own_machines(desk)
    assert shows_own_machines(laptop)


def test_name_typed_on_one_machine_survives_cd_on_the_other(machines):
    desk, laptop = machines
    share_a_tab(desk, laptop)
    laptop.until(lambda: shows_own_machines(laptop))
    rename_from_sidebar(laptop, "desk-one", "typed on laptop")
    desk.until(lambda: desk.current()["name"] == "typed on laptop")

    elsewhere = desk.root / "elsewhere"
    elsewhere.mkdir()
    desk.until(lambda: desk.terminal().get("kind") == "terminal")
    desk.run(f"cd {elsewhere}")
    desk.until(lambda: desk.terminal().get("cwd") == str(elsewhere))
    for machine in machines:
        machine.ctl("wait", "1000")
    assert desk.current()["name"] == "typed on laptop"
    assert laptop.current()["name"] == "typed on laptop"
