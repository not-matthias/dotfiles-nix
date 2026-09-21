import QtQuick
import Quickshell
import Quickshell.Services.SystemTray as SystemTrayService
import qs.Shared

PillGroup {
    id: root

    visible: SystemTrayService.SystemTray.items.values.length > 0

    Item {
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: trayItems.implicitWidth + 16
        implicitHeight: trayItems.implicitHeight

        Row {
            id: trayItems

            anchors.centerIn: parent
            spacing: 2

            Repeater {
                model: SystemTrayService.SystemTray.items
                delegate: TrayItem {}
            }
        }
    }
}
