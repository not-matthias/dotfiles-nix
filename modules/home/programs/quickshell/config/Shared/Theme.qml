pragma Singleton

import QtQuick

QtObject {
    readonly property color barBackground: "#d90f1115"
    readonly property color pillBackground: "#e6151922"
    readonly property color hoverBackground: "#ff1d2330"
    readonly property color foreground: "#fff0f3f6"
    readonly property color muted: "#99f0f3f6"
    readonly property color border: "#20f0f3f6"
    readonly property color accent: "#ffff6b7a"
    readonly property color warning: "#ffff9f68"
    readonly property color barText: foreground
    readonly property int barHeight: 42
    readonly property int pillHeight: 34
    readonly property int itemHeight: 30
    readonly property int pillRadius: 17
    readonly property int itemRadius: 8
    readonly property string fontFamily: "JetBrains Mono Nerd Font"
    readonly property int fontSize: 12

    function statusColor(className) {
        switch (className) {
        case "active":
        case "focused":
        case "volume":
        case "high":
        case "critical":
            return accent;
        case "warning":
        case "urgent":
        case "mid":
        case "muted":
            return warning;
        case "inactive":
        case "unavailable":
            return muted;
        default:
            return foreground;
        }
    }
}
