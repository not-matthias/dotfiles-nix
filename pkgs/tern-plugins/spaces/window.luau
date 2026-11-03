--!strict

local PANEL_SHARE = 0.15
local WIDTH_KEY = "sidebar-width"
local WIDTH_TOLERANCE = 0.0001
local MAX_SPLIT_SHARE = 0.99
local REFRESH_MS = 1000
local BRANCH_REFRESH_MS = 5000
local GROUP = "Spaces"
local CUSTOM_NAME_PREFIX = "custom-name:"
local rendered = {}
local pending = {}
local collapsed = {}
local branches = {}
local lastDirectoryPane = {}
local syncing = false
local sharedWidth = tern.kv.get(WIDTH_KEY)
local widths = {}
local activePanel = nil

tern.css(
  "sidebar",
  [[
  .spaces-sidebar {
    display: flex;
    flex-direction: column;
    gap: 4px;
    padding: 6px;
    font-size: 13px;
    min-width: 0;
    overflow: hidden;
  }
  .spaces-sidebar .sf-button {
    width: 100%;
    justify-content: flex-start;
    border-radius: 4px;
    min-height: 24px;
    padding: 2px 6px;
  }
  .spaces-sidebar > .sf-button {
    width: auto;
    margin-left: -4px;
    padding-left: 0;
  }
  .spaces-sidebar .space-row {
    display: flex;
    flex-direction: column;
    min-width: 0;
  }
  .spaces-sidebar .space-name {
    margin: 0;
    display: flex;
    align-items: center;
    min-width: 0;
  }
  .spaces-sidebar .space-name > .sf-table {
    flex: 1;
    min-width: 0;
  }
  .spaces-sidebar .space-name .sf-tbl {
    margin: 0;
    width: 100%;
    min-width: 0;
  }
  .spaces-sidebar .space-name .head,
  .spaces-sidebar .space-name .sf-tbl-probe {
    display: none;
  }
  .spaces-sidebar .space-name .sf-tbl-row:not(.head) {
    display: flex;
  }
  .spaces-sidebar .space-name .sf-tbl-c {
    padding: 0;
    flex: 1;
    min-width: 0;
  }
  .spaces-sidebar .space-name button {
    width: 100%;
    min-height: 22px;
    justify-content: flex-start;
    padding: 2px 6px;
    border-radius: 4px;
  }
  .spaces-sidebar .sf-btn-label,
  .spaces-sidebar .space-branch .sf-text {
    min-width: 0;
    overflow: hidden;
    white-space: nowrap;
    text-overflow: ellipsis;
  }
  .spaces-sidebar .space-agent {
    flex: 0 0 auto;
    padding: 0 4px;
    font-size: 11px;
  }
  .spaces-sidebar .space-branch {
    padding: 0 6px 2px;
    font-size: 11px;
    overflow: hidden;
    white-space: nowrap;
    text-overflow: ellipsis;
  }
]]
)

local function panels(cx: WindowCx)
  local result = {}
  for _, panel in cx.canvas:list() do
    if panel.owner == tern.plugin.id then
      result[panel.pane] = true
    end
  end
  return result
end

local function directoryPanes(cx: WindowCx)
  local byId = {}
  local byTab = {}
  for _, pane in cx.session:panes() do
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
  for _, tab in cx.session:tabs() do
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
  return byTab
end

local function button(label: string, action: string): Node
  return tern.ui.button(label, {
    key = action,
    actions = { click = action },
    variant = "quiet",
  })
end

local function updateBranches(cx: WindowCx)
  local focused = cx.session:focused()
  local activeTab = if focused then cx.session:tab_of(focused) else nil
  local directories = directoryPanes(cx)
  local chosen = {}
  for _, tab in cx.session:tabs() do
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
  for _, host in cx.hosts:list() do
    localHosts[host.id] = host.kind == "local"
  end
  local live = {}
  for _, session in cx.sessions:list() do
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

local function agentStates(cx: WindowCx): { [number]: string }
  local sessionByTab = {}
  for _, tab in cx.session:tabs() do
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

  for _, pane in cx.session:panes() do
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

