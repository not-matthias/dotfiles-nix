import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import qs.Shared

BarButton {
    id: root
    required property var screen
    required property real popupCenterX
    readonly property int popupMargin: 8
    property bool popupOpen: false
    property bool outputsOpen: false
    readonly property var outputs: Pipewire.nodes.values.filter(node => node.isSink && !node.isStream && node.audio !== null)

    onPopupOpenChanged: {
        if (!popupOpen)
            outputsOpen = false;
    }

    property var sink: Pipewire.defaultAudioSink
    readonly property bool ready: sink?.ready ?? false
    readonly property real volume: ready ? (sink.audio?.volume ?? 0) : 0
    readonly property bool muted: ready ? (sink.audio?.muted ?? false) : false
    readonly property int percentage: Math.round(volume * 100)

    text: !ready || muted ? "󰖁" : volume < 0.5 ? "\uf027" : "\uf028"
    tooltipText: !ready ? "Audio sink unavailable" : muted ? "Volume: muted" : `Volume: ${percentage}%`
    foreground: !ready ? Theme.muted : Theme.foreground
    background: "transparent"
    borderColor: "transparent"
    interactive: true

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    Process {
        id: pavucontrolProcess

        command: [Commands.pavucontrol]
    }

    function adjustVolume(steps) {
        if (steps === 0 || !sink?.audio)
            return;
        sink.audio.volume = Math.max(0, Math.min(1, volume + steps * 0.01));
    }

    onClicked: function (button) {
        if (button === Qt.LeftButton)
            popupOpen = !popupOpen;
    }
    onWheel: function (steps) {
        adjustVolume(steps);
    }

    PanelWindow {
        id: volumePopup

        screen: root.screen
        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true
        exclusiveZone: 0
        color: "transparent"
        visible: root.popupOpen
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.layer: WlrLayer.Overlay
        onVisibleChanged: {
            if (visible)
                panel.forceActiveFocus();
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: root.popupOpen = false
        }

        Rectangle {
            id: panel

            width: Math.min(368, volumePopup.width - 2 * root.popupMargin)
            height: content.implicitHeight + 32
            x: Math.max(root.popupMargin, Math.min(root.popupCenterX - width / 2, volumePopup.width - width - root.popupMargin))
            y: root.popupMargin
            radius: 12
            color: Theme.barBackground
            border.color: Theme.border
            focus: true
            Keys.onEscapePressed: root.popupOpen = false

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
            }

            Column {
                id: content
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 16
                spacing: 12

                Text {
                    text: "Sound"
                    color: Theme.foreground
                    font.family: "sans-serif"
                    font.pixelSize: Theme.fontSize + 1
                    font.bold: true
                }

                BarButton {
                    width: parent.width
                    text: (root.sink?.description || "No output device") + "  \uf107"
                    tooltipText: "Select audio output"
                    fontFamily: "sans-serif"
                    textAlignment: Text.AlignLeft
                    foreground: Theme.foreground
                    background: Theme.pillBackground
                    borderColor: Theme.border
                    onClicked: function (button) {
                        if (button === Qt.LeftButton)
                            root.outputsOpen = !root.outputsOpen;
                    }
                }

                ListView {
                    width: parent.width
                    height: Math.min(contentHeight, 160)
                    visible: root.outputsOpen
                    clip: true
                    model: root.outputs
                    spacing: 4

                    delegate: BarButton {
                        required property var modelData
                        width: ListView.view.width
                        text: modelData.description || modelData.name
                        tooltipText: text
                        fontFamily: "sans-serif"
                        textAlignment: Text.AlignLeft
                        foreground: modelData === root.sink ? Theme.accent : Theme.foreground
                        background: Theme.pillBackground
                        borderColor: "transparent"
                        onClicked: function (button) {
                            if (button !== Qt.LeftButton)
                                return;
                            Pipewire.preferredDefaultAudioSink = modelData;
                            root.outputsOpen = false;
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: 12

                    BarButton {
                        id: muteButton
                        width: Theme.itemHeight
                        fontFamily: "JetBrainsMono Nerd Font Propo"
                        text: root.muted ? "󰖁" : "\uf028"
                        tooltipText: root.muted ? "Unmute" : "Mute"
                        foreground: root.muted ? Theme.accent : Theme.foreground
                        background: Theme.pillBackground
                        borderColor: Theme.border
                        interactive: root.ready
                        onClicked: function (button) {
                            if (button === Qt.LeftButton && root.sink?.audio)
                                root.sink.audio.muted = !root.muted;
                        }
                    }

                    Slider {
                        id: volumeSlider
                        width: parent.width - muteButton.width - percentageLabel.width - 2 * parent.spacing
                        height: muteButton.height
                        from: 0
                        to: 1
                        stepSize: 0.01
                        value: root.volume
                        enabled: root.ready
                        onMoved: {
                            if (root.sink?.audio)
                                root.sink.audio.volume = value;
                        }
                        background: Rectangle {
                            x: volumeSlider.leftPadding
                            y: (volumeSlider.height - height) / 2
                            width: volumeSlider.availableWidth
                            height: 4
                            radius: 2
                            color: Theme.border
                            Rectangle {
                                width: volumeSlider.visualPosition * parent.width
                                height: parent.height
                                radius: parent.radius
                                color: Theme.accent
                            }
                        }
                        handle: Rectangle {
                            x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                            y: (volumeSlider.height - height) / 2
                            width: 12
                            height: 12
                            radius: 6
                            color: volumeSlider.enabled ? Theme.accent : Theme.muted
                        }
                    }

                    Text {
                        id: percentageLabel
                        width: 44
                        height: muteButton.height
                        text: root.percentage + "%"
                        color: Theme.foreground
                        font.family: "sans-serif"
                        font.pixelSize: Theme.fontSize
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignRight
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.border
                }

                BarButton {
                    width: parent.width
                    text: "Advanced audio settings  \uf08e"
                    fontFamily: "sans-serif"
                    textAlignment: Text.AlignLeft
                    foreground: Theme.muted
                    background: "transparent"
                    borderColor: "transparent"
                    onClicked: function (button) {
                        if (button !== Qt.LeftButton)
                            return;
                        root.popupOpen = false;
                        pavucontrolProcess.running = true;
                    }
                }
            }
        }
    }
}
