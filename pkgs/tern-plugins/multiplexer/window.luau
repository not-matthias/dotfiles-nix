--!strict

local profiles = require("./profiles")
local GROUP = "Multiplexer"
local STATE_KEY = "shortcuts"
local LABELS_KEY = "agent_labels"
local PREFIX_BYTE = "\002"

local currentPane: number? = nil
local previousPane: number? = nil

local function sameBinding(left, right): boolean
  if type(left) ~= "table" or type(right) ~= "table" then
    return left == right
  end
  if #left ~= #right then
    return false
  end
  for index, action in left do
    if action ~= right[index] then
      return false
    end
  end
  return true
end

local function restoredBindings(cx: WindowCx)
  local bindings = cx.settings:keybinds()
  local state = tern.kv.get(STATE_KEY)
  if not state then
    return bindings
  end
  for chord, installed in state.installed do
    -- A later manual edit belongs to the user, not to this profile.
    if sameBinding(bindings[chord], installed) then
      bindings[chord] = state.before[chord] or nil
    end
  end
  return bindings
end

local function applyStyle(cx: WindowCx, style: string)
  local bindings = restoredBindings(cx)
  local installed = table.clone(profiles.styles[style])
  for chord, action in profiles.personal do
    installed[chord] = action
  end
  local before = {}
  for chord, action in installed do
    before[chord] = bindings[chord] or false
    bindings[chord] = action
  end
  cx.settings:set("keybinds", bindings)
  tern.kv.set(STATE_KEY, { style = style, before = before, installed = installed })
  cx:toast("info", "Multiplexer shortcuts: " .. style)
end

local function agents(cx: WindowCx): { PaneInfo }
  local native = {}
  for _, agent in cx.agents:list() do
    native[agent.pane] = true
  end
  local panes = cx.session:panes()
  local result = {}
  for _, session in cx.session:sessions() do
    if not session.current then
      continue
    end
    for _, tab in session.tabs do
      local tabAgents = {}
      for _, pane in panes do
        if pane.tab ~= tab or pane.parked then
          continue
        end
        local program = string.match(pane.program or "", "([^/]+)$")
        if native[pane.pane] or program == "omp" or program == "pi" or program == "claude" or program == "codex" then
          table.insert(tabAgents, pane)
        end
      end
      table.sort(tabAgents, function(left, right)
        return left.pane < right.pane
      end)
      for _, pane in tabAgents do
        table.insert(result, pane)
      end
    end
  end
  return result
end

local function focusAgent(cx: WindowCx, index: number)
  local pane = agents(cx)[index]
  if not pane then
    cx:toast("warn", "No agent at position " .. index)
    return
  end
  cx.layout:focus(pane.pane)
end

local function cycleAgent(cx: WindowCx, step: number)
  local list = agents(cx)
  if #list == 0 then
    cx:toast("warn", "No agents in this session")
    return
  end
  local focused = cx.session:focused()
  for index, pane in list do
    if pane.pane == focused then
      cx.layout:focus(list[(index - 1 + step) % #list + 1].pane)
      return
    end
  end
  cx.layout:focus(list[if step > 0 then 1 else #list].pane)
end

local function label(pane: PaneInfo): string
  local labels = tern.kv.get(LABELS_KEY) or {}
  return labels[tostring(pane.pane)] or pane.title
end

tern.on("focus", function(ev: FocusEvent, _cx: WindowCx)
  if ev.pane ~= currentPane then
    previousPane = currentPane
    currentPane = ev.pane
  end
end)

tern.on("pane_closed", function(ev, _cx: WindowCx)
  local labels = tern.kv.get(LABELS_KEY) or {}
  labels[tostring(ev.pane)] = nil
  tern.kv.set(LABELS_KEY, labels)
end)

tern.command({
  id = "last_pane",
  title = "Focus last pane",
  group = GROUP,
  run = function(cx: WindowCx)
    if previousPane and cx.session:pane(previousPane) then
      cx.layout:focus(previousPane)
    end
  end,
})

tern.command({
  id = "next_agent",
  title = "Focus next agent",
  group = GROUP,
  run = function(cx: WindowCx)
    cycleAgent(cx, 1)
  end,
})

tern.command({
  id = "previous_agent",
  title = "Focus previous agent",
  group = GROUP,
  run = function(cx: WindowCx)
    cycleAgent(cx, -1)
  end,
})

for index = 1, 9 do
  tern.command({
    id = "agent_" .. index,
    title = "Focus agent " .. index,
    group = GROUP,
    run = function(cx: WindowCx)
      focusAgent(cx, index)
    end,
  })
end

tern.command({
  id = "choose_agent",
  title = "Choose agent…",
  group = GROUP,
  run = function(cx: WindowCx)
    local items = {}
    for index, pane in agents(cx) do
      table.insert(items, { label = index .. ": " .. label(pane), sub = pane.cwd, pane = pane.pane })
    end
    if #items == 0 then
      cx:toast("warn", "No agents in this session")
      return
    end
    cx:pick({ placeholder = "Choose agent", items = items }):next(function(item, err, fresh)
      if err then
        fresh:toast("error", err)
      elseif item and fresh.session:pane(item.pane) then
        fresh.layout:focus(item.pane)
      end
    end)
  end,
})

tern.command({
  id = "label_agent",
  title = "Rename focused agent label…",
  group = GROUP,
  run = function(cx: WindowCx)
    local focused = cx.session:focused()
    local target = nil
    for _, pane in agents(cx) do
      if pane.pane == focused then
        target = pane
        break
      end
    end
    if not target then
      cx:toast("warn", "Focus an agent to rename its label")
      return
    end
    cx:prompt({ value = label(target), placeholder = "Agent name" }):next(function(name, err, fresh)
      if err then
        fresh:toast("error", err)
        return
      end
      if name == nil or not fresh.session:pane(target.pane) then
        return
      end
      local labels = tern.kv.get(LABELS_KEY) or {}
      local trimmed = string.match(name, "^%s*(.-)%s*$")
      labels[tostring(target.pane)] = if trimmed ~= "" then trimmed else nil
      tern.kv.set(LABELS_KEY, labels)
      tern.chrome.refresh()
    end)
  end,
})

tern.chrome.status(function(pane: StatusPaneInfo)
  local labels = tern.kv.get(LABELS_KEY) or {}
  local name = labels[tostring(pane.pane)]
  return if name then { { text = name, icon = "terminal" } } else nil
end)

tern.command({
  id = "send_prefix",
  title = "Send Ctrl+B to program",
  group = GROUP,
  run = function(cx: WindowCx)
    local pane = cx.session:focused()
    if pane then
      cx:run(pane, PREFIX_BYTE)
    end
  end,
})

for _, style in { "herdr", "tmux", "zellij" } do
  tern.command({
    id = "use_" .. style,
    title = "Use " .. style .. " shortcuts",
    group = GROUP,
    run = function(cx: WindowCx)
      applyStyle(cx, style)
    end,
  })
end

tern.command({
  id = "restore",
  title = "Restore shortcuts from before Multiplexer",
  group = GROUP,
  run = function(cx: WindowCx)
    cx.settings:set("keybinds", restoredBindings(cx))
    tern.kv.set(STATE_KEY, { style = "off", before = {}, installed = {} })
    cx:toast("info", "Previous shortcuts restored")
  end,
})

-- Entry load also runs after plugin reload, unlike window_start.
tern.timer(0, function(cx: WindowCx)
  currentPane = cx.session:focused()
  if not tern.kv.get(STATE_KEY) then
    applyStyle(cx, profiles.default)
  end
end)
