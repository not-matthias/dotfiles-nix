import QtQuick
import Quickshell
import Quickshell.Services.SystemTray as SystemTrayService

Row {
    id: root

    readonly property bool hasItems: SystemTrayService.SystemTray.items.values.length > 0

    spacing: 2
    visible: hasItems

    Repeater {
        model: SystemTrayService.SystemTray.items
        delegate: TrayItem {}
    }
}
