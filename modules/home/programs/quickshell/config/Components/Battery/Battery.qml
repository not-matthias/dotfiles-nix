import QtQuick
import Quickshell.Services.UPower
import qs.Shared

BarButton {
    id: root

    readonly property var battery: UPower.displayDevice
    readonly property bool available: battery.ready && battery.isLaptopBattery && battery.isPresent
    readonly property int percentage: available ? Math.round(battery.percentage) : 0
    readonly property string batteryState: available ? UPowerDeviceState.toString(battery.state) : "Unknown"
    readonly property string batteryClass: {
        if (!available)
            return "unavailable";
        if (percentage < 15)
            return "critical";
        if (percentage < 30)
            return "warning";
        return "good";
    }

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
    tooltipText: available ? `Battery: ${percentage}% (${batteryState})` : "No battery"
    foreground: Theme.statusColor(batteryClass)
    background: "transparent"
    borderColor: "transparent"
    interactive: false
    visible: available
}
