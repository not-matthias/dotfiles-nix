import QtQuick
import QtQuick.Effects
import Quickshell
import qs.Services
import qs.Shared

Item {
    id: root
    required property var screen
    required property real popupCenterX
    readonly property int popupMargin: 8

    implicitWidth: mediaButton.implicitWidth
    implicitHeight: Theme.itemHeight

    property bool popupOpen: false
    readonly property var activePlayer: MediaManager.active
    readonly property string title: activePlayer !== null ? activePlayer.trackTitle || MediaManager.displayName(activePlayer) : "Media"
    readonly property string artist: activePlayer !== null ? activePlayer.trackArtist : ""

    visible: activePlayer !== null

    onVisibleChanged: {
        if (!visible)
            popupOpen = false;
    }

    BarButton {
        id: mediaButton

        text: "\uf001"
        tooltipText: root.artist.length > 0 ? root.title + " — " + root.artist : root.title
        foreground: Theme.foreground
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
            id: popupCards
            width: Math.min(392, Math.max(0, mediaPopup.width - 2 * root.popupMargin))
            x: Math.max(root.popupMargin, Math.min(root.popupCenterX - width / 2, mediaPopup.width - width - root.popupMargin))
            anchors.top: parent.top
            anchors.topMargin: root.popupMargin
            spacing: 8

            Repeater {
                model: MediaManager.players

                delegate: Item {
                    required property var modelData

                    width: popupCards.width
                    height: 172

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.AllButtons
                    }

                    MediaCard {
                        width: parent.width
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
