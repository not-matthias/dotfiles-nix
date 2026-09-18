import { execAsync } from "ags/process"
import { commands } from "../lib/commands"
import { createCommandState } from "../lib/poll"

interface ServiceStatus {
  text: string
  tooltip: string
  class: string
}

const [idleStatus, refreshIdle] = createCommandState<ServiceStatus>(
  { text: "󰾪", tooltip: "Idle inhibit: OFF", class: "inactive" },
  2_000,
  commands.idleInhibitStatus,
)
const [dndStatus, refreshDnd] = createCommandState<ServiceStatus>(
  { text: "󰂚", tooltip: "Do not disturb: OFF", class: "inactive" },
  2_000,
  commands.dndStatus,
)

export default function Status() {
  const toggleIdle = async () => {
    await execAsync([
      "sh",
      "-c",
      `${commands.systemctl} --user is-active --quiet ags-idle-inhibit.service && ${commands.systemctl} --user stop ags-idle-inhibit.service || ${commands.systemctl} --user start ags-idle-inhibit.service`,
    ])
    await refreshIdle()
  }

  const toggleDnd = async () => {
    await execAsync([commands.dunstctl, "set-paused", "toggle"])
    await refreshDnd()
  }

  return (
    <box cssClasses={["right-group", "merged"]}>
      <button
        cssClasses={idleStatus((value) => ["right-item", "status", value.class].filter(Boolean))}
        tooltipText={idleStatus((value) => value.tooltip)}
        onClicked={() => void toggleIdle()}
      >
        <label label={idleStatus((value) => value.text)} />
      </button>
      <button
        cssClasses={dndStatus((value) => ["right-item", "status", value.class].filter(Boolean))}
        tooltipText={dndStatus((value) => value.tooltip)}
        onClicked={() => void toggleDnd()}
      >
        <label label={dndStatus((value) => value.text)} />
      </button>
    </box>
  )
}
