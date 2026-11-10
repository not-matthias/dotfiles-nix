--!strict

local GROUP = "Profiles"
local IDS_KEY = "profile-ids"
local DEFAULT_KEY = "profile-default"
local PROFILE_PREFIX = "profile:"
local SESSION_PREFIX = "session-profile:"
local LAST_SESSION_PREFIX = "profile-last-session:"
local HIDDEN_KEY = "sidebar-hidden"
local PICKER_CHORD = "ctrl+alt+p"
local PICKER_ACTION = "plugin.spaces.open_profile"
local home = tern.getenv("HOME") or ""
local definitions = {}
local defaultId = "default"
local currentId = defaultId
local currentName = nil
local sessionKeys = {}
local membership = {}
local seen = {}
local lastSession = {}
local initialized = false
local changed = nil
local lastError = nil

local function report(cx: WindowCx, err: string)
  cx:toast("error", "Profiles", err)
end

local function definition(id: string)
  for _, profile in definitions do
    if profile.id == id then
      return profile
    end
  end
  return nil
end

-- Import labels and starting directories, never sessions or daemon ownership.
-- Existing isolated environments remain untouched on disk and in memory.
local function initialize(cx: WindowCx): boolean
  if tern.kv.get(IDS_KEY) then
    return true
  end
  local configHome = tern.getenv("XDG_CONFIG_HOME") or (home .. "/.config")
  local root = tern.getenv("TERN_PROFILES_DIR") or (configHome .. "/tern-profiles")
  local config = tern.getenv("TERN_CONFIG_DIR") or (configHome .. "/tern")
  local profiles = { { id = defaultId, name = "Default", cwd = home } }
  if tern.fs.exists(root .. "/profiles.json") then
    local registryLimit = 256 * 1024
    local ok, data = pcall(function()
      return tern.json.decode(tern.fs.read(root .. "/profiles.json", registryLimit))
    end)
    if ok and type(data) == "table" and type(data.profiles) == "table" and #data.profiles > 0 then
      profiles = {}
      for _, profile in data.profiles do
        if
          type(profile) ~= "table"
          or type(profile.id) ~= "string"
          or type(profile.name) ~= "string"
          or type(profile.cwd) ~= "string"
        then
          ok = false
          break
        end
        table.insert(profiles, { id = profile.id, name = profile.name, cwd = profile.cwd })
        if profile.config == config then
          defaultId = profile.id
        end
      end
      local found = false
      for _, profile in profiles do
        found = found or profile.id == defaultId
      end
      if not found and #profiles > 0 then
        defaultId = profiles[1].id
      end
    else
      ok = false
    end
    if not ok then
      local message = "Could not import saved profiles. Fix "
        .. root
        .. "/profiles.json and reload the plugin; existing environments are untouched."
      if message ~= lastError then
        report(cx, message)
        lastError = message
      end
      return false
    end
  end
  local ids = {}
  for _, profile in profiles do
    table.insert(ids, profile.id)
    tern.kv.set(PROFILE_PREFIX .. profile.id, { name = profile.name, cwd = profile.cwd })
  end
  tern.kv.set(DEFAULT_KEY, defaultId)
  tern.kv.set(IDS_KEY, ids)
  return true
end

local function profileId(session: number?): string
  return if session then membership[session] or defaultId else currentId
end

local function remember(cx: WindowCx, id: string, session: number)
  if lastSession[id] == session then
    return
  end
  lastSession[id] = session
  tern.kv.set(LAST_SESSION_PREFIX .. cx:window_key() .. ":" .. id, session)
end

