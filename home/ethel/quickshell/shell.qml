// Bar entry point: transparent layer-shell window + full layout.
// Layout uses QML anchors to achieve info-box fill between clock and right section —
// the feature that made Waybar unusable for this design.
// Compositor-agnostic: instantiates NiriIpc or HyprlandIpc based on environment.

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

ShellRoot {
    id: shellRoot

    // Detect compositor at startup via environment variable.
    property string _compositorType: ""

    // IPC object — assigned after compositor detection.
    property var compositorIpc: null

    Process {
        id: detectCompositor
        command: ["sh", "-c", "[ -n \"$NIRI_SOCKET\" ] && echo niri || ([ -n \"$HYPRLAND_INSTANCE_SIGNATURE\" ] && echo hyprland || echo unknown)"]
        stdout: StdioCollector {
            onStreamFinished: {
                shellRoot._compositorType = text.trim()
            }
        }
        Component.onCompleted: running = true
    }

    // Instantiate the correct IPC singleton based on compositor.
    NiriIpc {
        id: niriIpc
        Component.onCompleted: {
            if (shellRoot._compositorType === "" || shellRoot._compositorType === "niri") {
                shellRoot.compositorIpc = niriIpc
            }
        }
    }

    HyprlandIpc {
        id: hyprlandIpc
        Component.onCompleted: {
            if (shellRoot._compositorType === "hyprland") {
                shellRoot.compositorIpc = hyprlandIpc
            }
        }
    }

    // Re-evaluate IPC binding once compositor is detected (async).
    on_compositorTypeChanged: {
        if (_compositorType === "niri") {
            compositorIpc = niriIpc
        } else if (_compositorType === "hyprland") {
            compositorIpc = hyprlandIpc
        } else {
            // Fallback to niri
            compositorIpc = niriIpc
        }
    }

    // Single system stats + power-profile poller — owns both poll processes.
    // CpuMem, InfoBox, and StatusIcons bind to its reactive properties.
    StatusPoller { id: statusPoller }

    // Single WiFi monitor — owns the long-running wifi-monitor process.
    // StatusIcons binds to its reactive wifiState property.
    WifiMonitor { id: wifiMonitor }

    // Wallpaper picker overlay — visibility driven by ~/.cache/qs-wallpaper-open.
    // Toggle externally with toggle-wallpaper-picker (Mod+Shift+W).
    WallpaperPicker {}

    // Audio visualizer — layer-shell panel on Bottom layer (below all windows).
    // Visibility driven by ~/.cache/qs-visualizer-show.
    // Toggle externally with toggle-visualizer (Mod+Ctrl+G).
    AudioVisualizer {}

    PanelWindow {
        id: bar

        anchors {
            top: true
            left: true
            right: true
        }
        // Window is taller than the bar so MultiEffect shadows can render below the pills.
        // exclusiveZone stays at 24 — compositor only reserves 24px; the extra 20px overlap
        // the desktop transparently and carry the drop shadows.
        implicitHeight: 44
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.exclusiveZone: 24
        WlrLayershell.namespace: "bar"

        Item {
            width: parent.width
            height: 24

            // ── LEFT: CpuMem + Workspaces ───────────────────────────────────
            Row {
                id: leftSection
                anchors.left: parent.left
                anchors.leftMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                CpuMem {
                    cpuPct: statusPoller.cpuPct
                    memPct: statusPoller.memPct
                }
                Workspaces { workspaceModel: shellRoot.compositorIpc ? shellRoot.compositorIpc.workspaces : [] }
            }

            // ── CENTER: Clock ────────────────────────────────────────────────
            Clock {
                id: clockWidget
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
            }

            // ── COLUMNS: left of clock, grows left ──────────────────────────
            Columns {
                id: columnsWidget
                columnModel: shellRoot.compositorIpc ? shellRoot.compositorIpc.columns : []
                anchors.right: clockWidget.left
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
            }

            // ── INFO BOX: fills gap between clock and right section ──────────
            // anchors.left = clock.right  +  anchors.right = rightSection.left
            // makes this widget span exactly the remaining space on any resolution.
            InfoBox {
                anchors.left:        clockWidget.right
                anchors.leftMargin:  6
                anchors.right:       rightSection.left
                anchors.rightMargin: 6
                anchors.top:         parent.top
                anchors.bottom:      parent.bottom

                warningText:  statusPoller.warningText
                warningClass: statusPoller.warningClass
            }

            // ── RIGHT: Language + StatusIcons ────────────────────────────────
            Row {
                id: rightSection
                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Language {
                    langText:  shellRoot.compositorIpc ? shellRoot.compositorIpc.languageText : "EN"
                    langClass: shellRoot.compositorIpc ? shellRoot.compositorIpc.languageClass : "en"
                }
                StatusIcons {
                    wifiState:    wifiMonitor.wifiState
                    powerState:   statusPoller.powerState
                    parentWindow: bar
                }
            }
        }
    }

}
