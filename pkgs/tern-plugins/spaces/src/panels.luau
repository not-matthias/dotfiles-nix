--!strict

-- A sidebar panel is a canvas stored with its tab, so every window attached to that session shows
-- the same panel. Its view holds window-local ids and only the machines its author is attached to,
-- so a panel works only in the window that drew it. `about` records that window and how recently it
-- was used; a window redraws another's panel only in the tab it shows, and only when it was used
-- more recently.

local DEFAULT_WIDTH = 0.15
-- Only drags are persisted, so changing DEFAULT_WIDTH reaches users who never resized.
local WIDTH_KEY = "sidebar-width"
local WRITER_KEY = "writer-id"
local WIDTH_TOLERANCE = 0.0001
local MAX_SPLIT_SHARE = 0.99
local FLUSH_BUDGET_MS = 15
local OPENING_TIMEOUT_MS = 2000
local TITLE = "Spaces"
local ABOUT = "Spaces sidebar drawn by window %s at use %d"
local ABOUT_PATTERN = "^Spaces sidebar drawn by window (%S+) at use (%d+)$"

type Content = { signature: string, render: () -> Node }
type Update = { pane: number?, target: number, focus: number?, session: number, content: Content }

local sharedWidth: number = tern.kv.get(WIDTH_KEY) or DEFAULT_WIDTH
local me: string? = nil
-- Logical clocks: uses of this window, and the latest use any panel records. The panel in the
-- shown tab records every use.
local activity = 0
local seen = 0
-- Loading the plugin counts as a use: a window that just opened owns the tab it shows.
local used = true
-- pane -> what this window last drew there and the width it last saw.
local drawn = {}
-- tab -> the panel opened there that the pane list does not show yet.
local opening = {}
-- One reopen per tab per width; a layout that clamps the ratio would otherwise loop.
local reopened = {}
local queue: { [number]: Update } = {}
local scheduled = false
local shown: number? = nil
local panelByTab: { [number]: number } = {}
local restoreFocus = {}
local reported = {}

local function identity(cx: WindowCx): string
  if not me then
    local id = tern.kv.get(WRITER_KEY)
    if type(id) ~= "string" then
      id = string.format("%x-%x", os.time(), math.random(1, 0x7fffffff))
      tern.kv.set(WRITER_KEY, id)
    end
    me = id .. "/" .. cx:window_key()
  end
  return me :: string
end

local function canvases(cx: WindowCx)
  local result = {}
  for _, canvas in cx.canvas:list() do
    if canvas.owner == tern.plugin.id then
      local writer, stamp = string.match(canvas.about or "", ABOUT_PATTERN)
      result[canvas.pane] = { writer = writer, stamp = tonumber(stamp) or 0 }
    end
  end
  return result
end

-- The pane's share of the tab width, and the ratio of the split directly holding it.
local function paneGeometry(node: TabTree, pane: number, share: number, divider: number?): (number?, number?)
  if node.pane then
    if node.pane == pane then
      return share, divider
    end
    return nil, nil
  end
  local horizontal = node.split == "right"
  local found, ratio = paneGeometry(node[1], pane, if horizontal then share * node.ratio else share, node.ratio)
  if found then
    return found, ratio
  end
  return paneGeometry(node[2], pane, if horizontal then share * (1 - node.ratio) else share, node.ratio)
end

local function geometry(cx: WindowCx, pane: number): (number?, number?)
  local tab = cx.session:tab_of(pane)
  local layout = if tab then cx.session:layout(tab) else nil
  if not layout then
    return nil, nil
  end
  return paneGeometry(layout.root, pane, 1, nil)
end

local function leaves(node: TabTree, order: { [number]: number }, index: number): number
  if node.pane then
    order[node.pane] = index
    return index + 1
  end
  return leaves(node[2], order, leaves(node[1], order, index))
end

-- Every window must keep the same duplicate, and pane ids are window-local: the shared layout decides.
local function keepFirst(cx: WindowCx, tab: number, panes: { number }): number
  local layout = cx.session:layout(tab)
  local order = {}
  if layout then
    leaves(layout.root, order, 1)
  end
  table.sort(panes, function(a, b)
    return (order[a] or math.huge) < (order[b] or math.huge)
  end)
  for index = 2, #panes do
    cx.layout:close(panes[index])
  end
  return panes[1]
end

-- Only moving the panel's own divider is a resize. Closing a split neighbour also changes its
-- share, but sync reopens it at the shared width instead.
local function observeDrag(cx: WindowCx)
  local entry = if shown then drawn[shown] else nil
  if not entry or not entry.requested then
    return
  end
  local actual, divider = geometry(cx, shown :: number)
  if not actual then
    return
  end
  if entry.divider and divider and math.abs(divider - entry.divider) > WIDTH_TOLERANCE then
    sharedWidth = actual
    tern.kv.set(WIDTH_KEY, actual)
    entry.requested = actual
    entry.actual = actual
  end
  entry.divider = divider