local function view(cx: WindowCx): Node
  updateBranches(cx)
  local agents = agentStates(cx)
  local rows = { tern.ui.text({ tern.ui.span("SPACES", "muted") }) }
  local sessions = cx.sessions:list()
  for _, host in cx.hosts:list() do
    local marker = if collapsed[host.id] then "▸ " else "▾ "
    table.insert(rows, button(marker .. host.name, "host:" .. host.id))
    if collapsed[host.id] then
      continue
    end
    for _, session in sessions do
      if session.host == host.id then
        local action = "space:" .. session.id
        -- TSP exposes context menus on table rows, not standalone buttons.
        local title = tern.ui.table({ { id = "name", head = "", grow = 1 } }, {
          {
            id = tostring(session.id),
            cells = {
              {
                button = {
                  text = session.name,
                  act = action,
                  variant = if session.current then "primary" else "quiet",
                },
              },
            },
            menu = { "Rename" },
          },
        })
        title.p.key = action
        local nameParts = { title }
        local agentState = agents[session.id]
        if agentState then
          local labels = {
            working = "Agent working",
            waiting_input = "Agent awaiting input",
            idle = "Idle agent",
            present = "Agent present",
          }
          local label = labels[agentState]
          local stateClass = string.gsub(agentState, "_", "-")
          local tones = {
            working = "success",
            waiting_input = "warning",
            idle = "muted",
            present = "muted",
          }
          table.insert(
            nameParts,
            tern.ui.el("span", {
              class = "space-agent space-agent-" .. stateClass,
              title = label,
              attrs = {
                ["aria-label"] = label,
                ["data-session"] = tostring(session.id),
                ["data-state"] = agentState,
              },
            }, { tern.ui.text({ tern.ui.span("●", tones[agentState]) }) })
          )
        end
        local contents = { tern.ui.el("div", { class = "space-name" }, nameParts) }
        local branch = branches[session.id]
        if branch and branch.name then
          table.insert(
            contents,
            tern.ui.el("div", {
              class = "space-branch",
              actions = { click = action },
            }, { tern.ui.text({ tern.ui.span(branch.name, "muted") }) })
          )
        end
        table.insert(rows, tern.ui.el("div", { class = "space-row" }, contents))
      end
    end
  end
  return tern.ui.el("div", { class = "spaces-sidebar" }, rows)
end

local function paneShare(node: TabTree, pane: number, share: number): number?
  if node.pane then
    return if node.pane == pane then share else nil
  end
  local horizontal = node.split == "right"
  return paneShare(node[1], pane, if horizontal then share * node.ratio else share)
    or paneShare(node[2], pane, if horizontal then share * (1 - node.ratio) else share)
end

local function panelWidth(cx: WindowCx, pane: number): number?
  local tab = cx.session:tab_of(pane)
  local layout = if tab then cx.session:layout(tab) else nil
  return if layout then paneShare(layout.root, pane, 1) else nil
end

local function rememberWidth(width: number)
  sharedWidth = width
  tern.kv.set(WIDTH_KEY, width)
end

local function observeWidth(cx: WindowCx)
  local previous = if activePanel then widths[activePanel] else nil
  local actual = if previous then panelWidth(cx, activePanel) else nil
  if not actual then
    return
  end
  if previous.actual and math.abs(actual - previous.actual) > WIDTH_TOLERANCE then
    rememberWidth(actual)
    previous.requested = actual
  end
  previous.actual = actual
end

local function sync(cx: WindowCx)
  if syncing then
    return
  end
  syncing = true
  -- Read the departing panel too: a drag followed immediately by a space switch
  -- must propagate without waiting for the refresh timer.
  observeWidth(cx)
  local owned = panels(cx)
  local contents = {}
  for _, pane in cx.session:panes() do
    if not owned[pane.pane] and not pane.parked then
      contents[pane.tab] = contents[pane.tab] or pane.pane
    end
  end
  local byTab = {}
  for pane in owned do
    local tab = cx.session:tab_of(pane)
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
  local focused = cx.session:focused()
  local tab = if focused then cx.session:tab_of(focused) else nil
  local existing = if tab then byTab[tab] else nil
  local actual = if existing then panelWidth(cx, existing) else nil
  if not sharedWidth then
    rememberWidth(actual or PANEL_SHARE)
  end
  activePanel = existing
  if existing and actual then
    local previous = widths[existing]
    if not previous or math.abs(previous.requested - sharedWidth) > WIDTH_TOLERANCE then
      if math.abs(actual - sharedWidth) > WIDTH_TOLERANCE then
        -- The API sets exact ratios only when opening a canvas. Recreate only our
        -- panel; wait for pane_closed so remote layouts have removed its old split.
        cx.layout:close(existing)
        widths[existing] = nil
        rendered[existing] = nil
        activePanel = nil
        syncing = false
        return
      end
      widths[existing] = { requested = sharedWidth, actual = actual }
    elseif not previous.actual then
      -- Native minimum pane sizes can clamp a requested width. This is not a drag.
      previous.actual = actual
    end
  end
  local root = view(cx)
  local encoded = tern.json.encode(root)
  if tab and contents[tab] and not existing and not pending[tab] then
    local targetWidth = panelWidth(cx, contents[tab]) or 1
    local pane, err = cx.canvas:open({
      title = "Spaces",
      view = root,
      target = contents[tab],
      dir = "left",
      ratio = math.min(sharedWidth / targetWidth, MAX_SPLIT_SHARE),
      focus = false,
    })
    if pane then
      pending[tab] = pane
      rendered[pane] = encoded
      widths[pane] = { requested = sharedWidth }
    elseif err then
      cx:toast("error", err)
    end
  end
  if existing and rendered[existing] ~= encoded then
    cx.canvas:set(existing, { view = root })
    rendered[existing] = encoded
  end
  syncing = false
end

local function currentDirectory(cx: WindowCx): string?
  local focused = cx.session:focused()
  local tab = if focused then cx.session:tab_of(focused) else nil
  local pane = if tab then directoryPanes(cx)[tab] else nil
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
  local pane = if tab then directoryPanes(cx)[tab] else nil
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
  sync(cx)
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
              sync(cx)
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

for _, event in { "focus", "tab_created", "tab_closed", "pane_closed", "session_ended" } do
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
