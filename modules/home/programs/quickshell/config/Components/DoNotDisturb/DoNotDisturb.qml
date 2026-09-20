import QtQuick
import Quickshell
import qs.Shared
import Quickshell.Io

BarButton {
    id: root
    property var status: statusPoll.value || statusPoll.fallback

    background: "transparent"
    borderColor: "transparent"
    foreground: Theme.statusColor(status.class)
    interactive: !action.running
    text: status.text
    tooltipText: status.tooltip

    JsonPoll {
        id: statusPoll

        command: Commands.dndStatus
        interval: 2000
        fallback: ({
                text: "󰂚",
                tooltip: "Do not disturb: OFF",
                class: "inactive"
            })
    }

    Process {
        id: action

        command: [Commands.dunstctl, "set-paused", "toggle"]

        onExited: statusPoll.refresh()
    }

    onClicked: function (button) {
        if (button === Qt.LeftButton)
            action.running = true;
    }
}
