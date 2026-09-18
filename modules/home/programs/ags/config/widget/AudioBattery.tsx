import { execAsync } from "ags/process"
import Gtk from "gi://Gtk?version=4.0"
import { commands } from "../lib/commands"
import { createCommandState } from "../lib/poll"

interface VolumeStatus {
  text: string
  tooltip: string
  class: string
  percentage: number
}

interface BatteryStatus {
  text: string
  tooltip: string
  class: string
  percentage: number
}

const [volume, refreshVolume] = createCommandState<VolumeStatus>(
  { text: "vol unavailable", tooltip: "Audio sink unavailable", class: "unavailable", percentage: 0 },
  250,
  commands.volumeStatus,
)
const [battery] = createCommandState<BatteryStatus>(
  { text: "", tooltip: "No battery", class: "unavailable", percentage: 0 },
  60_000,
  commands.batteryStatus,
)

export default function AudioBattery() {
  const initVolumeButton = (button: Gtk.Button) => {
    const scroll = new Gtk.EventControllerScroll({
      flags: Gtk.EventControllerScrollFlags.VERTICAL,
    })
    scroll.connect("scroll", (_controller, _dx, dy) => {
      const adjustment = dy < 0 ? "1%+" : dy > 0 ? "1%-" : null
      if (adjustment) {
        void execAsync([
          commands.wpctl,
          "set-volume",
          "-l",
          "1.0",
          "@DEFAULT_AUDIO_SINK@",
          adjustment,
        ]).then(refreshVolume)
      }
      return true
    })
    button.add_controller(scroll)
  }

  return (
    <box cssClasses={["right-group"]}>
      <button
        $={initVolumeButton}
        cssClasses={volume((value) => ["right-item", "status", value.class].filter(Boolean))}
        tooltipText={volume((value) => value.tooltip)}
        onClicked={() => void execAsync(commands.pavucontrol)}
      >
        <label label={volume((value) => value.text)} />
      </button>
      <box
        cssClasses={battery((value) => ["right-item", "battery", value.class].filter(Boolean))}
        visible={battery((value) => value.text !== "")}
        tooltipText={battery((value) => value.tooltip)}
      >
        <label label={battery((value) => value.text)} />
      </box>
    </box>
  )
}
