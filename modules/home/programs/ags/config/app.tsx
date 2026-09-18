import { createBinding, For, onCleanup } from "ags"
import app from "ags/gtk4/app"
import Astal from "gi://Astal?version=4.0"
import Gdk from "gi://Gdk?version=4.0"
import Bar from "./widget/Bar"
import style from "./style.css"

const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

function BarWindow({ monitor }: { monitor: Gdk.Monitor }) {
  let window: Astal.Window

  onCleanup(() => window.destroy())

  return (
    <window
      $={(self) => (window = self)}
      visible
      name={`topbar-${monitor.connector ?? monitor.model ?? "default"}`}
      namespace="ags-topbar"
      cssClasses={["BarWindow"]}
      gdkmonitor={monitor}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      layer={Astal.Layer.TOP}
      anchor={TOP | LEFT | RIGHT}
      application={app}
    >
      <Bar />
    </window>
  )
}

app.start({
  instanceName: "ags",
  css: style,
  gtkTheme: "Adwaita",
  main() {
    return (
      <For each={createBinding(app, "monitors")}>
        {(monitor) => <BarWindow monitor={monitor} />}
      </For>
    )
  },
})
