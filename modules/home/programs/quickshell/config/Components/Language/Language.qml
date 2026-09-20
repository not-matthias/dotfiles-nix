import QtQuick
import qs.Services
import qs.Shared

BarButton {
    text: Niri.language
    tooltipText: Niri.language === "en" ? "English (US)" : Niri.language === "de" ? "German" : Niri.language
    foreground: Theme.statusColor(Niri.language === "" ? "inactive" : "active")
    background: "transparent"
    borderColor: "transparent"
    interactive: false
}
