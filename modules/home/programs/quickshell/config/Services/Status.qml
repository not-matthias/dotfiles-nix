pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Shared

Singleton {
    id: root

    readonly property var dnd: dndState
    readonly property var idleInhibit: idleInhibitState

    property var dndState: ({
            text: "󰂚",
            tooltip: "Do not disturb: OFF",
            class: "inactive"
        })
    property var idleInhibitState: ({
            text: "󰾪",
            tooltip: "Idle inhibit: OFF",
            class: "inactive"
        })
    property int retryDelay: 1000

    Process {
        id: statusProcess

        command: [Commands.statusBridge]
        running: true

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function (line) {
                root.consume(line);
            }
        }

        onRunningChanged: {
            if (running) {
                retryTimer.stop();
                root.retryDelay = 1000;
            } else {
                retryTimer.interval = root.retryDelay;
                retryTimer.start();
                root.retryDelay = Math.min(root.retryDelay * 2, 30000);
            }
        }
    }

    Timer {
        id: retryTimer

        repeat: false
        onTriggered: statusProcess.running = true
    }

    function consume(line) {
        try {
            const state = JSON.parse(line);
            if (state.dnd)
                dndState = state.dnd;
            if (state.idleInhibit)
                idleInhibitState = state.idleInhibit;
        } catch (error) {}
    }
}
