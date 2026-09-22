import QtQuick
import QtQuick.Effects
import Quickshell.Services.Mpris
import qs.Services
import qs.Shared

Item {
    id: root

    required property var player
    required property bool popupVisible

    readonly property string title: player !== null ? player.trackTitle || "Unknown title" : "Unknown title"
    readonly property string artist: player !== null ? player.trackArtist || "Unknown artist" : "Unknown artist"
    readonly property bool canSeekPosition: player !== null && player.canSeek && player.positionSupported && player.length > 0
    property real currentPosition: 0
    property real progress: 0

    width: 392
    height: 172

    onPlayerChanged: refreshPosition()
    onPopupVisibleChanged: refreshPosition()

    Connections {
        target: root.player
        enabled: root.player !== null

        function onPositionChanged() {
            root.refreshPosition();
        }

        function onLengthChanged() {
            root.refreshPosition();
        }
    }

    Timer {
        interval: 250
        repeat: true
        running: root.popupVisible && root.player !== null && root.player.positionSupported && root.player.isPlaying
        onTriggered: root.refreshPosition()
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Theme.barBackground
        border.width: 1
        border.color: Theme.border

        Item {
            id: artworkBlock

            width: 112
            height: 112
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                anchors.fill: parent
                radius: 12
                color: Theme.pillBackground

                Text {
                    anchors.centerIn: parent
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 34
                    text: "\uf001"
                }
            }

            Image {
                id: artworkSource

                anchors.fill: parent
                asynchronous: true
                fillMode: Image.PreserveAspectCrop
                source: root.player !== null ? root.player.trackArtUrl : ""
                visible: false
            }

            Rectangle {
                id: artworkMask

                anchors.fill: parent
                radius: 12
                visible: false
                layer.enabled: true
            }

            MultiEffect {
                anchors.fill: parent
                source: artworkSource
                maskEnabled: true
                maskSource: artworkMask
                visible: artworkSource.source.toString().length > 0 && artworkSource.status === Image.Ready
            }
        }

        Item {
            id: details

            anchors.left: artworkBlock.right
            anchors.leftMargin: 16
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.top: parent.top
            anchors.topMargin: 16
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16

            Item {
                id: metadata

                width: parent.width
                height: 48

                Column {
                    anchors.left: parent.left
                    anchors.right: playerButton.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        width: parent.width
                        color: Theme.foreground
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize + 1
                        font.bold: true
                        elide: Text.ElideRight
                        text: root.title
                    }

                    Text {
                        width: parent.width
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 1
                        elide: Text.ElideRight
                        text: root.artist
                    }
                }

                BarButton {
                    id: playerButton

                    width: 90
                    height: 26
                    anchors.right: parent.right
                    anchors.top: parent.top
                    text: MediaManager.displayName(root.player)
                    foreground: Theme.muted
                    background: Theme.pillBackground
                    borderColor: Theme.border
                    interactive: false
                }
            }

            Item {
                id: seekArea

                width: parent.width
                height: 12
                anchors.top: metadata.bottom
                anchors.topMargin: 12
                opacity: root.canSeekPosition ? 1 : 0.35

                Rectangle {
                    width: parent.width
                    height: 4
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 2
                    color: Theme.border
                }

                Rectangle {
                    width: parent.width * root.progress
                    height: 4
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 2
                    color: Theme.accent
                }

                Rectangle {
                    width: 8
                    height: 8
                    x: Math.max(0, Math.min(parent.width - width, parent.width * root.progress - width / 2))
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 4
                    color: Theme.accent
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: root.canSeekPosition
                    onPressed: function (mouse) {
                        root.seekTo(mouse.x, seekArea.width);
                    }
                    onPositionChanged: function (mouse) {
                        if (pressed)
                            root.seekTo(mouse.x, seekArea.width);
                    }
                }
            }

            Row {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8

                BarButton {
                    width: 28
                    height: 28
                    text: "\uf074"
                    tooltipText: "Toggle shuffle"
                    foreground: root.player !== null && root.player.shuffle ? Theme.accent : Theme.foreground
                    background: "transparent"
                    borderColor: "transparent"
                    interactive: root.player !== null && root.player.shuffleSupported && root.player.canControl
                    opacity: interactive ? 1 : 0.35
                    onClicked: function (button) {
                        if (button === Qt.LeftButton)
                            root.player.shuffle = !root.player.shuffle;
                    }
                }

                BarButton {
                    width: 28
                    height: 28
                    text: "\uf048"
                    tooltipText: "Previous track"
                    background: "transparent"
                    borderColor: "transparent"
                    interactive: root.player !== null && root.player.canGoPrevious
                    opacity: interactive ? 1 : 0.35
                    onClicked: function (button) {
                        if (button === Qt.LeftButton)
                            root.player.previous();
                    }
                }

                BarButton {
                    width: 36
                    height: 36
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.player !== null && root.player.isPlaying ? "\uf04c" : "\uf04b"
                    tooltipText: root.player !== null && root.player.isPlaying ? "Pause" : "Play"
                    foreground: Theme.barBackground
                    background: Theme.accent
                    borderColor: "transparent"
                    interactive: root.player !== null && root.player.canTogglePlaying
                    opacity: interactive ? 1 : 0.35
                    onClicked: function (button) {
                        if (button === Qt.LeftButton)
                            root.player.togglePlaying();
                    }
                }

                BarButton {
                    width: 28
                    height: 28
                    text: "\uf051"
                    tooltipText: "Next track"
                    background: "transparent"
                    borderColor: "transparent"
                    interactive: root.player !== null && root.player.canGoNext
                    opacity: interactive ? 1 : 0.35
                    onClicked: function (button) {
                        if (button === Qt.LeftButton)
                            root.player.next();
                    }
                }

                BarButton {
                    width: 28
                    height: 28
                    text: "\uf01e"
                    tooltipText: "Change repeat mode"
                    foreground: root.player !== null && root.player.loopState !== MprisLoopState.None ? Theme.accent : Theme.foreground
                    background: "transparent"
                    borderColor: "transparent"
                    interactive: root.player !== null && root.player.loopSupported && root.player.canControl
                    opacity: interactive ? 1 : 0.35
                    onClicked: function (button) {
                        if (button === Qt.LeftButton)
                            root.cycleLoopState();
                    }
                }
            }
        }
    }

    function refreshPosition() {
        if (player === null || !player.positionSupported) {
            currentPosition = 0;
            progress = 0;
            return;
        }

        currentPosition = Math.max(0, player.position);
        progress = player.length > 0 ? Math.max(0, Math.min(1, currentPosition / player.length)) : 0;
    }

    function seekTo(pointerX, trackWidth) {
        if (!canSeekPosition || trackWidth <= 0)
            return;

        const fraction = Math.max(0, Math.min(1, pointerX / trackWidth));
        currentPosition = fraction * player.length;
        progress = fraction;
        player.position = currentPosition;
    }

    function cycleLoopState() {
        if (player === null || !player.loopSupported || !player.canControl)
            return;

        switch (player.loopState) {
        case MprisLoopState.None:
            player.loopState = MprisLoopState.Playlist;
            break;
        case MprisLoopState.Playlist:
            player.loopState = MprisLoopState.Track;
            break;
        default:
            player.loopState = MprisLoopState.None;
        }
    }
}
