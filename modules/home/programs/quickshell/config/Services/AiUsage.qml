pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Shared

Singleton {
    id: root

    readonly property var claude: claudeState
    readonly property var codex: codexState
    readonly property var antigravity: antigravityState

    component Provider: QtObject {
        id: provider

        required property string providerName
        required property string providerIcon
        required property string providerCommand

        readonly property var fallback: ({
                text: providerIcon + " --",
                tooltip: providerName + " usage unavailable",
                class: "unavailable",
                percentage: 0
            })
        property var status: fallback
        readonly property bool busy: process.running

        function refresh() {
            if (process.running || providerCommand.length === 0)
                return;

            timer.stop();
            process.command = [providerCommand];
            process.running = true;
        }

        function restart() {
            if (process.running || providerCommand.length === 0)
                return;

            timer.stop();
            process.command = [providerCommand, "--restart"];
            process.running = true;
        }

        function consume(output) {
            try {
                const parsed = JSON.parse(output);
                if (parsed && typeof parsed.text === "string" && typeof parsed.tooltip === "string" && typeof parsed.class === "string")
                    status = parsed;
            } catch (error) {}
            timer.restart();

        }

        Process {
            id: process
            command: []

            stdout: StdioCollector {
                waitForEnd: true
                onStreamFinished: provider.consume(text)
            }

            onExited: timer.restart()
        }

        Timer {
            id: timer
            interval: 600000
            repeat: false
            onTriggered: provider.refresh()
        }

        Component.onCompleted: provider.refresh()
    }

    Provider {
        id: claudeState
        providerName: "Claude Code"
        providerIcon: "󰜡"
        providerCommand: Commands.claudeUsage
    }

    Provider {
        id: codexState
        providerName: "Codex CLI"
        providerIcon: "󰚩"
        providerCommand: Commands.codexUsage
    }

    Provider {
        id: antigravityState
        providerName: "Google Antigravity"
        providerIcon: "󰛖"
        providerCommand: Commands.antigravityUsage
    }
}
