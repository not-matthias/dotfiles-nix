pragma Singleton

import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property var players: Mpris.players.values.filter(player => root.hasMedia(player))
    readonly property var active: root.resolveActive()

    function resolveActive() {
        for (const player of players) {
            if (player.isPlaying)
                return player;
        }

        return players.length > 0 ? players[0] : null;
    }

    function hasMedia(player): bool {
        return player.isPlaying || player.trackTitle.length > 0;
    }

    function displayName(player): string {
        if (player === null)
            return "Media";

        return player.identity || player.desktopEntry || "Media";
    }
}
