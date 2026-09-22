pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Shared

Singleton {
    id: root

    readonly property var fallback: ({
            text: "",
            tooltip: "",
            class: ""
        })
    property var status: fallback

    function refresh() {
        if (process.running)
            return;

        process.command = [Commands.flashgen];
        process.running = true;
    }

    function scheduleNextHour() {
        const now = new Date();
        const nextHour = new Date(now);
        nextHour.setMinutes(0, 0, 0);
        nextHour.setHours(nextHour.getHours() + 1);
        refreshTimer.interval = Math.max(1, nextHour.getTime() - now.getTime());
        refreshTimer.restart();
    }

    Process {
        id: process
        command: []

        stdout: StdioCollector {
            waitForEnd: true

            onStreamFinished: {
                try {
                    const nextStatus = JSON.parse(text);
                    if (nextStatus && typeof nextStatus === "object")
                        root.status = nextStatus;
                } catch (error) {}
                root.scheduleNextHour();
            }
        }
    }

    Timer {
        id: refreshTimer
        repeat: false
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()
}
