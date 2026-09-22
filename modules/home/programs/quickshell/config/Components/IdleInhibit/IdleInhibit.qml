import QtQuick
import Quickshell
import qs.Shared
import Quickshell.Io
import qs.Services

BarButton {
    id: root
    property var status: Status.idleInhibit

    background: "transparent"
    borderColor: "transparent"
    foreground: Theme.statusColor(status.class)
    interactive: !action.running
    text: status.text
    tooltipText: status.tooltip

    Process {
        id: action

        command: [Commands.systemctl, "--user", status.class === "active" ? "stop" : "start", "quickshell-idle-inhibit.service"]
    }

    onClicked: function (button) {
        if (button === Qt.LeftButton)
            action.running = true;
    }
}
