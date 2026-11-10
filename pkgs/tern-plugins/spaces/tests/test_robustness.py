"""The sidebar must be there, exactly once, and usable: at any size and after any disturbance."""

import json
import time

import pytest

from harness import PLUGIN_ID

# Native Tern windows clamp smaller requests to 720 × 440.
WINDOW_SIZES = {"tiny": (720, 440), "laptop": (1366, 768), "wide": (2560, 1440)}
SPACE_COUNTS = [1, 12, 40]
IDLE_SECONDS = 4
ROGUE_PANELS = 5
CREATE_TIMEOUT = 60
RELOADS = 8
PAST_ANY_LIST = 100_000
# Appended to the plugin so a test can leave the debris a crashed or older version would.
ROGUE_PANEL_COMMAND = """
tern.command({
  id = "test_rogue_panel",
  title = "Open a stale sidebar",
  run = function(cx: WindowCx)
    cx.canvas:open({
      title = "Spaces",
      view = tern.ui.text("stale"),
      target = cx.session:focused(),
      dir = "left",
      ratio = 0.2,
      focus = false,
    })
  end,
})
"""
# One space per callback keeps each inside Tern's hook budget; the stored name stops the
# shell's first working-directory report from renaming the space.
CREATE_SPACES_COMMAND = """
do
  local names = tern.json.decode(%s)
  local function createNext(cx: WindowCx)
    local name = table.remove(names, 1)
    if not name then
      return
    end
    local home = cx.sessions:current().id
    local session = cx.sessions:create({ name = name })
    tern.kv.set("custom-name:" .. session.id, name)
    cx.sessions:switch(home)
    tern.timer(0, createNext)
  end
  tern.command({ id = "%s", title = "Create test spaces", run = createNext })
end
"""
UNUSUAL_NAMES = [
    "%d+%s (100%)",
    "名前 🚀 مرحبا",
    'quote " and \\ backslash',
    # Far wider than any sidebar; the control socket reports at most 200 characters of a text.
    "x" * 150,
    "<b>not markup</b>",
]


def create_spaces(tern, names):
    """Adds spaces whose names stay as given, and returns their ids in order."""
    if not names:
        return []
    before = {session["id"] for session in tern.snapshot()["sessions"]}
    command = f"test_create_{len(before)}"
    tern.extend_plugin(CREATE_SPACES_COMMAND % (json.dumps(json.dumps(names)), command))
    tern.ctl("plugins", "run", f"plugin.{PLUGIN_ID}.{command}")

    def created():
        sessions = [s for s in tern.snapshot()["sessions"] if s["id"] not in before]
        by_name = {session["name"]: session["id"] for session in sessions}
        return [by_name[name] for name in names] if set(names) <= set(by_name) else None

    return tern.until(created, timeout=CREATE_TIMEOUT)


def shown_sidebar(tern):
    """The one sidebar in the tab on screen, or None while it is missing or duplicated."""
    state = tern.snapshot()
    tab = next(
        (p.get("tab") for p in state["panes"] if p["pane"] == state["focused"]), None
    )
    if tab is None:
        return None
    panes = tern.panels(state).get(tab, [])
    return panes[0] if len(panes) == 1 else None


def space_button(tern, name):
    return next(
        (
            node
            for node in tern.ctl("tree", ".space-name button")["nodes"]
            if node["text"] == name
        ),
        None,
    )


def on_screen(node, size):
    x, y, width, height = node["rect"]
    return x >= 0 and y >= 0 and x + width <= size[0] and y + height <= size[1]


def wheel(tern, size, distance):
    panel = tern.panel_tree()[0]["rect"]
    tern.ctl("move", str(panel[0] + panel[2] / 2), str(size[1] / 2))
    tern.ctl("wheel", "0", str(distance))
    tern.ctl("wait", "100")


def listed_spaces(tern, size):
    """Every row of the sidebar, top to bottom: a short window shows a long list in parts."""
    wheel(tern, size, -PAST_ANY_LIST)
    names = tern.space_names()
    while True:
        wheel(tern, size, size[1] / 2)
        below = [name for name in tern.space_names() if name not in names]
        if not below:
            break
        names += below
    wheel(tern, size, -PAST_ANY_LIST)
    return names


