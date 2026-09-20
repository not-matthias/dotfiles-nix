//@ pragma UseQApplication

import Quickshell
import QtQuick

import qs.Shared

ShellRoot {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            property var modelData

            screen: modelData
            anchors {
                top: true
                left: true
                right: true
            }
            implicitHeight: Theme.barHeight
            exclusiveZone: Theme.barHeight
            focusable: false
            aboveWindows: true
            color: "transparent"

            Bar {
                anchors.fill: parent
            }
        }
    }
}
