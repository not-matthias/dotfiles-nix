--!strict

tern.css(
  "sidebar",
  [[
  .spaces-sidebar {
    display: flex;
    flex-direction: column;
    gap: 2px;
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
    align-items: center;
    gap: 6px;
    padding: 2px 6px;
    border-radius: 8px;
    min-width: 0;
  }
  .spaces-sidebar .space-row-current {
    border-radius: 8px;
    background-color: color-mix(in srgb, var(--t1) 9%, transparent);
  }
  .spaces-sidebar .space-list {
    display: flex;
    flex-direction: column;
    gap: 2px;
    min-width: 0;
  }
  .spaces-sidebar .space-content {
    flex: 1;
    min-width: 0;
  }
  .spaces-sidebar .space-index {
    display: flex;
    align-items: center;
    justify-content: center;
    flex: 0 0 auto;
    min-width: 28px;
    height: 28px;
    border-radius: 7px;
    font-size: 14px;
    font-weight: 600;
    color: #ffffff;
  }
  .spaces-sidebar .space-color-blue { background-color: #3978c6; }
  .spaces-sidebar .space-color-teal { background-color: #158575; }
  .spaces-sidebar .space-color-orange { background-color: #b86128; }
  .spaces-sidebar .space-color-purple { background-color: #8051bc; }
  .spaces-sidebar .space-color-pink { background-color: #b84274; }
  .spaces-sidebar .space-color-yellow { background-color: #8f7615; }
  /* The text box ends 1px above the name row, so the branch below never overlaps it while the
     row's layout animation is still settling. The glyphs sit where an 18px box would put them. */
  .spaces-sidebar .space-name {
    margin: 0;
    display: flex;
    align-items: flex-start;
    height: 18px;
    min-width: 0;
  }
  .spaces-sidebar .space-name > .sf-text {
    flex: 1;
    margin: 0;
    padding: 0 6px;
    height: 17px;
    line-height: 18px;
  }
  .spaces-sidebar .space-name > .sf-text,
  .spaces-sidebar .space-branch .sf-text {
    min-width: 0;
    overflow: hidden;
    white-space: nowrap;
    text-overflow: ellipsis;
  }
  .spaces-sidebar .space-agent {
    align-self: center;
    flex: 0 0 auto;
    width: 11px;
    height: 11px;
    margin: 0 4px;
    border-radius: 50%;
    box-sizing: border-box;
  }
  .spaces-sidebar .space-agent-working {
    background-color: #269c56;
  }
  .spaces-sidebar .space-agent-waiting-input {
    background-color: #c38a22;
  }
  .spaces-sidebar .space-agent-idle,
  .spaces-sidebar .space-agent-present {
    opacity: 0.55;
    border: 2px solid var(--t1);
  }
  .spaces-sidebar .space-branch {
    padding: 0 6px;
    font-size: 11px;
    overflow: hidden;
    white-space: nowrap;
    text-overflow: ellipsis;
  }
  .spaces-sidebar .space-branch .sf-text {
    margin: 0;
    font-size: 11px;
    line-height: 14px;
  }
  .spaces-sidebar .spaces-profiles {
    display: flex;
    flex-direction: row;
    gap: 4px;
    padding-bottom: 6px;
    border-bottom: 1px solid var(--t4);
    overflow-x: auto;
    flex-shrink: 0;
  }
  .spaces-sidebar .profile-item {
    flex: 0 0 auto;
  }
  .spaces-sidebar .profile-item button {
    width: auto;
    white-space: nowrap;
    padding: 3px 7px;
    border-radius: 5px;
  }
  .spaces-sidebar .profile-current button {
    color: var(--accent);
    background-color: color-mix(in srgb, var(--accent) 12%, transparent);
  }
  .spaces-sidebar .spaces-profiles > .sf-button {
    width: auto;
    padding: 3px 7px;
  }
  .spaces-sidebar .space-slot {
    position: relative;
  }
  .spaces-sidebar .space-zone {
    display: none;
    position: absolute;
    left: 0;
    top: 0;
    right: 0;
    bottom: 0;
  }
  .spaces-sidebar .sf-drag-slot.sf-gone {
    display: block;
  }
]]
)

local function button(label: string, action: string): Node
  return tern.ui.button(label, {
    key = action,
    actions = { click = action },
    variant = "quiet",
  })
end

local BADGE_COLORS = { "blue", "teal", "orange", "purple", "pink", "yellow" }
-- Canvas actions do not say which child of a `drag` container moved, so every row holds one
-- hidden drop zone per other space of its machine within DRAG_REACH rows, acting
-- `place:<that space>`. CSS shows only the zones of the space being dragged, and the drop node
-- names the row it landed on.
local PLACE_PREFIX = "place:"
-- Zones grow with the spaces times this reach rather than with the square of the spaces; it still
-- spans more rows than a screen shows.
local DRAG_REACH = 16

-- The space a `place:<id>` action says was dragged.
local function placeSource(act: string): number?
  if string.sub(act, 1, #PLACE_PREFIX) ~= PLACE_PREFIX then
    return nil
  end
  return tonumber(string.sub(act, #PLACE_PREFIX + 1))
end

-- The stylesheet is shared by every sidebar of this window, whatever profile each one shows.
local zoneIds: { [number]: boolean } = {}

-- `:has()` cannot compare class names, so each rendered space gets its own rule.
local function zoneCss(ids: { number })
  local added = false
  for _, id in ids do
    if not zoneIds[id] then
      zoneIds[id] = true
      added = true
    end
  end
  if not added then
    return
  end
  local rules = {}
  for id in zoneIds do
    table.insert(
      rules,
      string.format(".spaces-sidebar:has(.drag-src-%d.sf-dragging) .space-zone-%d { display: block; }", id, id)
    )
  end
  tern.css("drag-zones", table.concat(rules, "\n"))
end

-- `tern.ui.el` re-encodes every node below it, so wrapping already built rows in it again at each
-- level costs depth × rows, and the n² drop zones made that run past the 50 ms budget. Plain
-- containers of built nodes are therefore made as wire nodes directly.
local function wrap(props: { [string]: any }, children: { Node }): Node
  props.tag = "div"
  return { k = "el", p = props, c = children }
end

local function profileRow(profiles): Node
  local items = {}
  for _, profile in profiles.items do
    local action = "profile:" .. profile.id
    local title = tern.ui.button(profile.name, {
      key = action,
      variant = "quiet",
      actions = {
        click = action,
        menu = { "Rename profile", "Configure profile" },
      },
    })
    local class = if profile.current then "profile-item profile-current" else "profile-item"
    table.insert(
      items,
      tern.ui.el("div", {
        class = class,
        attrs = { ["data-profile"] = profile.id },
      }, { title })
    )
  end
  table.insert(items, button("+", "profile:new"))
  return tern.ui.el("div", { class = "spaces-profiles" }, items)
end

local function render(groups, selectedSession: number, profiles): Node
  local rows = {}
  local ids = {}
  if profiles then
    table.insert(rows, profileRow(profiles))
  end
  table.insert(rows, tern.ui.text({ tern.ui.span("SPACES", "muted") }))
  for _, host in groups do
    local marker = if host.collapsed then "▸ " else "▾ "
    table.insert(rows, button(marker .. host.name, "host:" .. host.id))
    local spaceRows = {}
    -- A space's zone is the same in every row, so one node serves them all.
    local sessions = host.sessions
    local zones: { [number]: Node } = {}
    for _, session in sessions do
      zones[session.id] = wrap({
        class = "space-zone space-zone-" .. session.id,
        key = "zone:" .. session.id,
        drop = PLACE_PREFIX .. session.id,
      }, {})
    end
    for index, session in sessions do
      table.insert(ids, session.id)
      local action = "space:" .. session.id
      local nameParts = { tern.ui.text(session.name) }
      local agentState = session.agent
      if agentState then
        local labels = {
          working = "Agent working",
          waiting_input = "Agent awaiting input",
          idle = "Idle agent",
          present = "Agent present",
        }
        local label = labels[agentState]
        local stateClass = string.gsub(agentState, "_", "-")
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
          }, {})
        )
      end
      local contents = { tern.ui.el("div", { class = "space-name" }, nameParts) }
      local branch = session.branch
      if branch then
        table.insert(
          contents,
          tern.ui.el("div", { class = "space-branch" }, { tern.ui.text({ tern.ui.span(branch, "muted") }) })
        )
      end
      local rowClass = if session.id == selectedSession then "space-row space-row-current" else "space-row"
      local color = BADGE_COLORS[session.id % #BADGE_COLORS + 1]
      local badge = tern.ui.el(
        "div",
        { class = "space-index space-color-" .. color },
        { tern.ui.text(tostring(session.index)) }
      )
      local rowKey = "row:" .. session.id
      local row = tern.ui.el("div", {
        class = rowClass,
        key = rowKey,
        motionKey = rowKey,
        actions = { click = action, menu = { "Rename", "Move to profile" } },
      }, {
        badge,
        tern.ui.el("div", { class = "space-content" }, contents),
      })
      local slot = {
        wrap({
          class = "drag-src drag-src-" .. session.id,
          key = "drag:" .. session.id,
          drag = "drag-row",
        }, { row }),
      }
      for other = math.max(1, index - DRAG_REACH), math.min(#sessions, index + DRAG_REACH) do
        if other ~= index then
          table.insert(slot, zones[sessions[other].id])
        end
      end
      table.insert(spaceRows, wrap({ class = "space-slot", key = "slot:" .. session.id }, slot))
    end
    -- Dropping the whole list at once leaves no row to animate out.
    if not host.collapsed then
      table.insert(
        rows,
        wrap({
          class = "space-list",
          key = "host-spaces:" .. host.id,
          transition = "layout",
        }, spaceRows)
      )
    end
  end
  zoneCss(ids)
  return wrap({ class = "spaces-sidebar" }, rows)
end

return { render = render, placeSource = placeSource }