local function refresh(cx: WindowCx, state: { hosts: { ManagedHost }, sessions: { ManagedSession } }?)
  if not initialize(cx) then
    return
  end
  defaultId = tern.kv.get(DEFAULT_KEY) or "default"
  definitions = {}
  for _, id in tern.kv.get(IDS_KEY) do
    local data = tern.kv.get(PROFILE_PREFIX .. id)
    if data then
      table.insert(definitions, { id = id, name = data.name, cwd = data.cwd })
    end
  end
  local hosts = {}
  for _, host in if state then state.hosts else cx.hosts:list() do
    hosts[host.id] = host.name
  end
  local nextSeen = {}
  local nextMembership = {}
  sessionKeys = {}
  for _, session in if state then state.sessions else cx.sessions:list() do
    local hostName = hosts[session.host]
    -- A machine still connecting lists its sessions before itself.
    if not hostName then
      continue
    end
    local key = SESSION_PREFIX .. hostName .. ":" .. session.id
    sessionKeys[session.id] = key
    local id = tern.kv.get(key)
    if not id and initialized and not seen[session.id] and session.current then
      id = currentId
      if id ~= defaultId then
        tern.kv.set(key, id)
      end
    end
    nextMembership[session.id] = if id and definition(id) then id else defaultId
    nextSeen[session.id] = true
    if session.current then
      currentId = nextMembership[session.id]
      remember(cx, currentId, session.id)
    end
  end
  membership = nextMembership
  seen = nextSeen
  initialized = true
  local profile = definition(currentId)
  local name = if profile then profile.name else nil
  if name ~= currentName then
    currentName = name
    tern.chrome.refresh()
  end
end

local function notify(cx: WindowCx)
  if changed then
    changed(cx)
  else
    refresh(cx)
  end
end

local function assign(session: number, id: string)
  tern.kv.set(sessionKeys[session], if id == defaultId then nil else id)
  membership[session] = id
end

local function createSpace(cx: WindowCx, opts, id: string)
  local host = cx.hosts:current()
  local session = cx.sessions:create(opts)
  sessionKeys[session.id] = SESSION_PREFIX .. host.name .. ":" .. session.id
  seen[session.id] = true
  assign(session.id, id)
  currentId = id
  remember(cx, id, session.id)
  return session
end

local function addSpace(cx: WindowCx, opts)
  refresh(cx)
  return createSpace(cx, opts, profileId(cx.sessions:current().id))
end

local function open(cx: WindowCx, id: string)
  refresh(cx)
  local profile = definition(id)
  if not profile then
    return
  end
  local target = nil
  local remembered = lastSession[id] or tern.kv.get(LAST_SESSION_PREFIX .. cx:window_key() .. ":" .. id)
  for _, session in cx.sessions:list() do
    if profileId(session.id) ~= id then
      continue
    end
    if not target or (target.tabs == 0 and session.tabs > 0) or (session.tabs > 0 and session.id == remembered) then
      target = session
    end
  end
  if target then
    cx.sessions:switch(target.id)
    if target.tabs == 0 then
      cx.layout:new_tab({ cwd = profile.cwd })
    end
  else
    createSpace(cx, { name = profile.name, cwd = profile.cwd }, id)
  end
  notify(cx)
end

local function prompt(cx: WindowCx, opts, callback)
  cx:prompt(opts):next(function(value, err, fresh)
    if err then
      report(fresh, err)
    elseif value then
      local trimmed = string.match(value, "^%s*(.-)%s*$")
      if trimmed ~= "" then
        callback(trimmed, fresh)
      end
    end
  end)
end

local function create(cx: WindowCx)
  prompt(cx, { placeholder = "Profile name" }, function(name, fresh)
    prompt(fresh, { placeholder = "Starting directory", value = home }, function(cwd, nextCx)
      refresh(nextCx)
      if #definitions == 0 then
        return
      end
      local base = "group-" .. nextCx:window_key() .. "-" .. string.format("%.0f", tern.now())
      local id = base
      local suffix = 1
      while tern.kv.get(PROFILE_PREFIX .. id) do
        suffix += 1
        id = base .. "-" .. suffix
      end
      local ids = tern.kv.get(IDS_KEY)
      tern.kv.set(PROFILE_PREFIX .. id, { name = name, cwd = cwd })
      table.insert(ids, id)
      tern.kv.set(IDS_KEY, ids)
      open(nextCx, id)
    end)
  end)
end

local function pick(cx: WindowCx, placeholder: string, callback)
  refresh(cx)
  local items = {}
  for _, profile in definitions do
    table.insert(items, { label = profile.name, id = profile.id, current = profile.id == currentId })
  end
  cx:pick({ placeholder = placeholder, items = items }):next(function(choice, err, fresh)
    if err then
      report(fresh, err)
    elseif choice then
      callback(fresh, choice.id)
    end
  end)
end

