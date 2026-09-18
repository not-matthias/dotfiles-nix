import Gtk from "gi://Gtk?version=4.0"
import AiUsage from "./AiUsage"
import AudioBattery from "./AudioBattery"
import Clock from "./Clock"
import Flashgen from "./Flashgen"
import Language from "./Language"
import Status from "./Status"
import Tray from "./Tray"
import Workspaces from "./Workspaces"

export default function Bar() {
  return (
    <centerbox cssClasses={["bar"]}>
      <Workspaces $type="start" />
      <Clock $type="center" />
      <box $type="end" cssClasses={["right"]} halign={Gtk.Align.END}>
        <Flashgen />
        <AiUsage />
        <Status />
        <Language />
        <AudioBattery />
        <Tray />
      </box>
    </centerbox>
  )
}
