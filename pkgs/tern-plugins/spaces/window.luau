--!strict

-- Mobile keeps Tern's native session UI; the sidebar does not fit there.
local MOBILE_OS = { ios = true, android = true }
if MOBILE_OS[tern.runtime.os] then
  return
end

local stateModel = require("./state")
local view = require("./view")
local profiles = require("./profiles")

local PANEL_SHARE = 0.15
-- Only drags are persisted, so changing PANEL_SHARE reaches users who never resized.
local WIDTH_KEY = "sidebar-width"
local COLLAPSED_PREFIX = "collapsed:"
local WIDTH_TOLERANCE = 0.0001
local MAX_SPLIT_SHARE = 0.99
local REFRESH_MS = 1000
local GROUP = "Spaces"
local CUSTOM_NAME_PREFIX = "custom-name:"
local rendered = {}
local pending = {}
-- KV is shared by every window and re-read when it changes on disk.
local function isCollapsed(host: string): boolean
  return tern.kv.get(COLLAPSED_PREFIX .. host) == true
end
local syncing = false
local sharedWidth: number = tern.kv.get(WIDTH_KEY) or PANEL_SHARE
local widths = {}
local activePanel = nil
local panelByTab = {}
local focusAfterOpen = {}
local updates = {}
local updateScheduled = false
-- One reopen per tab per width; a layout that clamps the ratio would otherwise loop.
local reopenedWidth = {}

local function panels(cx: WindowCx)
  local result = {}
  for _, panel in cx.canvas:list() do
    if panel.owner == tern.plugin.id then
      result[panel.pane] = true
    end
  end
  return result
end

local function existingPanel(cx: WindowCx, tab: number): number?
  for _, panel in cx.canvas:list() do
    if panel.owner == tern.plugin.id and cx.session:tab_of(panel.pane) == tab then
      return panel.pane
    end
  end
  return nil
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

local function panelGeometry(cx: WindowCx, pane: number): (number?, number?)
  local tab = cx.session:tab_of(pane)
  local layout = if tab then cx.session:layout(tab) else nil
  if not layout then
    return nil, nil
  end
  return paneGeometry(layout.root, pane, 1, nil)
end

local function panelWidth(cx: WindowCx, pane: number): number?
  return (panelGeometry(cx, pane))
end

local function rememberWidth(width: number)
  sharedWidth = width
  tern.kv.set(WIDTH_KEY, width)
end

local function observeWidth(cx: WindowCx): boolean
  local previous = if activePanel then widths[activePanel] else nil
  if not previous then
    return false
  end
  local actual, divider = panelGeometry(cx, activePanel)
  if not actual then
    return false
  end
  -- Only moving the panel's own divider is a resize. Closing a split neighbour
  -- also changes its share, but sync reopens it at the shared width instead.
  local dragged = previous.divider ~= nil and divider ~= nil and math.abs(divider - previous.divider) > WIDTH_TOLERANCE
  if dragged then
    rememberWidth(actual)
    previous.requested = actual
    previous.actual = actual
  end
  previous.divider = divider
  return dragged
end

-- Render one panel per callback to stay within Tern's plugin-hook budget.
local function flush(cx: WindowCx)
  updateScheduled = false
  local focused = cx.session:focused()
  local tab = if focused then cx.session:tab_of(focused) else nil
  local update = if tab then updates[tab] else nil
  if not update then
    tab, update = next(updates)
  end
  if not tab then
    return
  end
  updates[tab] = nil
  -- Recheck the pane after yielding to a render callback.
  if cx.session:tab_of(update.target) == tab and (not update.pane or cx.session:tab_of(update.pane) == tab) then
    local root = view(update.model, update.session, update.profiles)
    -- Never open a second panel: sync may predate a panel another window or callback opened.
    local pane = update.pane or existingPanel(cx, tab)
    if pane then
      cx.canvas:set(pane, { view = root })
    elseif not pending[tab] and focused and cx.session:tab_of(focused) == tab then
      local targetWidth = panelWidth(cx, update.target) or 1
      local err
      pane, err = cx.canvas:open({
        title = "Spaces",
        view = root,
        target = update.target,
        dir = "left",
        ratio = math.min(sharedWidth / targetWidth, MAX_SPLIT_SHARE),
        focus = false,
      })
      if pane then
        pending[tab] = pane
        panelByTab[tab] = pane
        -- focus=false preserves the shown pane, but changes hidden tabs' focus.
        if update.focus ~= cx.session:focused() then
          focusAfterOpen[pane] = update.focus
        end
        widths[pane] = { requested = sharedWidth }
      elseif err then
        cx:toast("error", err)
      end
    end
    if pane then
      rendered[pane] = { signature = update.signature, session = update.session }
    end
  end
  if next(updates) then
    updateScheduled = true
    tern.timer(0, flush)
  end
