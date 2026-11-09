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
    min-height: 18px;
    justify-content: flex-start;
    padding: 0 6px;
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

local function view(groups, selectedSession: number, profiles): Node
  local rows = {}
  if profiles then
    table.insert(rows, profileRow(profiles))
  end
  table.insert(rows, tern.ui.text({ tern.ui.span("SPACES", "muted") }))
  for _, host in groups do
    local marker = if host.collapsed then "▸ " else "▾ "
    table.insert(rows, button(marker .. host.name, "host:" .. host.id))
    for _, session in host.sessions do
      local action = "space:" .. session.id
      local title = tern.ui.table({ { id = "name", head = "", grow = 1 } }, {
        {
          id = tostring(session.id),
          cells = {
            {
              button = {
                text = session.name,
                act = action,
                variant = "quiet",
              },
            },
          },
          menu = { "Rename", "Move to profile" },
        },
      })
      title.p.key = action
      local nameParts = { title }
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
          tern.ui.el("div", {
            class = "space-branch",
            actions = { click = action },
          }, { tern.ui.text({ tern.ui.span(branch, "muted") }) })
        )
      end
      local rowClass = if session.id == selectedSession then "space-row space-row-current" else "space-row"
      local color = BADGE_COLORS[session.id % #BADGE_COLORS + 1]
      local badge = tern.ui.el("div", {
        class = "space-index space-color-" .. color,
        actions = { click = action },
      }, { tern.ui.text(tostring(session.index)) })
      table.insert(
        rows,
        tern.ui.el("div", { class = rowClass }, {
          badge,
          tern.ui.el("div", { class = "space-content" }, contents),
        })
      )
    end
  end
  return tern.ui.el("div", { class = "spaces-sidebar" }, rows)
end

return view
