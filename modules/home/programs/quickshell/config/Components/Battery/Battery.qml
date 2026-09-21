import QtQuick
import qs.Shared

BarButton {
    id: root

    readonly property int percentage: statusPoll.value.percentage
    function iconForPercentage() {
        if (percentage < 15)
            return "\uf244";
        if (percentage < 30)
            return "\uf243";
        if (percentage < 60)
            return "\uf242";
        if (percentage < 90)
            return "\uf241";
        return "\uf240";
    }

    text: iconForPercentage()
    tooltipText: statusPoll.value.tooltip
    foreground: Theme.statusColor(statusPoll.value.class)
    background: "transparent"
    borderColor: "transparent"
    interactive: false
    visible: statusPoll.value.available

    JsonPoll {
        id: statusPoll

        command: Commands.batteryStatus
        interval: 60_000
        fallback: ({
                available: false,
                tooltip: "No battery",
                class: "unavailable",
                percentage: 0
            })
    }
}
