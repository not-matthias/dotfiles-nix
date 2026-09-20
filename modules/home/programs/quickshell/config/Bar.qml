import QtQuick

import qs.Components.AiUsage
import qs.Components.Battery
import qs.Components.Clock
import qs.Components.DoNotDisturb
import qs.Components.Flashgen
import qs.Components.IdleInhibit
import qs.Components.Language
import qs.Components.SystemTray
import qs.Components.Volume
import qs.Components.Workspaces
import qs.Shared

Item {
    id: bar

    implicitHeight: Theme.barHeight
    anchors.fill: parent

    Rectangle {
        anchors.fill: parent
        color: Theme.barBackground
    }

    Workspaces {
        id: workspaces
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
    }

    Clock {
        id: clock
        anchors.centerIn: parent
    }

    Row {
        id: rightItems
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Flashgen {}
        AiUsage {}

        PillGroup {
            IdleInhibit {}
            DoNotDisturb {}
        }

        Language {}

        PillGroup {
            Volume {}
            Battery {}
        }

        SystemTray {
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
