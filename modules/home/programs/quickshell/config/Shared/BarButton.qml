import QtQuick

import qs.Shared

Item {
    id: root

    property string text: ""
    property string tooltipText: ""
    property color foreground: Theme.foreground
    property color background: Theme.pillBackground
    property color borderColor: Theme.border
    property bool interactive: true

    signal clicked(int button)
    signal wheel(int steps)

    property bool hovered: pointer.containsMouse

    implicitWidth: label.implicitWidth + 16
    implicitHeight: Theme.itemHeight

    Rectangle {
        anchors.fill: parent
        radius: Theme.itemRadius
        color: root.hovered && root.interactive ? Theme.hoverBackground : root.background
        border.width: 1
        border.color: root.borderColor
    }

    Text {
        id: label
        anchors.fill: parent
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: root.foreground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        text: root.text
        elide: Text.ElideRight
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: root.interactive ? Qt.AllButtons : Qt.NoButton
        onClicked: function (mouse) {
            root.clicked(mouse.button);
        }
        onWheel: function (wheel) {
            if (!root.interactive)
                return;
            var steps = Math.round(wheel.angleDelta.y / 120);
            if (steps === 0)
                steps = wheel.angleDelta.y > 0 ? 1 : -1;
            root.wheel(steps);
        }
    }
    Tooltip {
        anchorItem: root
        text: root.tooltipText
        hovered: root.hovered
    }
}
