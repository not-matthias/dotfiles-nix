import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Shared

PillGroup {
    id: root

    SystemClock {
        id: systemClock
        precision: SystemClock.Minutes
    }

    BarButton {
        id: clockButton
        text: Qt.formatDateTime(systemClock.date, "ddd dd MMM · HH:mm")
        tooltipText: "Open calendar"
        foreground: Theme.barText
        background: "transparent"
        borderColor: "transparent"
        onClicked: function (button) {
            if (button === Qt.LeftButton)
                calendarPopup.visible = !calendarPopup.visible;
        }
    }

    PopupWindow {
        id: calendarPopup

        anchor.item: clockButton
        anchor.edges: Edges.Bottom | Edges.Left
        anchor.gravity: Edges.Bottom | Edges.Left
        anchor.adjustment: PopupAdjustment.Slide
        color: Theme.barBackground
        implicitWidth: 296
        implicitHeight: 318

        Rectangle {
            anchors.fill: parent
            color: Theme.barBackground
            border.width: 1
            border.color: Theme.border
            radius: Theme.itemRadius

            Column {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 7

                Row {
                    width: parent.width
                    height: 30
                    spacing: 6

                    BarButton {
                        width: 30
                        height: 30
                        text: "‹"
                        foreground: Theme.accent
                        background: "transparent"
                        borderColor: "transparent"
                        tooltipText: "Previous month"
                        onClicked: function (button) {
                            if (button === Qt.LeftButton)
                                root.shiftMonth(-1);
                        }
                    }

                    Text {
                        width: parent.width - 72
                        height: parent.height
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        font.bold: true
                        text: root.monthTitle
                    }

                    BarButton {
                        width: 30
                        height: 30
                        text: "›"
                        foreground: Theme.accent
                        background: "transparent"
                        borderColor: "transparent"
                        tooltipText: "Next month"
                        onClicked: function (button) {
                            if (button === Qt.LeftButton)
                                root.shiftMonth(1);
                        }
                    }
                }

                DayOfWeekRow {
                    id: weekdays

                    width: parent.width
                    height: 20
                    locale: calendarGrid.locale
                    delegate: Text {
                        required property string shortName
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 1
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: shortName
                    }
                }

                MonthGrid {
                    id: calendarGrid

                    width: parent.width
                    height: parent.height - 65
                    month: root.displayMonth
                    year: root.displayYear
                    locale: Qt.locale()
                    delegate: Text {
                        required property var model
                        color: model.today ? Theme.accent : (model.month === calendarGrid.month ? Theme.foreground : Theme.muted)
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        font.bold: model.today
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        opacity: model.month === calendarGrid.month ? 1 : 0.55
                        text: model.day
                    }
                    onClicked: {
                        root.selectedDate = date;
                    }
                }
            }
        }
    }

    property int displayMonth: systemClock.date.getMonth()
    property int displayYear: systemClock.date.getFullYear()
    property date selectedDate: systemClock.date
    readonly property string monthTitle: Qt.formatDateTime(new Date(displayYear, displayMonth, 1), "MMMM yyyy")

    function shiftMonth(offset) {
        var next = new Date(displayYear, displayMonth + offset, 1);
        displayMonth = next.getMonth();
        displayYear = next.getFullYear();
    }
}
