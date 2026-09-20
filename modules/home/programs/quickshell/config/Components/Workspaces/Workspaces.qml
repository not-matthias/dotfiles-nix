import QtQuick
import Quickshell.Io
import qs.Services
import qs.Shared

PillGroup {
    id: root

    Row {
        spacing: 2

        Repeater {
            model: Niri.workspaces

            delegate: BarButton {
                required property var modelData

                text: modelData.name || String(modelData.idx)
                tooltipText: modelData.name || `Workspace ${modelData.idx}`
                foreground: modelData.is_focused || modelData.is_urgent ? Theme.barBackground : Theme.statusColor(modelData.is_active ? "active" : "inactive")
                background: modelData.is_focused ? Theme.statusColor("focused") : modelData.is_urgent ? Theme.statusColor("urgent") : "transparent"
                borderColor: "transparent"
                interactive: true

                Process {
                    id: focusWorkspace
                }

                onClicked: function (button) {
                    if (button === Qt.LeftButton)
                        focusWorkspace.exec([Commands.niri, "msg", "action", "focus-workspace", String(modelData.idx),]);
                }
            }
        }

        Item {
            width: 8
            height: 1
        }
        Repeater {
            model: Niri.windows

            delegate: Text {
                required property var modelData
                anchors.verticalCenter: parent.verticalCenter

                color: Theme.statusColor(modelData.is_focused ? "focused" : "inactive")
                text: modelData.is_focused ? "󰪥" : "󰄰"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 1
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}
