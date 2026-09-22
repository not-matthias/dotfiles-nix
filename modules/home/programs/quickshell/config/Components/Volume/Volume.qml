import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.Shared

BarButton {
    id: root

    property var sink: Pipewire.defaultAudioSink
    readonly property bool ready: sink?.ready ?? false
    readonly property real volume: ready ? (sink.audio?.volume ?? 0) : 0
    readonly property bool muted: ready ? (sink.audio?.muted ?? false) : false
    readonly property int percentage: Math.round(volume * 100)

    text: !ready || muted ? "󰖁" : volume < 0.5 ? "\uf027" : "\uf028"
    tooltipText: !ready ? "Audio sink unavailable" : muted ? "Volume: muted" : `Volume: ${percentage}%`
    foreground: !ready ? Theme.muted : Theme.foreground
    background: "transparent"
    borderColor: "transparent"
    interactive: ready

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    Process {
        id: pavucontrolProcess

        command: [Commands.pavucontrol]
    }

    function adjustVolume(steps) {
        if (steps === 0 || !sink?.audio)
            return;
        sink.audio.volume = Math.max(0, Math.min(1, volume + steps * 0.01));
    }

    onClicked: function (button) {
        if (button === Qt.LeftButton)
            pavucontrolProcess.running = true;
    }
    onWheel: function (steps) {
        adjustVolume(steps);
    }
}
