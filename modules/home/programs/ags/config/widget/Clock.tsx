import { createPoll } from "ags/time"
import GLib from "gi://GLib?version=2.0"
import Gtk from "gi://Gtk?version=4.0"

export default function Clock() {
  const time = createPoll("", 1000, () =>
    GLib.DateTime.new_now_local().format("%a %d %b · %H:%M") ?? "",
  )

  return (
    <box cssClasses={["section", "center"]} halign={Gtk.Align.CENTER}>
      <menubutton cssClasses={["clock-item"]} tooltipText="Open calendar">
        <label cssClasses={["clock"]} label={time} />
        <popover cssClasses={["calendar-popup"]}>
          <Gtk.Calendar cssClasses={["calendar"]} showHeading showDayNames />
        </popover>
      </menubutton>
    </box>
  )
}
