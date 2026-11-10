--!strict

-- Mobile keeps Tern's native session UI; the sidebar does not fit there.
local MOBILE_OS = { ios = true, android = true }
if MOBILE_OS[tern.runtime.os] then
  return
end

local stateModel = require("./state")
local view = require("./view")
local profiles = require("./profiles")
local panels = require("./panels")

local COLLAPSED_PREFIX = "collapsed:"
local CUSTOM_NAME_PREFIX = "custom-name:"
-- The name Tern gives the session it starts with.
local TERN_FIRST_SESSION_NAME = "Default"
local REFRESH_MS = 1000
local GROUP = "Spaces"

-- KV is shared by every window and re-read when it changes on disk.
local function isCollapsed(host: string): boolean
  return tern.kv.get(COLLAPSED_PREFIX .. host) == true
end

local function snapshot(cx: WindowCx)
  local state = {
    panes = cx.session:panes(),
    tabs = cx.session:tabs(),
    sessions = cx.sessions:list(),
    hosts = cx.hosts:list(),
    activeTab = nil :: number?,
  }
  local focused = cx.session:focused()
  for _, pane in state.panes do
    if pane.pane == focused then
      state.activeTab = pane.tab
    end
  end
  return state
end

local function directoryName(path: string): string
  return string.match(path, "([^/]+)/?$") or path
end

-- Session names are shared with every attached window, but the record of names typed by hand
-- (CUSTOM_NAME_PREFIX) stays on the machine that typed them. A name therefore follows `cd` only
-- while it is the one Tern starts with, this window has seen it be a directory's name, or this
-- window saw the space appear without a directory yet.
local followedNames: { [number]: string } = {}
local seenSessions: { [number]: boolean } = {}
local connectedHosts: { [number]: boolean } = {}
local watching = false

local function trackNames(state)
  local sessionByTab = {}
  for _, tab in state.tabs do
    sessionByTab[tab.id] = tab.session
  end
  local directories: { [number]: { [string]: boolean } } = {}
  for _, pane in state.panes do
    local session = if pane.tab then sessionByTab[pane.tab] else nil
    if session and pane.cwd and pane.cwd ~= "" then
      directories[session] = directories[session] or {}
      directories[session][directoryName(pane.cwd)] = true
    end
  end
  local live = {}
  for _, session in state.sessions do
    live[session.id] = true
    local names = directories[session.id]
    -- A machine that just attached lists spaces before their panes: those are not new.
    local created = watching and not seenSessions[session.id] and connectedHosts[session.host] and not names
    if created or session.name == TERN_FIRST_SESSION_NAME or (names and names[session.name]) then
      followedNames[session.id] = session.name
    end
    seenSessions[session.id] = true
  end
  for id in seenSessions do
    if not live[id] then
      seenSessions[id] = nil
      followedNames[id] = nil
    end
  end
  connectedHosts = {}
  for _, host in state.hosts do
    connectedHosts[host.id] = host.state == "connected"
  end
  watching = true
end

local syncing = false
local shownSession: number? = nil

local function sync(cx: WindowCx)
  if syncing then
    return
  end
  syncing = true
  local state = snapshot(cx)
  -- Which space a window shows is its own; pane focus is shared by every window on a session.
  for _, session in state.sessions do
    if session.current and session.id ~= shownSession then
      shownSession = session.id
      panels.touch()
    end
  end
  trackNames(state)
  profiles.refresh(cx, state)
  if profiles.hidden() then
    panels.hide(cx)
    syncing = false
    return
  end
  local groups = stateModel.sidebarModel(cx, state, isCollapsed)
  -- Tabs of one profile share a model; only the highlighted space differs.
  local byProfile = {}
  panels.sync(cx, state, function(session: number)
    local profileId = profiles.profileId(session)
    local content = byProfile[profileId]
    if not content then
      local model = profiles.filter(groups, session, state.sessions)
      local profileModel = profiles.model(session)
      content = {
        model = model,
        profiles = profileModel,
        signature = tern.json.encode({ spaces = model, profiles = profileModel }),
      }
      byProfile[profileId] = content
    end
    return {
      signature = content.signature,
      render = function()
        return view.render(content.model, session, content.profiles)
      end,
    }
  end)
  syncing = false
end

