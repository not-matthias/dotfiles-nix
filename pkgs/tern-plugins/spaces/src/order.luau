--!strict

-- Tern keeps no order of sessions a plugin can change, so the sidebar order lives in KV: one rank
-- per space, keyed by machine name like profile membership. Spaces without a rank follow the
-- ranked ones in Tern's order, so new spaces append.
local RANK_PREFIX = "rank:"

export type Placement = "before" | "after"

local function rankKey(hostName: string, session: number): string
  return RANK_PREFIX .. hostName .. ":" .. session
end

local function hostNames(hosts: { ManagedHost }): { [number]: string }
  local names = {}
  for _, host in hosts do
    names[host.id] = host.name
  end
  return names
end

-- The sessions in sidebar order, as a new list. Machines keep Tern's order (by their first
-- session); ranks only order spaces within one machine.
local function sort(sessions: { ManagedSession }, hosts: { ManagedHost }): { ManagedSession }
  local names = hostNames(hosts)
  local hostPositions: { [number]: number } = {}
  -- Tern's lists are protected: copy the rows rather than `table.clone` them.
  local entries = {}
  for position, session in sessions do
    hostPositions[session.host] = hostPositions[session.host] or position
    local name = names[session.host]
    local rank = if name then tern.kv.get(rankKey(name, session.id)) else nil
    table.insert(entries, {
      session = session,
      host = hostPositions[session.host],
      rank = if type(rank) == "number" then rank else math.huge,
      position = position,
    })
  end
  table.sort(entries, function(a, b)
    if a.host ~= b.host then
      return a.host < b.host
    end
    if a.rank ~= b.rank then
      return a.rank < b.rank
    end
    return a.position < b.position
  end)
  local result = {}
  for _, entry in entries do
    table.insert(result, entry.session)
  end
  return result
end

-- Moves `session` next to `target` on the same machine. Spaces of other profiles keep their places.
local function place(cx: WindowCx, session: number, target: number, placement: Placement): boolean
  local hosts = cx.hosts:list()
  local sessions = sort(cx.sessions:list(), hosts)
  local hostOf: { [number]: number } = {}
  for _, item in sessions do
    hostOf[item.id] = item.host
  end
  local host = hostOf[session]
  local name = if host then hostNames(hosts)[host] else nil
  -- A space lives on one machine: it cannot be dropped among another machine's spaces.
  if session == target or not name or hostOf[target] ~= host then
    return false
  end
  local order = {}
  for _, item in sessions do
    if item.host == host and item.id ~= session then
      table.insert(order, item.id)
    end
  end
  local index = table.find(order, target) :: number
  table.insert(order, if placement == "after" then index + 1 else index, session)
  for rank, id in order do
    tern.kv.set(rankKey(name, id), rank)
  end
  return true
end

return { sort = sort, place = place }
