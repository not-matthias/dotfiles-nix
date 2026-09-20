import QtQuick
import qs.Shared
import Quickshell

MouseArea {
    id: root

    required property var modelData
    readonly property string tooltipText: {
        const title = modelData.tooltipTitle || modelData.title || modelData.id || "";
        const description = modelData.tooltipDescription || "";
        if (!title)
            return description;
        if (!description)
            return title;
        return title + "\n" + description;
    }

    implicitWidth: 18
    implicitHeight: 18
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    cursorShape: Qt.PointingHandCursor

    function openMenu() {
        if (modelData.hasMenu)
            menuAnchor.open();
    }

    Image {
        anchors.fill: parent
        source: root.modelData.icon
        fillMode: Image.PreserveAspectFit
        smooth: true
    }

    QsMenuAnchor {
        id: menuAnchor

        menu: root.modelData.menu
        anchor.item: root
        anchor.edges: Edges.Bottom | Edges.Left
        anchor.gravity: Edges.Bottom | Edges.Right
    }
    Tooltip {
        anchorItem: root
        text: root.tooltipText
        hovered: root.containsMouse
    }

    onClicked: event => {
        switch (event.button) {
        case Qt.LeftButton:
            if (modelData.onlyMenu)
                openMenu();
            else
                modelData.activate();
            break;
        case Qt.RightButton:
            openMenu();
            break;
        case Qt.MiddleButton:
            modelData.secondaryActivate();
            break;
        }
        event.accepted = true;
    }

    onWheel: event => {
        const horizontal = Math.abs(event.angleDelta.x) > Math.abs(event.angleDelta.y);
        const delta = horizontal ? event.angleDelta.x : event.angleDelta.y;
        if (delta !== 0)
            modelData.scroll(delta, horizontal);
        event.accepted = true;
    }
}