end

-- Exact ratios require reopening: returns true after closing the panel for sync to replace.
local function fitWidth(cx: WindowCx, tab: number, pane: number): boolean
  local actual, divider = geometry(cx, pane)
  if not actual then
    return false
  end
  local entry = drawn[pane] or {}
  drawn[pane] = entry
  local relaid = entry.actual and math.abs(actual - entry.actual) > WIDTH_TOLERANCE
  if not entry.requested or relaid or math.abs(entry.requested - sharedWidth) > WIDTH_TOLERANCE then
    if math.abs(actual - sharedWidth) > WIDTH_TOLERANCE and reopened[tab] ~= sharedWidth then
      reopened[tab] = sharedWidth
      cx.layout:close(pane)
      drawn[pane] = nil
      return true
    end
    entry.requested = sharedWidth
    entry.actual = actual
    entry.divider = divider
  elseif not entry.actual then
    -- Minimum pane sizes may clamp the opening ratio; this is not a drag.
    entry.actual = actual
    entry.divider = divider
  end
  return false
end

local function panelIn(cx: WindowCx, tab: number): boolean
  for pane in canvases(cx) do
    if cx.session:tab_of(pane) == tab then
      return true
    end
  end
  return false
end

local function apply(cx: WindowCx, tab: number, update: Update, visible: number?)
  -- The queue outlives the callback that filled it.
  if cx.session:tab_of(update.target) ~= tab then
    return
  end
  local about = string.format(ABOUT, identity(cx), activity)
  local pane = update.pane
  if pane then
    if cx.session:tab_of(pane) ~= tab then
      return
    end
    local canvas = canvases(cx)[pane]
    if not canvas then
      return
    end
    local mine = canvas.writer == identity(cx)
    if canvas.writer and not mine and not (visible == tab and activity > canvas.stamp) then
      return
    end
    local entry = drawn[pane]
    -- Recording a use keeps the view this window already drew.
    local unchanged = mine and entry and entry.signature == update.content.signature and entry.session == update.session
    cx.canvas:set(pane, { view = if unchanged then nil else update.content.render(), about = about })
  else
    -- Never open a second panel: another window or callback may have opened one since sync.
    if opening[tab] or visible ~= tab or panelIn(cx, tab) then
      return
    end
    local targetShare = geometry(cx, update.target) or 1
    local opened, err = cx.canvas:open({
      title = TITLE,
      about = about,
      view = update.content.render(),
      target = update.target,
      dir = "left",
      ratio = math.min(sharedWidth / targetShare, MAX_SPLIT_SHARE),
      focus = false,
    })
    if not opened then
      if err and reported[tab] ~= err then
        reported[tab] = err
        cx:toast("error", TITLE, err)
      end
      return
    end
    reported[tab] = nil
    pane = opened
    opening[tab] = { pane = opened, at = tern.now() }
    -- focus=false preserves the shown pane, but changes hidden tabs' focus.
    if update.focus and update.focus ~= cx.session:focused() then
      restoreFocus[opened] = update.focus
    end
    drawn[opened] = { requested = sharedWidth }
  end
  local entry = drawn[pane] or {}
  drawn[pane] = entry
  entry.signature = update.content.signature
  entry.session = update.session
  entry.stamp = activity
end

local module = {}

-- Draws the shown tab first and stops early: each callback has a 50 ms budget.
function module.flush(cx: WindowCx)
  scheduled = false
  local started = tern.now()
  local focused = cx.session:focused()
  local visible = if focused then cx.session:tab_of(focused) else nil
  while next(queue) do
    local tab = if visible and queue[visible] then visible else next(queue)
    local update = queue[tab]
    queue[tab] = nil
    apply(cx, tab, update, visible)
    if tern.now() - started > FLUSH_BUDGET_MS then
      break
    end
  end
  if next(queue) then
    scheduled = true
    tern.timer(0, module.flush)
  end
end

-- Uses of this window decide which window owns a panel that two of them show.
function module.touch()
  used = true
end

function module.status(cx: WindowCx, pane: number, about: string?): "none" | "foreign" | "mine"
  local canvas = canvases(cx)[pane]
  if not canvas then
    return "none"
  end
  -- A queued click belongs to the view that emitted it, not a later redraw.
  local writer = if about then string.match(about, ABOUT_PATTERN) else canvas.writer
  return if writer == identity(cx) then "mine" else "foreign"
end

function module.pending(): boolean
  return next(queue) ~= nil
end