def scroll_to_space(tern, name, size):
    def visible():
        node = space_button(tern, name)
        if node and on_screen(node, size):
            return node
        wheel(tern, size, (-1 if node and node["rect"][1] < 0 else 1) * size[1] / 2)
        return None

    return tern.until(visible)


@pytest.mark.parametrize("count", SPACE_COUNTS)
@pytest.mark.parametrize("size", WINDOW_SIZES.values(), ids=WINDOW_SIZES.keys())
def test_sidebar_lists_all_spaces_and_opens_scrolled_rows_at_any_size(
    tern, size, count
):
    tern.ctl("resize", str(size[0]), str(size[1]))
    first = tern.current()["id"]
    names = [f"space-{index:02d}" for index in range(2, count + 1)]
    created = create_spaces(tern, names)
    tern.lua('cx.sessions:rename(nil, "space-01")')
    ids = dict(zip(["space-01", *names], [first, *created]))

    tern.until(lambda: sorted(listed_spaces(tern, size)) == sorted(ids))
    sidebar = tern.until(lambda: shown_sidebar(tern))
    panel = tern.panel_tree()[0]
    assert panel["rect"][2] > 0 and panel["rect"][3] > 0
    assert panel["rect"][0] + panel["rect"][2] <= size[0]
    terminal = tern.terminal()
    assert terminal["kind"] == "terminal" and terminal["pane"] != sidebar

    # Include the bottom row: a long list must remain reachable on a small display.
    names = list(ids)
    for name in dict.fromkeys((names[0], names[len(names) // 2], names[-1])):
        tern.click(scroll_to_space(tern, name, size))
        tern.until(lambda: tern.current()["id"] == ids[name])
        tern.until(lambda: shown_sidebar(tern))
        tern.until(lambda: sorted(listed_spaces(tern, size)) == sorted(ids))
    assert len(tern.snapshot()["sessions"]) == count


@pytest.mark.parametrize("size", WINDOW_SIZES.values(), ids=WINDOW_SIZES.keys())
def test_sidebar_survives_resizing_between_sizes(tern, size):
    sidebar = tern.until(lambda: shown_sidebar(tern))
    terminal = tern.terminal()["pane"]
    for width, height in (size, WINDOW_SIZES["tiny"], size):
        tern.ctl("resize", str(width), str(height))
        tern.until(lambda: shown_sidebar(tern))
    assert shown_sidebar(tern) == sidebar
    assert tern.terminal()["pane"] == terminal


@pytest.mark.parametrize("disturbance", ["close", "park"])
def test_closed_sidebar_comes_back_once_and_stays(tern, disturbance):
    sidebar = tern.until(lambda: shown_sidebar(tern))
    terminal = tern.terminal()["pane"]
    if disturbance == "park":
        tern.lua(f"cx.layout:focus({sidebar})")
        tern.ctl("park")
    else:
        tern.lua(f"cx.layout:close({sidebar})")
    reopened = tern.until(
        lambda: shown_sidebar(tern) if shown_sidebar(tern) != sidebar else None
    )
    deadline = time.monotonic() + IDLE_SECONDS
    while time.monotonic() < deadline:
        assert shown_sidebar(tern) == reopened
    assert tern.terminal()["pane"] == terminal
    assert tern.space_names() == [tern.current()["name"]]


def test_idle_sidebar_is_neither_reopened_nor_redrawn(tern):
    tern.keys("ctrl+b", "c")
    create_spaces(tern, ["second", "third"])
    tern.until(lambda: len(tern.space_names()) == 3)
    tern.until(lambda: shown_sidebar(tern))
    time.sleep(1)
    panes = {pane["pane"] for pane in tern.snapshot()["panes"]}
    records = tern.panel_records()
    deadline = time.monotonic() + IDLE_SECONDS
    while time.monotonic() < deadline:
        assert {pane["pane"] for pane in tern.snapshot()["panes"]} == panes
        assert tern.panel_records() == records


def test_stale_and_duplicate_sidebars_collapse_to_the_working_one(tern):
    tern.keys("ctrl+b", "c")
    session = tern.current()["id"]
    tern.until(lambda: len(tern.tabs(session)) == 2)
    terminals = {
        pane["pane"]
        for pane in tern.snapshot()["panes"]
        if pane.get("kind") == "terminal"
    }
    tern.extend_plugin(ROGUE_PANEL_COMMAND)
    for _ in range(ROGUE_PANELS):
        tern.ctl("plugins", "run", f"plugin.{PLUGIN_ID}.test_rogue_panel")
    tern.until(lambda: shown_sidebar(tern))
    tern.until(lambda: not tern.panel_problems() or None)
    assert tern.space_names() == [tern.current()["name"]]
    assert "stale" not in tern.panel_tree()[0]["text"]
    assert {
        pane["pane"]
        for pane in tern.snapshot()["panes"]
        if pane.get("kind") == "terminal"
    } == terminals
    # The survivor still works.
    other = create_spaces(tern, ["other"])[0]
    tern.click(tern.until(lambda: space_button(tern, "other")))
    tern.until(lambda: tern.current()["id"] == other)


def test_reload_storm_keeps_one_sidebar_and_every_terminal(tern):
    tern.keys("ctrl+b", "c")
    session = tern.current()["id"]
    tern.until(lambda: len(tern.tabs(session)) == 2)
    create_spaces(tern, ["second", "third"])
    tern.until(lambda: len(tern.space_names()) == 3)
    sidebar = tern.until(lambda: shown_sidebar(tern))
    terminals = {
        pane["pane"]
        for pane in tern.snapshot()["panes"]
        if pane.get("kind") == "terminal"
    }
    for _ in range(RELOADS):
        tern.reload(PLUGIN_ID)
    tern.until(lambda: len(tern.space_names()) == 3)
    assert shown_sidebar(tern) == sidebar
    assert {
        pane["pane"]
        for pane in tern.snapshot()["panes"]
        if pane.get("kind") == "terminal"
    } == terminals
    assert tern.windows() == {tern.window}


def test_every_tab_of_a_space_gets_its_own_single_sidebar(tern):
    session = tern.current()["id"]
    for count in range(2, 6):
        tern.keys("ctrl+b", "c")
        tern.until(lambda: len(tern.tabs(session)) == count)
        tern.until(lambda: shown_sidebar(tern))
    for tab in tern.tabs(session):
        tern.lua(f"cx.layout:focus({tab['pane']})")
        tern.until(lambda: tern.terminal()["tab"] == tab["id"] and shown_sidebar(tern))
    assert len(tern.tabs(session)) == 5
    assert not tern.panel_problems()


def test_unusual_space_names_render_and_stay_clickable(tern):
    first = tern.current()["id"]
    ids = create_spaces(tern, UNUSUAL_NAMES)
    tern.until(lambda: len(tern.space_names()) == len(UNUSUAL_NAMES) + 1)
    assert set(UNUSUAL_NAMES) <= set(tern.space_names())
    for name, session in zip(UNUSUAL_NAMES, ids):
        tern.click(tern.until(lambda: space_button(tern, name)))
        tern.until(lambda: tern.current()["id"] == session)
        tern.until(lambda: shown_sidebar(tern))
    assert first in {s["id"] for s in tern.snapshot()["sessions"]}


def test_hidden_sidebar_stays_hidden_until_asked_back(tern):
    tern.until(lambda: shown_sidebar(tern))
    tern.ctl("plugins", "run", f"plugin.{PLUGIN_ID}.toggle_sidebar")
    tern.until(lambda: not tern.panels())
    tern.keys("ctrl+b", "c")
    deadline = time.monotonic() + IDLE_SECONDS
    while time.monotonic() < deadline:
        assert not tern.panels()
    tern.ctl("plugins", "run", f"plugin.{PLUGIN_ID}.toggle_sidebar")
    tern.until(lambda: shown_sidebar(tern))
    assert tern.space_names() == [tern.current()["name"]]
