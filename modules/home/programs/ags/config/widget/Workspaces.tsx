import { For } from "ags"
import { createSubprocess, execAsync } from "ags/process"
import Gtk from "gi://Gtk?version=4.0"
import { commands } from "../lib/commands"

interface Workspace {
  id: number
  idx: number
  name?: string
  is_active: boolean
  is_focused: boolean
  is_urgent: boolean
}

interface NiriWindow {
  id: number
  is_focused: boolean
}

interface NiriState {
  workspaces: Workspace[]
  windows: NiriWindow[]
  language: string
}

const emptyState: NiriState = {
  workspaces: [],
  windows: [],
  language: "",
}

export const niriState = createSubprocess(
  emptyState,
  commands.niriState,
  (output, previous) => {
    try {
      return JSON.parse(output) as NiriState
    } catch (error) {
      console.error("Failed to parse Niri state:", error)
      return previous
    }
  },
)

export default function Workspaces() {
  return (
    <box cssClasses={["section", "left"]} halign={Gtk.Align.START}>
      <box cssClasses={["workspaces"]}>
        <For each={niriState((state) => state.workspaces)}>
          {(workspace) => (
            <button
              cssClasses={[
                "workspace",
                workspace.is_active ? "active" : "",
                workspace.is_focused ? "focused" : "",
                workspace.is_urgent ? "urgent" : "",
              ].filter(Boolean)}
              tooltipText={workspace.name ?? `Workspace ${workspace.idx}`}
              onClicked={() => {
                void execAsync([
                  commands.niri,
                  "msg",
                  "action",
                  "focus-workspace",
                  String(workspace.idx),
                ])
              }}
            >
              <label label={workspace.name ?? String(workspace.idx)} />
            </button>
          )}
        </For>
      </box>
      <box cssClasses={["window-dots"]}>
        <For each={niriState((state) => state.windows)}>
          {(window) => (
            <label
              cssClasses={["window-dot", window.is_focused ? "focused" : ""].filter(Boolean)}
              label={window.is_focused ? "󰪥" : "󰄰"}
            />
          )}
        </For>
      </box>
    </box>
  )
}
