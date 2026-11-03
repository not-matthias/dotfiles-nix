--!strict

local stateModel = require("./state")
local view = require("./view")

local PANEL_SHARE = 0.15
-- Only drags are persisted, so changing PANEL_SHARE reaches users who never resized.
local WIDTH_KEY = "sidebar-width"
local WIDTH_TOLERANCE = 0.0001
local MAX_SPLIT_SHARE = 0.99
local REFRESH_MS = 1000
local GROUP = "Spaces"
local CUSTOM_NAME_PREFIX = "custom-name:"
local rendered = {}
local pending = {}
local collapsed = {}
local syncing = false
local sharedWidth: number = tern.kv.get(WIDTH_KEY) or PANEL_SHARE
local widths = {}
local activePanel = nil
local panelByTab = {}
local focusAfterOpen = {}
local deferredLayouts = {}
local updates = {}
local updateScheduled = false

local function panels(cx: WindowCx)
  local result = {}
  for _, panel in cx.canvas:list() do
    if panel.owner == tern.plugin.id then
      result[panel.pane] = true
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
  local dragged = previous.divider ~= nil
    and divider ~= nil
    and math.abs(divider - previous.divider) > WIDTH_TOLERANCE
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
  -- Canvas creation uses the selected host, even with a target on another host.
  if not update.pane and cx.hosts:current().id ~= update.host then
    deferredLayouts[tab] = true
  elseif cx.session:tab_of(update.target) == tab then
    local root = view(update.model, update.session)
    local pane = update.pane
    if pane then
      cx.canvas:set(pane, { view = root })
    elseif not pending[tab] then
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
  observeWidth(cx)
  local owned = panels(cx)
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
  local model = stateModel.sidebarModel(cx, state, collapsed)
  local signature = tern.json.encode(model)
  local nextUpdates = {}
  local live = table.clone(owned)
  local currentHost = cx.hosts:current().id
  local hostBySession = {}
  for _, session in state.sessions do
    hostBySession[session.id] = session.host
  end
  deferredLayouts = {}
  for _, tab in state.tabs do
    local target = contents[tab.id]
    if not target then
      pending[tab.id] = nil
      continue
    end
    local existing = byTab[tab.id]
    local host = hostBySession[tab.session]
    local canCreate = host == currentHost
    if not existing and not canCreate then
      deferredLayouts[tab.id] = true
      continue
    end
    if pending[tab.id] then
      live[pending[tab.id]] = true
      continue
    end
    if existing then
      local actual, divider = panelGeometry(cx, existing)
      local previous = widths[existing]
      if actual then
        local relaid = previous
          and previous.actual
          and math.abs(actual - previous.actual) > WIDTH_TOLERANCE
        if not previous or relaid or math.abs(previous.requested - sharedWidth) > WIDTH_TOLERANCE then
          if math.abs(actual - sharedWidth) > WIDTH_TOLERANCE then
            if canCreate then
              -- Exact ratios require reopening. Wait for pane_closed before replacing
              -- the panel so remote layouts have removed its old split.
              cx.layout:close(existing)
              widths[existing] = nil
              rendered[existing] = nil
              byTab[tab.id] = nil
              continue
            end
            deferredLayouts[tab.id] = true
          else
            widths[existing] = { requested = sharedWidth, actual = actual, divider = divider }
          end
        elseif not previous.actual then
          -- Minimum pane sizes may clamp the opening ratio; this is not a drag.
          previous.actual = actual
          previous.divider = divider
        end
      end
      local cached = rendered[existing]
      if cached and cached.signature == signature and cached.session == tab.session then
        continue
      end
    end
    nextUpdates[tab.id] = {
      pane = existing,
      target = target,
      focus = if not owned[tab.pane] then tab.pane else nil,
      session = tab.session,
      host = host,
      model = model,
      signature = signature,
    }
  end
  for pane in widths do
    if not live[pane] then
      rendered[pane] = nil
      widths[pane] = nil
      focusAfterOpen[pane] = nil
    end
  end
  for tab in pending do
    if not contents[tab] then
      pending[tab] = nil
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
  cx.sessions:create({ name = name, cwd = cwd })
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
  local rename = if ev.act == "Rename" then tonumber(string.match(ev.node, "%.space:(%d+)$")) else nil
  if rename then
    renameSpace(cx, rename)
    return true
  end
  local host = tonumber(string.match(ev.act, "^host:(%d+)$"))
  if host then
    collapsed[host] = not collapsed[host]
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
tern.command({ id = "refresh", title = "Show spaces panel", group = GROUP, run = sync })

for index = 1, 9 do
  tern.command({
    id = "space_" .. index,
    title = "Go to space " .. index,
    group = GROUP,
    run = function(cx: WindowCx)
      local sessions = cx.sessions:list()
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

local function closeEmptySpaces(cx: WindowCx)
  local known = {}
  for _, session in cx.sessions:list() do
    known[session.id] = true
  end
  tern.timer(0, function(fresh: WindowCx)
    local sessions = fresh.sessions:list()
    if fresh.sessions:current().tabs == 0 then
      for _, session in sessions do
        if session.tabs > 0 then
          fresh.sessions:switch(session.id)
          break
        end
      end
    end
    local remaining = #sessions
    for _, session in sessions do
      if remaining > 1 and known[session.id] and session.tabs == 0 then
        fresh.sessions:close(session.id)
        remaining -= 1
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
  local resized = observeWidth(cx)
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
  if resized or deferredLayouts[ev.tab] then
    sync(cx)
  end
end)

for _, event in { "tab_created", "tab_closed", "pane_created", "pane_closed", "session_ended" } do
  tern.on(event, function(_, cx: WindowCx)
    sync(cx)
  end)
end
for _, event in { "agent_state", "agent_finished", "command_started", "command_finished" } do
  tern.on(event, function(_, cx: WindowCx)
    sync(cx)
  end)
end

-- Session renames and changes from other windows have no dedicated window event.
local function refresh(cx: WindowCx)
  sync(cx)
  tern.timer(REFRESH_MS, refresh)
end
tern.timer(0, function(cx: WindowCx)
  -- Native tabs and the space picker share the same sessions, without an import copy.
  if cx.settings:get("tabs") ~= "Horizontal" then
    cx.settings:set("tabs", "Horizontal")
  end
  closeEmptySpaces(cx)
  refresh(cx)
end)
