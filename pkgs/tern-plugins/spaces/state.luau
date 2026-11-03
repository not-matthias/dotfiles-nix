--!strict

local BRANCH_REFRESH_MS = 5000
local branches = {}
local lastDirectoryPane = {}
local directoryPaneIds = {}

local function directoryPanes(panes, tabs)
  local byId = {}
  local byTab = {}
  for _, pane in panes do
    if pane.kind ~= "terminal" and pane.kind ~= "agent" then
      continue
    end
    if pane.tab and not pane.parked and pane.cwd and pane.cwd ~= "" then
      byId[pane.pane] = pane
      if not byTab[pane.tab] or lastDirectoryPane[pane.tab] == pane.pane then
        byTab[pane.tab] = pane
      end
    end
  end
  -- Keep the last terminal directory while native blocks have focus.
  for _, tab in tabs do
    if byId[tab.pane] then
      byTab[tab.id] = byId[tab.pane]
    end
  end
  for tab, pane in byTab do
    lastDirectoryPane[tab] = pane.pane
  end
  for tab in lastDirectoryPane do
    if not byTab[tab] then
      lastDirectoryPane[tab] = nil
    end
  end
  directoryPaneIds = byId
  return byTab
end

local function updateBranches(cx: WindowCx, state)
  local activeTab = state.activeTab
  local directories = directoryPanes(state.panes, state.tabs)
  local chosen = {}
  for _, tab in state.tabs do
    local previous = branches[tab.session]
    local pane = directories[tab.id]
    if
      pane
      and (
        not chosen[tab.session]
        or tab.id == activeTab
        or (chosen[tab.session].tab ~= activeTab and previous and previous.tab == tab.id)
      )
    then
      chosen[tab.session] = pane
    end
  end
  local localHosts = {}
  for _, host in state.hosts do
    localHosts[host.id] = host.kind == "local"
  end
  local live = {}
  for _, session in state.sessions do
    live[session.id] = true
    local pane = chosen[session.id]
    if not localHosts[session.host] or not pane then
      branches[session.id] = nil
      continue
    end
    local entry = branches[session.id]
    if not entry or entry.cwd ~= pane.cwd then
      entry = { cwd = pane.cwd, tab = pane.tab, checked = -BRANCH_REFRESH_MS }
      branches[session.id] = entry
    end
    entry.tab = pane.tab
    if entry.pending or tern.now() - entry.checked < BRANCH_REFRESH_MS then
      continue
    end
    entry.pending = true
    entry.checked = tern.now()
    cx.git:repo(pane.cwd):next(function(repo, err)
      entry.pending = false
      entry.name = if not err and repo then repo.branch else nil
    end)
  end
  for id in branches do
    if not live[id] then
      branches[id] = nil
    end
  end
end

local function agentStates(cx: WindowCx, state): { [number]: string }
  local sessionByTab = {}
  for _, tab in state.tabs do
    sessionByTab[tab.id] = tab.session
  end

  local priority = { present = 1, idle = 2, waiting_input = 3, working = 4 }
  local states = {}
  local native = {}
  for _, agent in cx.agents:list() do
    native[agent.pane] = true
    -- Runtime agent rows include their session even when parked without a tab.
    local session = agent.session
    local state = agent.state
    if state ~= "exited" and (not states[session] or priority[state] > priority[states[session]]) then
      states[session] = state
    end
  end

  for _, pane in state.panes do
    if native[pane.pane] or not pane.tab then
      continue
    end
    local session = sessionByTab[pane.tab]
    if not session then
      continue
    end

    local program = string.match(pane.program or "", "([^/]+)$")
    if program == "omp" or program == "pi" or program == "claude" or program == "codex" then
      local state = if pane.busy then "working" else "present"
      if not states[session] or priority[state] > priority[states[session]] then
        states[session] = state
      end
    end
  end
  return states
end

local function sidebarModel(cx: WindowCx, state, isCollapsed: (string) -> boolean)
  updateBranches(cx, state)
  local agents = agentStates(cx, state)
  local groups = {}
  local byHost = {}
  for _, host in state.hosts do
    local group = { id = host.id, name = host.name, collapsed = isCollapsed(host.name), sessions = {} }
    table.insert(groups, group)
    byHost[host.id] = group
  end
  for _, session in state.sessions do
    local group = byHost[session.host]
    if not group or group.collapsed then
      continue
    end
    local branch = branches[session.id]
    table.insert(group.sessions, {
      id = session.id,
      name = session.name,
      agent = agents[session.id],
      branch = if branch then branch.name else nil,
    })
  end
  return groups
end

local function focus(ev: FocusEvent)
  if directoryPaneIds[ev.pane] then
    lastDirectoryPane[ev.tab] = ev.pane
  end
end

return {
  directoryPanes = directoryPanes,
  sidebarModel = sidebarModel,
  focus = focus,
}
