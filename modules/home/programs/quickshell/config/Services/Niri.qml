pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Shared

Singleton {
    id: root

    readonly property var workspaces: snapshot.workspaces
    readonly property var windows: snapshot.windows
    readonly property string language: snapshot.language
    property var snapshot: ({
            workspaces: [],
            windows: [],
            language: ""
        })

    Process {
        id: stateProcess

        command: [Commands.niriState]
        running: true

        stdout: SplitParser {
            splitMarker: "\n"

            onRead: function (line) {
                root.consume(line);
            }
        }

        onRunningChanged: {
            if (running)
                retryTimer.stop();
            else
                retryTimer.restart();
        }
    }

    Timer {
        id: retryTimer
        interval: 1000
        repeat: false
        onTriggered: stateProcess.running = true
    }

    function consume(line) {
        try {
            const next = JSON.parse(line);
            if (!next || !Array.isArray(next.workspaces) || !Array.isArray(next.windows) || typeof next.language !== "string")
                return;
            root.snapshot = next;
        } catch (error) {
            // Keep the last valid state until the producer emits valid JSON again.
        }
    }
}
