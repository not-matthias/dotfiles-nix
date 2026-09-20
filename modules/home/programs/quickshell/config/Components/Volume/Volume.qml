import QtQuick
import Quickshell.Io
import qs.Shared

BarButton {
    id: root

    text: statusPoll.value.text
    tooltipText: statusPoll.value.tooltip
    foreground: Theme.statusColor(statusPoll.value.class)
    background: "transparent"
    borderColor: "transparent"
    interactive: true

    JsonPoll {
        id: statusPoll

        command: Commands.volumeStatus
        interval: 250
        fallback: ({
                text: "vol unavailable",
                tooltip: "Audio sink unavailable",
                class: "unavailable",
                percentage: 0
            })
    }

    Process {
        id: volumeProcess
        command: []
        onExited: statusPoll.refresh()
    }

    Process {
        id: pavucontrolProcess

        command: [Commands.pavucontrol]
    }

    function adjustVolume(steps) {
        if (steps === 0)
            return;
        volumeProcess.command = [Commands.wpctl, "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", steps > 0 ? "1%+" : "1%-",];
        volumeProcess.running = true;
    }

    onClicked: function (button) {
        if (button === Qt.LeftButton)
            pavucontrolProcess.running = true;
    }
    onWheel: function (steps) {
        adjustVolume(steps);
    }
}
