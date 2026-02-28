// Bar entry point: transparent layer-shell window + full layout.
// Layout uses QML anchors to achieve info-box fill between clock and right section —
// the feature that made Waybar unusable for this design.

import Quickshell
import Quickshell.Wayland
import QtQuick

ShellRoot {
    PanelWindow {
        id: bar

        anchors {
            top: true
            left: true
            right: true
        }
        height: 24
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.exclusiveZone: 24
        WlrLayershell.namespace: "bar"

        Item {
            anchors.fill: parent

            // ── LEFT: CpuMem + Workspaces ───────────────────────────────────
            Row {
                id: leftSection
                anchors.left: parent.left
                anchors.leftMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                CpuMem {}
                Workspaces {}
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
            }

            // ── RIGHT: Language + StatusIcons ────────────────────────────────
            Row {
                id: rightSection
                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Language {}
                StatusIcons {}
            }
        }
    }
}
