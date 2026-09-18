import { createBinding, For } from "ags"
import AstalTray from "gi://AstalTray"
import Gtk from "gi://Gtk?version=4.0"

export default function Tray() {
  const tray = AstalTray.get_default()

  const initItem = (button: Gtk.MenuButton, item: AstalTray.TrayItem) => {
    button.menuModel = item.menuModel
    button.insert_action_group("dbusmenu", item.actionGroup)
    item.connect("notify::action-group", () => {
      button.insert_action_group("dbusmenu", item.actionGroup)
    })
  }

  return (
    <box cssClasses={["right-group"]}>
      <box cssClasses={["right-item", "tray"]}>
        <For each={createBinding(tray, "items")}>
          {(item) => (
            <menubutton
              $={(self) => initItem(self, item)}
              cssClasses={["tray-button"]}
              tooltipMarkup={createBinding(item, "tooltipMarkup")}
            >
              <image gicon={createBinding(item, "gicon")} pixelSize={14} />
            </menubutton>
          )}
        </For>
      </box>
    </box>
  )
}
