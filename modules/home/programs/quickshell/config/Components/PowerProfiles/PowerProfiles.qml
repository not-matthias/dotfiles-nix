import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Services as Services
import qs.Shared

BarButton {
    id: root

    required property var screen
    required property real popupCenterX
    readonly property int popupMargin: 8
    property bool popupOpen: false

    readonly property var profiles: Services.PowerProfiles
    readonly property var fan: profiles.fan
    readonly property var cpu: profiles.cpu

    // Material Design speedometer-slow/medium/speedometer, picked by how
    // aggressive the loudest of both settings is.
    readonly property var levelIcons: [0xf0f86, 0xf0f85, 0xf04c5]

    function levelOf(options, current) {
        const index = options.indexOf(current);
        if (index < 0 || options.length < 2)
            return 0;
        return Math.round((index / (options.length - 1)) * (root.levelIcons.length - 1));
    }

    function fanSummary() {
        if (!root.fan.available)
            return "";
        const speed = root.fan.speed ?? 0;
        const temperature = Math.round(root.fan.temperature ?? 0);
        return `${root.fan.strategy ?? "unknown"} · ${speed}% at ${temperature}°C`;
    }

    function cpuSummary() {
        if (!root.cpu.available)
            return "";
        const supply = root.cpu.onAc ? "AC" : "battery";
        return `${root.cpu.mode ?? "auto"} · ${root.cpu.governor ?? ""} on ${supply}`;
    }

    readonly property int level: Math.max(root.levelOf(profiles.fanStrategies, root.fan.strategy ?? ""), root.levelOf(profiles.cpuModes, root.cpu.mode ?? ""))

    visible: fan.available || cpu.available
    text: String.fromCodePoint(root.levelIcons[root.level])
    tooltipText: [root.fanSummary(), root.cpuSummary()].filter(part => part.length > 0).join("  ·  ")
    foreground: root.level === 0 ? Theme.muted : root.level >= root.levelIcons.length - 1 ? Theme.warning : Theme.foreground
    background: "transparent"
    borderColor: "transparent"

    onClicked: function (button) {
        if (button === Qt.LeftButton)
            root.popupOpen = !root.popupOpen;
    }

    component SectionLabel: Text {
        color: Theme.foreground
        font.family: "sans-serif"
        font.pixelSize: Theme.fontSize + 1
        font.bold: true
    }

    component SectionDetail: Text {
        color: Theme.muted
        font.family: "sans-serif"
        font.pixelSize: Theme.fontSize
        elide: Text.ElideRight
    }

    component OptionRow: Row {
        id: optionRow

        required property var options
        required property string current
        readonly property int columns: options.length

        signal selected(string value)

        spacing: 8

        Repeater {
            model: optionRow.options

            delegate: BarButton {
                required property string modelData
                readonly property bool active: modelData === optionRow.current

                width: (optionRow.width - (optionRow.columns - 1) * optionRow.spacing) / optionRow.columns
                text: modelData
                tooltipText: modelData
                fontFamily: "sans-serif"
                foreground: active ? Theme.accent : Theme.foreground
                background: Theme.pillBackground
                borderColor: active ? Theme.accent : Theme.border
                interactive: !root.profiles.busy

                onClicked: function (button) {
                    if (button === Qt.LeftButton)
                        optionRow.selected(modelData);
                }
            }
        }
    }

    PanelWindow {
        id: profilesPopup

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

            width: Math.min(340, profilesPopup.width - 2 * root.popupMargin)
            height: content.implicitHeight + 32
            x: Math.max(root.popupMargin, Math.min(root.popupCenterX - width / 2, profilesPopup.width - width - root.popupMargin))
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
                spacing: 8

                SectionLabel {
                    visible: root.fan.available
                    text: "Fan"
                }

                SectionDetail {
                    width: parent.width
                    visible: root.fan.available
                    text: root.fanSummary()
                }

                OptionRow {
                    width: parent.width
                    visible: root.fan.available
                    options: root.profiles.fanStrategies
                    current: root.fan.strategy ?? ""
                    onSelected: value => root.profiles.setFan(value)
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    visible: root.fan.available && root.cpu.available
                    color: Theme.border
                }

                SectionLabel {
                    visible: root.cpu.available
                    text: "CPU"
                }

                SectionDetail {
                    width: parent.width
                    visible: root.cpu.available
                    text: root.cpuSummary()
                }

                OptionRow {
                    width: parent.width
                    visible: root.cpu.available
                    options: root.profiles.cpuModes
                    current: root.cpu.mode ?? ""
                    onSelected: value => root.profiles.setCpu(value)
                }
            }
        }
    }
}
