import QtQuick
import Quickshell
import qs.Shared

PopupWindow {
    id: root

    property Item anchorItem
    property string text: ""
    property bool hovered: false
    property int delay: 500
    property bool ready: false

    anchor.item: root.anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.bottom: 6
    anchor.adjustment: PopupAdjustment.Slide

    color: "transparent"
    surfaceFormat.opaque: false
    visible: root.ready && root.hovered && root.text.length > 0 && root.anchorItem !== null
    implicitWidth: tooltipLabel.implicitWidth + 16
    implicitHeight: tooltipLabel.implicitHeight + 8

    mask: Region {}

    function updateVisibility() {
        root.ready = false;
        delayTimer.stop();
        if (root.hovered && root.text.length > 0 && root.anchorItem !== null)
            delayTimer.start();
    }

    onHoveredChanged: root.updateVisibility()
    onTextChanged: root.updateVisibility()
    onAnchorItemChanged: root.updateVisibility()

    Timer {
        id: delayTimer
        interval: Math.max(0, root.delay)
        repeat: false
        onTriggered: root.ready = true
    }

    Rectangle {
        id: body
        anchors.fill: parent
        radius: Theme.itemRadius
        color: Theme.barBackground
        border.width: 1
        border.color: Theme.border

        Text {
            id: tooltipLabel
            anchors.centerIn: parent
            color: Theme.foreground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            text: root.text
        }
    }
}
