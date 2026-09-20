import QtQuick

import qs.Shared

Item {
    id: root

    default property alias content: contentRow.data

    implicitWidth: contentRow.childrenRect.width + 8
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
        anchors.margins: 2
        spacing: 0
    }
}
