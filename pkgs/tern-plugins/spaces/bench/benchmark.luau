-- Appended to an isolated copy of the plugin's window entry by benchmark.py.
-- Revisions before the src/ layout kept panel drawing in the entry: `flush`, `updates`, and
-- `panels` and `view` functions instead of the `panels` and `view` modules.
local SETTLE_MS = 50
local benchmarkSync = sync
local benchmarkRefresh = refresh
local capture = nil
local polling = false
sync = function(cx)
  local start = tern.now()
  benchmarkSync(cx)
  if capture then
    capture.ms += tern.now() - start
    capture.syncs += 1
    if polling then
      capture.poll_syncs += 1
    end
  end
end
refresh = function(cx)
  polling = true
  benchmarkRefresh(cx)
  polling = false
end

local function timedFlush(original)
  return function(cx)
    local start = tern.now()
    original(cx)
    if capture then
      capture.ms += tern.now() - start
      capture.flushes += 1
    end
  end
end
local function countedView(original)
  return function(...)
    if capture then
      capture.views += 1
    end
    return original(...)
  end
end
local modular = type(panels) == "table"
if modular then
  panels.flush = timedFlush(panels.flush)
  view.render = countedView(view.render)
else
  if flush then
    flush = timedFlush(flush)
  end
  view = countedView(view)
end

local function drawing(): boolean
  if modular then
    return panels.pending()
  end
  return updates ~= nil and next(updates) ~= nil
end

tern.command({
  id = "benchmark",
  title = "Benchmark sidebar refresh",
  run = function(cx: WindowCx)
    local samples = tonumber(tern.getenv("TERN_BENCH_SAMPLES"))
    local warmup = tonumber(tern.getenv("TERN_BENCH_WARMUP"))
    local scenarios = { "unchanged", "switch", "rename" }
    local sessions = cx.sessions:list()
    assert(#sessions >= 2, "Benchmark needs at least two workspaces")
    for index, session in sessions do
      local name = string.format("Workspace %02d", index)
      cx.sessions:rename(session.id, name)
      tern.kv.set(CUSTOM_NAME_PREFIX .. session.id, name)
    end
    sync(cx)

    local scenarioIndex = 1
    local iteration = 0
    local function step(fresh: WindowCx)
      iteration += 1
      local scenario = scenarios[scenarioIndex]
      local position = if scenario == "switch" then (iteration % 2) + 1 else 1
      local target = sessions[position].id
      if scenario ~= "switch" then
        fresh.sessions:switch(target)
      end
      local name = string.format("Renamed workspace %02d", iteration)
      if scenario == "rename" then
        tern.kv.set(CUSTOM_NAME_PREFIX .. target, name)
      end

      capture = { scenario = scenario, ms = 0, syncs = 0, poll_syncs = 0, flushes = 0, views = 0 }
      local start = tern.now()
      if scenario == "switch" then
        benchmarkCommands["space_" .. position](fresh)
      else
        if scenario == "rename" then
          fresh.sessions:rename(target, name)
        end
        sync(fresh)
      end
      capture.dispatch_ms = tern.now() - start

      -- Include queued hooks and background panel writes before starting another action.
      local function finish(settled: WindowCx)
        if drawing() then
          tern.timer(SETTLE_MS, finish)
          return
        end
        local sample = capture
        capture = nil
        assert(settled.sessions:current().id == target, "Workspace switch did not apply")
        if iteration > warmup then
          tern.log.warn("SPACES_BENCH_SAMPLE " .. tern.json.encode(sample))
        end
        if iteration == samples + warmup then
          scenarioIndex += 1
          iteration = 0
        end
        if scenarioIndex > #scenarios then
          tern.log.warn("SPACES_BENCH_DONE")
          return
        end
        tern.timer(0, step)
      end
      tern.timer(SETTLE_MS, finish)
    end
    local function begin(fresh: WindowCx)
      if drawing() then
        tern.timer(SETTLE_MS, begin)
        return
      end
      step(fresh)
    end
    tern.timer(SETTLE_MS, begin)
  end,
})
