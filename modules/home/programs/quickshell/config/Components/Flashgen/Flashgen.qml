import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services
import qs.Shared

BarButton {
    id: root

    readonly property var status: Flashgen.status || Flashgen.fallback
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

    Process {
        id: openProcess
        command: [Commands.flashgen, "--open"]
    }

    onClicked: function (button) {
        if (button === Qt.LeftButton)
            Flashgen.refresh();
        else if (button === Qt.RightButton && !openProcess.running)
            openProcess.running = true;
    }
}