end

local function sync(cx: WindowCx)
  if syncing then
    return
  end
  syncing = true
  profiles.refresh(cx)
  observeWidth(cx)
  local owned = panels(cx)
  if profiles.hidden() then
    for pane in owned do
      cx.layout:close(pane)
    end
    updates = {}
    syncing = false
    return
  end
  local state = {
    panes = cx.session:panes(),
    tabs = cx.session:tabs(),
    sessions = cx.sessions:list(),
    hosts = cx.hosts:list(),
  }
  local tabByPane = {}
  for _, pane in state.panes do
    tabByPane[pane.pane] = pane.tab
  end
  state.activeTab = tabByPane[cx.session:focused()]
  local contents = {}
  for _, pane in state.panes do
    if not owned[pane.pane] and not pane.parked then
      contents[pane.tab] = contents[pane.tab] or pane.pane
    end
  end
  local byTab = {}
  for pane in owned do
    local tab = tabByPane[pane]
    if tab then
      pending[tab] = nil
      -- Panels never keep empty tabs alive; concurrent windows may create duplicates.
      if not contents[tab] or (byTab[tab] and byTab[tab] < pane) then
        cx.layout:close(pane)
        rendered[pane] = nil
      else
        if byTab[tab] then
          cx.layout:close(byTab[tab])
          rendered[byTab[tab]] = nil
        end
        byTab[tab] = pane
      end
    end
  end
  panelByTab = byTab
  activePanel = byTab[state.activeTab]
  local fullModel = stateModel.sidebarModel(cx, state, isCollapsed)
  local profileModels = {}
  local function profileFor(session: number)
    local profileId = profiles.profileId(session)
    local profile = profileModels[profileId]
    if not profile then
      local model = profiles.filter(fullModel, session, state.sessions)
      local profileModel = profiles.model(session)
      profile = {
        model = model,
        profiles = profileModel,
        signature = tern.json.encode({ spaces = model, profiles = profileModel }),
      }
      profileModels[profileId] = profile
    end
    return profile
  end
  local nextUpdates = {}
  local live = table.clone(owned)
  for _, tab in state.tabs do
    local target = contents[tab.id]
    if not target then
      pending[tab.id] = nil
      continue
    end
    local existing = byTab[tab.id]
    if not existing and tab.id ~= state.activeTab then
      continue
    end
    if pending[tab.id] then
      live[pending[tab.id]] = true
      continue
    end
    if existing then
      local actual, divider = panelGeometry(cx, existing)
      local previous = widths[existing]
      if actual and tab.id == state.activeTab then
        local relaid = previous and previous.actual and math.abs(actual - previous.actual) > WIDTH_TOLERANCE
        if not previous or relaid or math.abs(previous.requested - sharedWidth) > WIDTH_TOLERANCE then
          -- Reopen at most once per width: layouts that clamp the ratio would otherwise loop.
          if math.abs(actual - sharedWidth) > WIDTH_TOLERANCE and reopenedWidth[tab.id] ~= sharedWidth then
            -- Exact ratios require reopening. Wait for pane_closed before replacing
            -- the panel so remote layouts have removed its old split.
            reopenedWidth[tab.id] = sharedWidth
            cx.layout:close(existing)
            widths[existing] = nil
            rendered[existing] = nil
            byTab[tab.id] = nil
            continue
          else
            widths[existing] = { requested = sharedWidth, actual = actual, divider = divider }
          end
        elseif not previous.actual then
          -- Minimum pane sizes may clamp the opening ratio; this is not a drag.
          previous.actual = actual
          previous.divider = divider
        end
      end
      local profile = profileFor(tab.session)
      local cached = rendered[existing]
      if cached and cached.signature == profile.signature and cached.session == tab.session then
        continue
      end
    end
    local profile = profileFor(tab.session)
    nextUpdates[tab.id] = {
      pane = existing,
      target = target,
      focus = if not owned[tab.pane] then tab.pane else nil,
      session = tab.session,
      model = profile.model,
      profiles = profile.profiles,
      signature = profile.signature,
    }
  end
  for pane in widths do
    if not live[pane] then
      rendered[pane] = nil
      widths[pane] = nil
      focusAfterOpen[pane] = nil
    end
  end
  local liveTabs = {}
  for _, tab in state.tabs do
    liveTabs[tab.id] = true
  end
  for tab in pending do
    if not contents[tab] then
      pending[tab] = nil
    end
  end
  for tab in reopenedWidth do
    if not liveTabs[tab] then
      reopenedWidth[tab] = nil
    end
  end
  updates = nextUpdates
  if next(updates) and not updateScheduled then
    updateScheduled = true
    tern.timer(0, flush)
  end
  syncing = false
