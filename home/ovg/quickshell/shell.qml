// Bar entry point: transparent layer-shell window + full layout.
// Layout uses QML anchors to achieve info-box fill between clock and right section —
// the feature that made Waybar unusable for this design.

import Quickshell
import Quickshell.Wayland
import QtQuick

ShellRoot {
    // Single Niri IPC object — owns the one EventStream socket for the whole bar.
    // Workspaces and Language bind to its reactive properties.
    NiriIpc { id: niriIpc }

    // Single system stats + power-profile poller — owns both poll processes.
    // CpuMem, InfoBox, and StatusIcons bind to its reactive properties.
    StatusPoller { id: statusPoller }

    // Single WiFi monitor — owns the long-running wifi-monitor process.
    // StatusIcons binds to its reactive wifiState property.
    WifiMonitor { id: wifiMonitor }

    PanelWindow {
        id: bar

        anchors {
            top: true
            left: true
            right: true
        }
        // Window is taller than the bar so MultiEffect shadows can render below the pills.
        // exclusiveZone stays at 24 — Niri only reserves 24px; the extra 20px overlap the
        // desktop transparently and carry the drop shadows.
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
                Workspaces { workspaceModel: niriIpc.workspaces }
            }

            // ── CENTER: Clock ────────────────────────────────────────────────
            Clock {
                id: clockWidget
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
            }

            // ── INFO BOX: fills gap between clock and right section ──────────
            // anchors.left = clock.right  +  anchors.right = rightSection.left
            // makes this widget span exactly the remaining space on any resolution.
            InfoBox {
                anchors.left:        clockWidget.right
                anchors.leftMargin:  3
                anchors.right:       rightSection.left
                anchors.rightMargin: 3
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
                    langText:  niriIpc.languageText
                    langClass: niriIpc.languageClass
                }
                StatusIcons {
                    wifiState:  wifiMonitor.wifiState
                    powerState: statusPoller.powerState
                }
            }
        }
    }

    WallpaperPicker {}
}
