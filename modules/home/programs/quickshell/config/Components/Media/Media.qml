import QtQuick
import QtQuick.Effects
import Quickshell
import qs.Services
import qs.Shared

PillGroup {
    id: root
    required property var screen
    required property real popupCenterX

    property bool popupOpen: false
    readonly property var activePlayer: MediaManager.active
    readonly property string title: activePlayer !== null ? activePlayer.trackTitle || MediaManager.displayName(activePlayer) : "Media"
    readonly property string artist: activePlayer !== null ? activePlayer.trackArtist : ""

    visible: activePlayer !== null

    onVisibleChanged: {
        if (!visible)
            popupOpen = false;
    }

    TextMetrics {
        id: titleMetrics

        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        text: "\uf001  " + root.title
    }

    BarButton {
        id: mediaButton

        implicitWidth: Math.min(180, titleMetrics.advanceWidth + 16)
        text: "\uf001  " + root.title
        tooltipText: root.artist.length > 0 ? root.title + " — " + root.artist : root.title
        foreground: Theme.barText
        background: "transparent"
        borderColor: "transparent"
        onClicked: function (button) {
            if (button === Qt.LeftButton)
                root.popupOpen = !root.popupOpen;
        }
    }

    PanelWindow {
        id: mediaPopup

        screen: root.screen
        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true
        exclusiveZone: 0
        aboveWindows: true
        color: "transparent"
        visible: root.popupOpen && root.activePlayer !== null

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: root.popupOpen = false
        }

        Column {
            x: root.popupCenterX - width / 2
            anchors.top: parent.top
            anchors.topMargin: Theme.barHeight + 8
            spacing: 8

            Repeater {
                model: MediaManager.players

                delegate: Item {
                    required property var modelData

                    width: 392
                    height: 172

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.AllButtons
                    }

                    MediaCard {
                        player: modelData
                        popupVisible: mediaPopup.visible
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowColor: "black"
                            shadowOpacity: 0.45
                            shadowBlur: 1
                            blurMax: 12
                            shadowVerticalOffset: 4
                        }
                    }
                }
            }
        }
    }
}