end

local function currentDirectory(cx: WindowCx): string?
  local focused = cx.session:focused()
  local tab = if focused then cx.session:tab_of(focused) else nil
  local pane = if tab then stateModel.directoryPanes(cx.session:panes(), cx.session:tabs())[tab] else nil
  return if pane then pane.cwd else nil
end

local function newSpace(cx: WindowCx)
  local cwd = currentDirectory(cx)
  local name = if cwd then string.match(cwd, "([^/]+)/?$") or cwd else nil
  profiles.addSpace(cx, { name = name, cwd = cwd })
  sync(cx)
end

local function newTab(cx: WindowCx)
  cx.layout:new_tab({ cwd = currentDirectory(cx) })
  sync(cx)
end

tern.override("new_tab", function(cx: WindowCx)
  if not panels(cx)[cx.session:focused()] then
    return false
  end
  newTab(cx)
  return true
end)
tern.override("new_session", function(cx: WindowCx)
  newSpace(cx)
  return true
end)

local function renameSpace(cx: WindowCx, id: number)
  for _, session in cx.sessions:list() do
    if session.id ~= id then
      continue
    end
    cx:prompt({ value = session.name, placeholder = "Space name" }):next(function(name, err, fresh)
      if err then
        fresh:toast("error", err)
        return
      end
      if name == nil then
        return
      end
      local trimmed = string.match(name, "^%s*(.-)%s*$")
      if trimmed == "" then
        return
      end
      for _, live in fresh.sessions:list() do
        if live.id == id then
          fresh.sessions:rename(id, trimmed)
          tern.kv.set(CUSTOM_NAME_PREFIX .. id, trimmed)
          sync(fresh)
          return
        end
      end
    end)
    return
  end
end

tern.on("canvas_action", function(ev: CanvasAction, cx: WindowCx)
  local owned = panels(cx)
  if not owned[ev.pane] then
    return false
  end
  local tab = cx.session:tab_of(ev.pane)
  local pane = if tab then stateModel.directoryPanes(cx.session:panes(), cx.session:tabs())[tab] else nil
  if pane then
    cx.layout:focus(pane.pane)
  end
  local move = if ev.act == "Move to profile" then tonumber(string.match(ev.node, "%.space:(%d+)$")) else nil
  if move then
    profiles.move(cx, move)
    return true
  end
  if profiles.action(ev, cx) then
    return true
  end
  local rename = if ev.act == "Rename" then tonumber(string.match(ev.node, "%.space:(%d+)$")) else nil
  if rename then
    renameSpace(cx, rename)
    return true
  end
  local hostId = tonumber(string.match(ev.act, "^host:(%d+)$"))
  if hostId then
    -- Host ids are per connection; names survive reconnects and restarts.
    for _, host in cx.hosts:list() do
      if host.id == hostId then
        tern.kv.set(COLLAPSED_PREFIX .. host.name, if isCollapsed(host.name) then nil else true)
      end
    end
    sync(cx)
    return true
  end
  local session = tonumber(string.match(ev.act, "^space:(%d+)$"))
  if session then
    cx.sessions:switch(session)
  end
  return true
end)

tern.command({ id = "new_space", title = "New space", group = GROUP, run = newSpace })
tern.command({ id = "new_tab", title = "New terminal tab", group = GROUP, run = newTab })
tern.command({
  id = "refresh",
  title = "Show spaces panel",
  group = GROUP,
  run = function(cx)
    profiles.setVisibility("visible")
    sync(cx)
  end,
})
tern.command({
  id = "toggle_sidebar",
  title = "Show/hide spaces sidebar",
  group = GROUP,
  run = function(cx)
    profiles.setVisibility(if profiles.hidden() then "visible" else "hidden")
    sync(cx)
  end,
})

for index = 1, 9 do
  tern.command({
    id = "space_" .. index,
    title = "Go to space " .. index,
    group = GROUP,
    run = function(cx: WindowCx)
      local sessions = profiles.sessions(cx)
      local position = 0
      for _, host in cx.hosts:list() do
        for _, session in sessions do
          if session.host == host.id then
            position += 1
            if position == index then
              cx.sessions:switch(session.id)
              return
            end
          end
        end
      end
    end,
  })
end

