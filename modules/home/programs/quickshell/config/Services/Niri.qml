pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Shared

Singleton {
    id: root

    property var allWorkspaces: []
    property var allWindows: []
    property var keyboardLayouts: ({
            names: [],
            current_idx: 0
        })

    readonly property var workspaces: allWorkspaces.filter(ws => ws.name !== null).sort((a, b) => a.idx - b.idx)
    readonly property var focusedWorkspace: allWorkspaces.find(ws => ws.is_focused) || allWorkspaces.find(ws => ws.is_active) || allWorkspaces[0]
    readonly property var windows: allWindows.filter(win => win.workspace_id === focusedWorkspace?.id && !win.is_floating).sort((a, b) => a.position - b.position)
    readonly property string language: {
        const name = keyboardLayouts.names[keyboardLayouts.current_idx] || "";
        return name === "English (US)" ? "en" : name === "German" ? "de" : name;
    }

    Process {
        id: stateProcess

        command: [Commands.niri, "msg", "--json", "event-stream"]
        running: true

        stdout: SplitParser {
            splitMarker: "\n"

            onRead: function (line) {
                root.consume(line);
            }
        }

        onRunningChanged: {
            if (running)
                retryTimer.stop();
            else
                retryTimer.restart();
        }
    }

    Timer {
        id: retryTimer
        interval: 1000
        repeat: false
        onTriggered: stateProcess.running = true
    }

    function consume(line) {
        try {
            applyEvent(JSON.parse(line));
        } catch (error) {
            console.error("Failed to apply Niri event:", error);
        }
    }

    function windowState(win) {
        return {
            id: win.id,
            workspace_id: win.workspace_id,
            is_focused: win.is_focused,
            is_floating: win.is_floating,
            position: win.layout.pos_in_scrolling_layout?.[0] || 0
        };
    }

    function applyEvent(event) {
        if (event.WorkspacesChanged) {
            allWorkspaces = event.WorkspacesChanged.workspaces;
        } else if (event.WorkspaceActivated) {
            const activated = event.WorkspaceActivated;
            const output = allWorkspaces.find(ws => ws.id === activated.id).output;
            for (const ws of allWorkspaces) {
                if (ws.output === output)
                    ws.is_active = ws.id === activated.id;
                if (activated.focused)
                    ws.is_focused = ws.id === activated.id;
            }
            allWorkspacesChanged();
        } else if (event.WorkspaceUrgencyChanged) {
            const urgency = event.WorkspaceUrgencyChanged;
            const ws = allWorkspaces.find(ws => ws.id === urgency.id);
            if (ws) {
                ws.is_urgent = urgency.urgent;
                allWorkspacesChanged();
            }
        } else if (event.WindowsChanged) {
            allWindows = event.WindowsChanged.windows.map(windowState);
        } else if (event.WindowOpenedOrChanged) {
            const next = windowState(event.WindowOpenedOrChanged.window);
            const index = allWindows.findIndex(win => win.id === next.id);
            const previous = allWindows[index];
            if (previous && previous.workspace_id === next.workspace_id && previous.is_focused === next.is_focused && previous.is_floating === next.is_floating && previous.position === next.position)
                return;
            if (next.is_focused) {
                for (const win of allWindows)
                    win.is_focused = false;
            }
            if (index === -1)
                allWindows.push(next);
            else
                allWindows[index] = next;
            allWindowsChanged();
        } else if (event.WindowClosed) {
            allWindows = allWindows.filter(win => win.id !== event.WindowClosed.id);
        } else if (event.WindowFocusChanged) {
            for (const win of allWindows)
                win.is_focused = win.id === event.WindowFocusChanged.id;
            allWindowsChanged();
        } else if (event.WindowLayoutsChanged) {
            let changed = false;
            for (const [id, layout] of event.WindowLayoutsChanged.changes) {
                const win = allWindows.find(win => win.id === id);
                const position = layout.pos_in_scrolling_layout?.[0] || 0;
                if (win && win.position !== position) {
                    win.position = position;
                    changed = true;
                }
            }
            if (changed)
                allWindowsChanged();
        } else if (event.KeyboardLayoutsChanged) {
            keyboardLayouts = event.KeyboardLayoutsChanged.keyboard_layouts;
        } else if (event.KeyboardLayoutSwitched) {
            keyboardLayouts.current_idx = event.KeyboardLayoutSwitched.idx;
            keyboardLayoutsChanged();
        }
    }
}
