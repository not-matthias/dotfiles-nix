pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Shared

Singleton {
    id: root

    readonly property var unavailable: ({
            available: false
        })

    readonly property var fan: poll.value.fan ?? unavailable
    readonly property var cpu: poll.value.cpu ?? unavailable

    // Quietest to loudest, and slowest to fastest, so the widget can map a
    // position in the list to an icon and a colour.
    readonly property var fanStrategies: Commands.fanStrategies
    readonly property var cpuModes: ["powersave", "auto", "performance"]

    readonly property bool busy: action.running
    readonly property bool enabled: Commands.powerProfiles.length > 0

    function apply(kind, value) {
        if (action.running || !root.enabled || value.length === 0)
            return;
        action.command = [Commands.powerProfiles, kind, value];
        action.running = true;
    }

    function setFan(strategy) {
        apply("fan", strategy);
    }

    function setCpu(mode) {
        apply("cpu", mode);
    }

    JsonPoll {
        id: poll

        command: root.enabled ? [Commands.powerProfiles, "get"] : []
        interval: 15000
        fallback: ({
                fan: root.unavailable,
                cpu: root.unavailable
            })
    }

    Process {
        id: action

        onExited: poll.refresh()
    }
}