-- Acting in this window makes it the one whose sidebar the user is looking at.
local function used(cx: WindowCx)
  panels.touch()
  sync(cx)
end

local function findSession(cx: WindowCx, id: number): ManagedSession?
  for _, session in cx.sessions:list() do
    if session.id == id then
      return session
    end
  end
  return nil
end

local function currentDirectory(cx: WindowCx): string?
  local focused = cx.session:focused()
  local tab = if focused then cx.session:tab_of(focused) else nil
  local pane = if tab then stateModel.directoryPanes(cx.session:panes(), cx.session:tabs())[tab] else nil
  return if pane then pane.cwd else nil
end

local function newSpace(cx: WindowCx)
  local cwd = currentDirectory(cx)
  local name = if cwd then directoryName(cwd) else nil
  profiles.addSpace(cx, { name = name, cwd = cwd })
  used(cx)
end

local function newTab(cx: WindowCx)
  cx.layout:new_tab({ cwd = currentDirectory(cx) })
  used(cx)
end

tern.override("new_tab", function(cx: WindowCx)
  local focused = cx.session:focused()
  if not focused or panels.status(cx, focused) == "none" then
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
  local session = findSession(cx, id)
  if not session then
    return
  end
  cx:prompt({ value = session.name, placeholder = "Space name" }):next(function(name, err, fresh)
    if err then
      fresh:toast("error", err)
      return
    end
    local trimmed = if name then string.match(name, "^%s*(.-)%s*$") else ""
    if trimmed == "" or not findSession(fresh, id) then
      return
    end
    fresh.sessions:rename(id, trimmed)
    tern.kv.set(CUSTOM_NAME_PREFIX .. id, trimmed)
    sync(fresh)
  end)
end

tern.on("canvas_action", function(ev: CanvasAction, cx: WindowCx)
  local status = panels.status(cx, ev.pane, ev.about)
  if status == "none" then
    return false
  end
  panels.touch()
  if status == "foreign" then
    -- Another window drew this view with its own ids: redraw it instead of acting on them.
    sync(cx)
    return true
  end
  local tab = cx.session:tab_of(ev.pane)
  local pane = if tab then stateModel.directoryPanes(cx.session:panes(), cx.session:tabs())[tab] else nil
  if pane then
    cx.layout:focus(pane.pane)
  end
  local row = tonumber(string.match(ev.node, "%.space:(%d+)$"))
  if row and findSession(cx, row) and ev.act == "Move to profile" then
    profiles.move(cx, row)
    return true
  end
  if profiles.action(ev, cx) then
    return true
  end
  if row and ev.act == "Rename" then
    renameSpace(cx, row)
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
  -- A queued redraw may still show a space that closed.
  if session and findSession(cx, session) then
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
    used(cx)
  end,
})
tern.command({
  id = "toggle_sidebar",
  title = "Show/hide spaces sidebar",
  group = GROUP,
  run = function(cx)
    profiles.setVisibility(if profiles.hidden() then "visible" else "hidden")
    used(cx)
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
      local session = findSession(cx, tab.session)
      if not session or session.name == tern.kv.get(CUSTOM_NAME_PREFIX .. tab.session) then
        return
      end
      local name = directoryName(ev.path)
      if session.name ~= name and session.name ~= followedNames[tab.session] then
        return
      end
      followedNames[tab.session] = name
      if session.name == name then
        return
      end
      cx.sessions:rename(tab.session, name)
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
  sync(cx)
end)

tern.on("focus", function(ev: FocusEvent, cx: WindowCx)
  stateModel.focus(ev)
  panels.focus(ev, cx)
  sync(cx)
end)

tern.on("pane_closed", function(ev: PaneEvent, cx: WindowCx)
  panels.closed(ev.pane)
  sync(cx)
end)

for _, event in
  {
    "tab_created",
    "pane_created",
    "session_ended",
    "agent_state",
    "agent_finished",
    "command_started",
    "command_finished",
  }
do
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
  -- The sidebar must appear even if the rest of startup runs out of budget.
  tern.timer(0, refresh)
  profiles.start(cx, sync)
  -- Native tabs and the space picker share the same sessions, without an import copy.
  if not profiles.hidden() and cx.settings:get("tabs") ~= "Horizontal" then
    cx.settings:set("tabs", "Horizontal")
  end
  closeEmptySpaces(cx)
end)
