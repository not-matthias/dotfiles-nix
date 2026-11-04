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

        PillGroup {
            visible: flashgen.statusText.length > 0
            Flashgen {
                id: flashgen
            }
        }
        AiUsage {}

        PillGroup {
            IdleInhibit {}
            DoNotDisturb {}
        }

        PillGroup {
            id: controls
            Language {}
            Media {
                id: media
                screen: bar.screen
                popupCenterX: rightItems.x + controls.x + media.parent.x + media.x + media.width / 2
            }
            Volume {}
            Battery {}
        }

        SystemTray {
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
