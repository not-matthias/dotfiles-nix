import QtQuick
import Quickshell.Io

import qs.Shared

Item {
    id: root

    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    JsonPoll {
        id: mode
        command: [Commands.desktopTheme, "get", "--json"]
        interval: 1500
        fallback: ({ mode: Commands.defaultTheme })
    }

    Process {
        id: toggle
        command: [Commands.desktopTheme, "toggle"]
    }

    BarButton {
        id: button
        anchors.fill: parent
        text: mode.value.mode === "dark" ? "☾" : "☀"
        tooltipText: "Application theme: " + mode.value.mode + " (click to switch)"
        onClicked: toggle.running = true
    }
}