tern.on("cwd", function(ev: CwdEvent, cx: WindowCx)
  if ev.path == "" then
    return
  end
  local paneTab = cx.session:tab_of(ev.pane)
  for _, tab in cx.session:tabs() do
    if tab.id == paneTab then
      local custom = tern.kv.get(CUSTOM_NAME_PREFIX .. tab.session)
      for _, session in cx.sessions:list() do
        if session.id == tab.session and session.name == custom then
          return
        end
      end
      cx.sessions:rename(tab.session, string.match(ev.path, "([^/]+)/?$") or ev.path)
      sync(cx)
      return
    end
  end
end)

local function adjacentSpace(cx: WindowCx, sessions, current: number, profileId: string): number?
  local previous = nil
  local afterCurrent = false
  -- Prefer neighbours on the same machine, then fall back to sidebar order.
  for _, host in cx.hosts:list() do
    local previousOnHost = nil
    for _, session in sessions do
      if session.host ~= host.id or profiles.profileId(session.id) ~= profileId then
        continue
      end
      if session.id == current then
        afterCurrent = true
      elseif session.tabs > 0 then
        if afterCurrent then
          return session.id
        end
        previous = session.id
        previousOnHost = session.id
      end
    end
    if afterCurrent and previousOnHost then
      return previousOnHost
    end
  end
  return previous
end

local function closeEmptySpaces(cx: WindowCx)
  local known = {}
  for _, session in cx.sessions:list() do
    known[session.id] = true
  end
  tern.timer(0, function(fresh: WindowCx)
    profiles.refresh(fresh)
    local sessions = fresh.sessions:list()
    local current = fresh.sessions:current()
    local currentProfile = profiles.profileId(current.id)
    local target = if current.tabs == 0 then adjacentSpace(fresh, sessions, current.id, currentProfile) else nil
    if target then
      fresh.sessions:switch(target)
    end
    local profileCounts = {}
    local hostCounts = {}
    for _, session in sessions do
      local profileId = profiles.profileId(session.id)
      profileCounts[profileId] = (profileCounts[profileId] or 0) + 1
      hostCounts[session.host] = (hostCounts[session.host] or 0) + 1
    end
    for _, session in sessions do
      local profileId = profiles.profileId(session.id)
      if
        known[session.id]
        and session.tabs == 0
        and (session.id ~= current.id or target ~= nil)
        and profileCounts[profileId] > 1
        and hostCounts[session.host] > 1
      then
        fresh.sessions:close(session.id)
        profileCounts[profileId] -= 1
        hostCounts[session.host] -= 1
      end
    end
    sync(fresh)
  end)
end

tern.on("tab_closed", function(_, cx: WindowCx)
  closeEmptySpaces(cx)
end)

tern.on("focus", function(ev: FocusEvent, cx: WindowCx)
  stateModel.focus(ev)
  observeWidth(cx)
  activePanel = panelByTab[ev.tab]
  local restore = focusAfterOpen[ev.pane]
  if restore and cx.session:focused() == ev.pane then
    focusAfterOpen[ev.pane] = nil
    if cx.session:tab_of(restore) == ev.tab then
      cx.layout:focus(restore)
    end
  elseif activePanel and ev.pane ~= activePanel then
    focusAfterOpen[activePanel] = nil
  end
  sync(cx)
end)

for _, event in { "tab_created", "tab_closed", "pane_created", "session_ended" } do
  tern.on(event, function(_, cx: WindowCx)
    sync(cx)
  end)
end
tern.on("pane_closed", function(ev: PaneEvent, cx: WindowCx)
  for tab, pane in pending do
    if pane == ev.pane then
      pending[tab] = nil
    end
  end
  sync(cx)
end)
for _, event in { "agent_state", "agent_finished", "command_started", "command_finished" } do
  tern.on(event, function(_, cx: WindowCx)
    sync(cx)
  end)
end

-- Session renames and changes from other windows have no dedicated window event.
local function refresh(cx: WindowCx)
  -- Queue recovery before native calls can exhaust the callback budget.
  tern.timer(REFRESH_MS, refresh)
  -- Callbacks are serial; a guard still set here belongs to an interrupted sync.
  syncing = false
  sync(cx)
end
tern.timer(0, function(cx: WindowCx)
  profiles.start(cx, sync)
  -- Native tabs and the space picker share the same sessions, without an import copy.
  if not profiles.hidden() and cx.settings:get("tabs") ~= "Horizontal" then
    cx.settings:set("tabs", "Horizontal")
  end
  closeEmptySpaces(cx)
  refresh(cx)
end)
