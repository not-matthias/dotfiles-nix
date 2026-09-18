import type { Accessor } from "ags"
import { execAsync } from "ags/process"
import Gtk from "gi://Gtk?version=4.0"
import { commands } from "../lib/commands"
import { createCommandState } from "../lib/poll"

interface UsageStatus {
  text: string
  tooltip: string
  class: string
  percentage: number
}
interface AiState {
  command: string
  status: Accessor<UsageStatus>
  refresh: () => Promise<void>
}


function createAiState(command: string): AiState {
  const [status, refresh] = createCommandState<UsageStatus>(
    { text: "", tooltip: "", class: "", percentage: 0 },
    600_000,
    command,
  )
  return { command, status, refresh }
}

const claude = createAiState(commands.claudeUsage)
const codex = createAiState(commands.codexUsage)
const antigravity = createAiState(commands.antigravityUsage)

function UsageItem({ item }: { item: AiState }) {
  const { status, refresh } = item
  const initButton = (button: Gtk.Button) => {
    const gesture = new Gtk.GestureClick({ button: 3 })
    gesture.connect("released", async () => {
      try {
        await execAsync([item.command, "--restart"])
      } finally {
        await refresh()
      }
    })
    button.add_controller(gesture)
  }

  return (
    <button
      $={initButton}
      cssClasses={status((value) => ["right-item", "ai-item", value.class].filter(Boolean))}
      tooltipText={status((value) => value.tooltip)}
      onClicked={() => void refresh()}
    >
      <label label={status((value) => value.text)} />
    </button>
  )
}

export default function AiUsage() {
  return (
    <box cssClasses={["right-group", "merged"]}>
      <UsageItem item={claude} />
      <UsageItem item={codex} />
      <UsageItem item={antigravity} />
    </box>
  )
}
