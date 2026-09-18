import { execAsync } from "ags/process"
import Gtk from "gi://Gtk?version=4.0"
import { commands } from "../lib/commands"
import { createCommandState } from "../lib/poll"

interface FlashgenStatus {
  text: string
  tooltip: string
}

const [status, refresh] = createCommandState<FlashgenStatus>(
  { text: "", tooltip: "" },
  3_600_000,
  commands.flashgen,
)

export default function Flashgen() {
  const initButton = (button: Gtk.Button) => {
    const gesture = new Gtk.GestureClick({ button: 3 })
    gesture.connect("released", () => {
      void execAsync([commands.flashgen, "--open"])
    })
    button.add_controller(gesture)
  }

  return (
    <box cssClasses={["right-group"]} visible={status((value) => value.text !== "")}>
      <button
        $={initButton}
        cssClasses={["right-item", "flashgen"]}
        tooltipText={status((value) => value.tooltip)}
        onClicked={() => void refresh()}
      >
        <label label={status((value) => value.text)} />
      </button>
    </box>
  )
}
