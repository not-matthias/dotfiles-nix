import QtQuick
import qs.Services
import qs.Shared

BarButton {
    text: Niri.language
    tooltipText: Niri.language === "en" ? "English (US)" : Niri.language === "de" ? "German" : Niri.language
    foreground: Niri.language === "" ? Theme.muted : Theme.foreground
    background: "transparent"
    borderColor: "transparent"
    interactive: false
}
