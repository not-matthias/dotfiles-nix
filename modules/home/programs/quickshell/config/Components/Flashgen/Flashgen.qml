import QtQuick
import Quickshell
import Quickshell.Io
import qs.Shared

BarButton {
    id: root

    property var status: poll.value || poll.fallback
    readonly property string statusText: status.text || ""
    readonly property string statusTooltip: status.tooltip || ""
    readonly property string statusClass: status.class || ""

    visible: statusText.length > 0
    text: statusText
    tooltipText: statusTooltip
    foreground: Theme.statusColor(statusClass)
    background: "transparent"
    borderColor: Theme.accent
    interactive: statusText.length > 0

    JsonPoll {
        id: poll

        command: Commands.flashgen
        interval: 3600000
        fallback: ({
                text: "",
                tooltip: "",
                class: ""
            })
        Component.onCompleted: refresh()
    }

    Process {
        id: openProcess
        command: [Commands.flashgen, "--open"]
    }

    onClicked: function (button) {
        if (button === Qt.LeftButton)
            poll.refresh();
        else if (button === Qt.RightButton && !openProcess.running)
            openProcess.running = true;
    }
}
