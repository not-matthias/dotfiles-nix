import QtQuick
import qs.Services as Services
import qs.Shared

PillGroup {
    id: root

    component UsageItem: BarButton {
        id: item

        required property var provider

        property var status: item.provider.status
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
        interactive: !item.provider.busy

        onClicked: function (button) {
            if (button === Qt.LeftButton || button === 0) {
                item.provider.refresh();
            } else if (button === Qt.RightButton || button === 2 || button === 3) {
                item.provider.restart();
            }
        }
    }

    UsageItem {
        provider: Services.AiUsage.claude
    }

    UsageItem {
        provider: Services.AiUsage.codex
    }

    UsageItem {
        provider: Services.AiUsage.antigravity
    }
}
