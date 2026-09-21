import QtQuick

import qs.Components.AiUsage
import qs.Components.Battery
import qs.Components.Clock
import qs.Components.DoNotDisturb
import qs.Components.Flashgen
import qs.Components.IdleInhibit
import qs.Components.Language
import qs.Components.Media
import qs.Components.SystemTray
import qs.Components.Volume
import qs.Components.Workspaces
import qs.Shared

Item {
    id: bar
    required property var screen

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

    Row {
        id: centerItems
        anchors.centerIn: parent
        spacing: 4

        Media {
            id: media
            popupCenterX: centerItems.x + media.x + media.width / 2
            screen: bar.screen
            anchors.verticalCenter: parent.verticalCenter
        }

        Clock {
            id: clock
            anchors.verticalCenter: parent.verticalCenter
        }
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
