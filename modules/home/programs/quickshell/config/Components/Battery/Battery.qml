import QtQuick
import qs.Shared

BarButton {
    id: root

    text: statusPoll.value.text
    tooltipText: statusPoll.value.tooltip
    foreground: Theme.statusColor(statusPoll.value.class)
    background: "transparent"
    borderColor: "transparent"
    interactive: false
    visible: text !== ""

    JsonPoll {
        id: statusPoll

        command: Commands.batteryStatus
        interval: 60_000
        fallback: ({
                text: "",
                tooltip: "No battery",
                class: "unavailable",
                percentage: 0
            })
    }
}
