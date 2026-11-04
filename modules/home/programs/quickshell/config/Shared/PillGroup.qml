import QtQuick

import qs.Shared

Item {
    id: root

    default property alias content: contentRow.data
    readonly property int padding: 2

    implicitWidth: contentRow.childrenRect.width + 2 * padding
    implicitHeight: Theme.pillHeight

    Rectangle {
        anchors.fill: parent
        radius: Theme.pillRadius
        color: Theme.pillBackground
        border.width: 1
        border.color: Theme.border
    }

    Row {
        id: contentRow
        anchors.fill: parent
        anchors.margins: root.padding
        spacing: 0
    }
}
