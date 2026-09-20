import QtQuick
import Quickshell.Io
import Quickshell

Scope {
    id: root
    Component.onCompleted: root.refresh()

    property var command: []
    property int interval: 1000
    property var value: fallback
    property var fallback: ({})

    signal refreshed

    function refresh() {
        if (process.running || !root.command)
            return;
        var commandList = root.command instanceof Array ? root.command : [root.command];
        if (commandList.length === 0 || commandList[0] === "")
            return;
        process.command = commandList;
        process.running = true;
    }

    Process {
        id: process
        command: []
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    root.value = JSON.parse(text);
                } catch (error) {}
                root.refreshed();
                timer.restart();
            }
        }
    }

    Timer {
        id: timer
        interval: Math.max(1, root.interval)
        repeat: false
        running: true
        onTriggered: root.refresh()
    }
}
