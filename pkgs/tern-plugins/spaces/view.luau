--!strict

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
  .spaces-sidebar .space-row-current {
    border-radius: 4px;
    background-color: color-mix(in srgb, var(--t1) 9%, transparent);
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
    font-size: 14px;
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

local function button(label: string, action: string): Node
  return tern.ui.button(label, {
    key = action,
    actions = { click = action },
    variant = "quiet",
  })
end

local function view(groups, selectedSession: number): Node
  local rows = { tern.ui.text({ tern.ui.span("SPACES", "muted") }) }
  for _, host in groups do
    local marker = if host.collapsed then "▸ " else "▾ "
    table.insert(rows, button(marker .. host.name, "host:" .. host.id))
    for _, session in host.sessions do
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
                variant = if session.id == selectedSession then "primary" else "quiet",
              },
            },
          },
          menu = { "Rename" },
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
      table.insert(rows, tern.ui.el("div", { class = rowClass }, contents))
    end
  end
  return tern.ui.el("div", { class = "spaces-sidebar" }, rows)
end

return view
