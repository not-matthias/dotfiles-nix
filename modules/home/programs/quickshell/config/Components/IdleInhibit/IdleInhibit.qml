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
    interactive: !query.running && !action.running
    text: status.text
    tooltipText: status.tooltip

    JsonPoll {
        id: statusPoll

        command: Commands.idleInhibitStatus
        interval: 2000
        fallback: ({
                text: "󰾪",
                tooltip: "Idle inhibit: OFF",
                class: "inactive"
            })
    }

    Process {
        id: query

        command: [Commands.systemctl, "--user", "is-active", "--quiet", "quickshell-idle-inhibit.service",]

        onExited: function (exitCode) {
            action.command = [Commands.systemctl, "--user", exitCode === 0 ? "stop" : "start", "quickshell-idle-inhibit.service",];
            action.running = true;
        }
    }

    Process {
        id: action

        command: []

        onExited: statusPoll.refresh()
    }

    onClicked: function (button) {
        if (button === Qt.LeftButton)
            query.running = true;
    }
}