function module.focus(ev: FocusEvent, cx: WindowCx)
  observeDrag(cx)
  shown = panelByTab[ev.tab]
  local restore = restoreFocus[ev.pane]
  if restore and cx.session:focused() == ev.pane then
    restoreFocus[ev.pane] = nil
    if cx.session:tab_of(restore) == ev.tab then
      cx.layout:focus(restore)
    end
  elseif shown and ev.pane ~= shown then
    restoreFocus[shown] = nil
  end
end

function module.closed(pane: number)
  for tab, entry in opening do
    if entry.pane == pane then
      opening[tab] = nil
    end
  end
end

-- Another window may still show panels it drew; only this window's are closed.
function module.hide(cx: WindowCx)
  local self = identity(cx)
  for pane, canvas in canvases(cx) do
    if not canvas.writer or canvas.writer == self then
      cx.layout:close(pane)
    end
  end
  queue = {}
end

function module.sync(cx: WindowCx, state, contentFor: (session: number) -> Content)
  local self = identity(cx)
  observeDrag(cx)
  local owned = canvases(cx)
  for _, canvas in owned do
    seen = math.max(seen, canvas.stamp)
  end
  if used then
    used = false
    activity = math.max(activity, seen) + 1
  end

  local rows = {}
  local content = {}
  for _, pane in state.panes do
    rows[pane.pane] = pane
    if pane.tab and not pane.parked and not pane.floating and not owned[pane.pane] then
      content[pane.tab] = content[pane.tab] or pane.pane
    end
  end

  local candidates = {}
  for pane in owned do
    local row = rows[pane]
    if not row then
      continue
    end
    local tab = row.tab
    if not tab then
      -- A parked sidebar shows nothing and would never be found again.
      if row.parked then
        cx.layout:close(pane)
      end
      continue
    end
    -- Panels never keep empty tabs alive.
    if not content[tab] then
      cx.layout:close(pane)
      drawn[pane] = nil
      continue
    end
    candidates[tab] = candidates[tab] or {}
    table.insert(candidates[tab], pane)
  end
  local byTab = {}
  for tab, panes in candidates do
    byTab[tab] = if #panes == 1 then panes[1] else keepFirst(cx, tab, panes)
  end
  for tab, entry in opening do
    local row = rows[entry.pane]
    if byTab[tab] == entry.pane or not content[tab] then
      opening[tab] = nil
    elseif (row and row.tab ~= tab) or tern.now() - entry.at > OPENING_TIMEOUT_MS then
      -- It landed elsewhere or never appeared: this tab may try again.
      opening[tab] = nil
      if row and owned[entry.pane] and byTab[row.tab] ~= entry.pane then
        cx.layout:close(entry.pane)
      end
    end
  end
  panelByTab = byTab
  shown = byTab[state.activeTab]

  local nextQueue: { [number]: Update } = {}
  local live = {}
  for pane in owned do
    live[pane] = true
  end
  local liveTabs = {}
  for _, tab in state.tabs do
    liveTabs[tab.id] = true
    local target = content[tab.id]
    if not target then
      continue
    end
    local visible = tab.id == state.activeTab
    local pane = byTab[tab.id]
    if not pane then
      if opening[tab.id] then
        live[opening[tab.id].pane] = true
      elseif visible then
        nextQueue[tab.id] = {
          target = target,
          focus = if not owned[tab.pane] then tab.pane else nil,
          session = tab.session,
          content = contentFor(tab.session),
        }
      end
      continue
    end
    local canvas = owned[pane]
    local mine = canvas.writer == self
    if canvas.writer and not mine and not (visible and activity > canvas.stamp) then
      drawn[pane] = nil
      continue
    end
    if visible and fitWidth(cx, tab.id, pane) then
      continue
    end
    local tabContent = contentFor(tab.session)
    local entry = drawn[pane]
    local unchanged = mine and entry and entry.signature == tabContent.signature and entry.session == tab.session
    -- The shown panel records every use, even when nothing else changed: a use another window
    -- never saw would outrank its later ones and take the panel back while this window is idle.
    if unchanged and (not visible or entry.stamp == activity) then
      continue
    end
    nextQueue[tab.id] = { pane = pane, target = target, session = tab.session, content = tabContent }
  end

  for pane in drawn do
    if not live[pane] then
      drawn[pane] = nil
      restoreFocus[pane] = nil
    end
  end
  for tab in reopened do
    if not liveTabs[tab] then
      reopened[tab] = nil
    end
  end
  for tab in reported do
    if not liveTabs[tab] then
      reported[tab] = nil
    end
  end
  queue = nextQueue
  if next(queue) and not scheduled then
    scheduled = true
    tern.timer(0, module.flush)
  end
end

return module
