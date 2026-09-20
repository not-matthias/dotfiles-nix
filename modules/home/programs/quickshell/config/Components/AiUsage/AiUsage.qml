import QtQuick
import Quickshell.Io
import qs.Shared

PillGroup {
    id: root

    component UsageItem: BarButton {
        id: item

        required property string providerCommand
        required property string providerName
        required property string icon

        property var status: usagePoll.value || usagePoll.fallback
        text: status.text
        tooltipText: status.tooltip

        function stateClass(className) {
            if (className === "low")
                return "inactive";
            if (className === "mid")
                return "warning";
            return className;
        }

        foreground: Theme.statusColor(stateClass(status.class))
        background: "transparent"
        borderColor: "transparent"
        interactive: !restartProcess.running

        JsonPoll {
            id: usagePoll

            command: [item.providerCommand]
            interval: 600000
            fallback: ({
                    text: item.icon + " --",
                    tooltip: item.providerName + " usage unavailable",
                    class: "unavailable",
                    percentage: 0
                })
        }

        Process {
            id: restartProcess

            command: []
            onExited: usagePoll.refresh()
        }

        onClicked: function (button) {
            if (button === Qt.LeftButton || button === 0) {
                usagePoll.refresh();
            } else if (button === Qt.RightButton || button === 2 || button === 3) {
                restartProcess.command = [item.providerCommand, "--restart"];
                restartProcess.running = true;
            }
        }
    }

    UsageItem {
        providerName: "Claude Code"
        providerCommand: Commands.claudeUsage
        icon: "󰜡"
    }

    UsageItem {
        providerName: "Codex CLI"
        providerCommand: Commands.codexUsage
        icon: "󰚩"
    }

    UsageItem {
        providerName: "Google Antigravity"
        providerCommand: Commands.antigravityUsage
        icon: "󰛖"
    }
}