local function rename(cx: WindowCx, id: string)
  local profile = definition(id)
  if not profile then
    return
  end
  prompt(cx, { placeholder = "Profile name", value = profile.name }, function(name, fresh)
    local data = tern.kv.get(PROFILE_PREFIX .. id)
    data.name = name
    tern.kv.set(PROFILE_PREFIX .. id, data)
    notify(fresh)
  end)
end

local function configure(cx: WindowCx, id: string)
  local profile = definition(id)
  if not profile then
    return
  end
  prompt(cx, { placeholder = "Starting directory", value = profile.cwd }, function(cwd, fresh)
    local data = tern.kv.get(PROFILE_PREFIX .. id)
    data.cwd = cwd
    tern.kv.set(PROFILE_PREFIX .. id, data)
    notify(fresh)
  end)
end

local function move(cx: WindowCx, session: number)
  pick(cx, "Move space to profile", function(fresh, id)
    refresh(fresh)
    if not sessionKeys[session] then
      return
    end
    assign(session, id)
    notify(fresh)
  end)
end

local function action(ev: CanvasAction, cx: WindowCx): boolean
  if ev.act == "profile:new" then
    create(cx)
    return true
  end
  local id = string.match(ev.act, "^profile:([%w_-]+)$")
  if id then
    open(cx, id)
    return true
  end
  id = string.match(ev.node, "%.profile:([%w_-]+)$")
  if not id then
    return false
  end
  if ev.act == "Rename profile" then
    rename(cx, id)
  elseif ev.act == "Configure profile" then
    configure(cx, id)
  else
    return false
  end
  return true
end

local function model(session: number?)
  if #definitions == 0 then
    return nil
  end
  local id = profileId(session)
  local items = {}
  local name = nil
  for _, profile in definitions do
    table.insert(items, { id = profile.id, name = profile.name, current = profile.id == id })
    if profile.id == id then
      name = profile.name
    end
  end
  return { items = items, current = id, name = name }
end

local function filter(groups, session: number, sessions)
  local id = profileId(session)
  local counts = {}
  for _, item in sessions do
    if profileId(item.id) == id then
      counts[item.host] = (counts[item.host] or 0) + 1
    end
  end
  local result = {}
  local offset = 0
  for _, group in groups do
    local count = counts[group.id] or 0
    if count == 0 then
      continue
    end
    local rows = {}
    for _, item in group.sessions do
      if profileId(item.id) == id then
        local row = table.clone(item)
        row.index = offset + #rows + 1
        table.insert(rows, row)
      end
    end
    table.insert(
      result,
      { id = group.id, name = group.name, collapsed = group.collapsed, sessions = rows, count = count }
    )
    offset += count
  end
  return result
end

local function sessions(cx: WindowCx)
  refresh(cx)
  local id = profileId(cx.sessions:current().id)
  local result = {}
  for _, session in cx.sessions:list() do
    if profileId(session.id) == id then
      table.insert(result, session)
    end
  end
  return result
end

local function start(cx: WindowCx, onChanged)
  changed = onChanged
  if cx.settings:keybinds()[PICKER_CHORD] == nil and cx.actions:keys()[PICKER_CHORD] == nil then
    cx.settings:bind(PICKER_CHORD, PICKER_ACTION)
  end
  refresh(cx)
end

tern.command({ id = "new_profile", title = "New profile", group = GROUP, run = create })
tern.command({
  id = "open_profile",
  title = "Open profile",
  group = GROUP,
  run = function(cx)
    pick(cx, "Open profile", open)
  end,
})
tern.command({
  id = "rename_profile",
  title = "Rename profile",
  group = GROUP,
  run = function(cx)
    pick(cx, "Rename profile", rename)
  end,
})
tern.command({
  id = "configure_profile",
  title = "Configure profile",
  group = GROUP,
  run = function(cx)
    pick(cx, "Configure profile", configure)
  end,
})
tern.chrome.window_title(function(win)
  return if currentName then currentName .. " · " .. (win.space or "Tern") else nil
end)

return {
  start = start,
  refresh = refresh,
  model = model,
  filter = filter,
  sessions = sessions,
  profileId = profileId,
  addSpace = addSpace,
  move = move,
  action = action,
  hidden = function()
    return tern.kv.get(HIDDEN_KEY) == true
  end,
  setVisibility = function(mode: "hidden" | "visible")
    tern.kv.set(HIDDEN_KEY, if mode == "hidden" then true else nil)
  end,
}
