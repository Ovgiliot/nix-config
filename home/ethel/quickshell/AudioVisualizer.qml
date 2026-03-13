// Audio spectrum visualizer — layer-shell panel on the Bottom layer.
//
// Runs cava (Console Audio Visualizer) as a subprocess for FFT data.
// Bars are rendered natively in QML — no GLava/X11 dependency.
//
// Layer: Bottom (above wallpaper, below all windows).
// Sticky: inherent — layer-shell surfaces are not workspace-managed.
// Height: 50% of screen.
//
// Visibility driven by ~/.cache/qs-visualizer-show (JSON: {"show": true/false}).
// Default: visible. Toggle: Mod+Ctrl+G → toggle-visualizer.
//
// Bar count is dynamic: floor(width / (barWidth + barGap)). Cava is restarted
// when the count changes (rare — only on monitor plug/unplug).
//
// Colors: height-based gradient from surface_container_lowest (quiet) to
// surface_container (loud), live-reloaded via Colors singleton.

import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtCore
import QtQuick

PanelWindow {
    id: root

    // ── Bar geometry ─────────────────────────────────────────────────────────
    readonly property int barWidth: 6
    readonly property int barGap: 3
    readonly property int barCount: Math.max(1, Math.floor(width / (barWidth + barGap)))
    readonly property real maxBarHeight: height

    // ── Bar data from cava ───────────────────────────────────────────────────
    property var barValues: []

    // ── Layer-shell geometry ─────────────────────────────────────────────────
    anchors {
        bottom: true
        left:   true
        right:  true
    }
    implicitHeight: screen.height * 0.4
    color: "transparent"

    WlrLayershell.layer:         WlrLayer.Bottom
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.namespace:     "visualizer"

    visible: true

    // ── Flag file: {"show": true/false} ──────────────────────────────────────
    // Default visible — if the file does not exist, flagData.show stays true.
    FileView {
        id: flagFile
        path:         StandardPaths.writableLocation(StandardPaths.GenericCacheLocation)
                      + "/qs-visualizer-show"
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: flagData
            property bool show: true
        }
    }

    Binding { target: root; property: "visible"; value: flagData.show }

    // ── Cava process ─────────────────────────────────────────────────────────
    // _activeBarCount collapses to 0 when hidden, stopping cava (no wasted CPU).
    // When bar count changes (resize) or visibility toggles, cava restarts.
    property int _activeBarCount: visible ? barCount : 0

    Process {
        id: cavaProc
        command: root._activeBarCount > 0
                 ? [Scripts.cavaWrapper, root._activeBarCount.toString()]
                 : ["sh", "-c", "true"]
        running: root._activeBarCount > 0

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (line) => {
                const parts = line.split(";")
                const vals = new Array(parts.length)
                for (let i = 0; i < parts.length; i++) {
                    const n = parseInt(parts[i])
                    vals[i] = isNaN(n) ? 0 : n
                }
                root.barValues = vals
            }
        }

        onExited: (exitCode, exitStatus) => {
            // Restart with backoff if still supposed to be running.
            if (root._activeBarCount > 0) _restartTimer.start()
        }
    }

    Timer {
        id: _restartTimer
        interval: 2000
        repeat:   false
        onTriggered: {
            if (root._activeBarCount > 0 && !cavaProc.running)
                cavaProc.running = true
        }
    }

    on_ActiveBarCountChanged: {
        if (cavaProc.running) cavaProc.running = false
        root.barValues = []
        if (_activeBarCount > 0) _restartTimer.start()
    }

    // ── Color interpolation ──────────────────────────────────────────────────
    function lerpColor(c1, c2, t) {
        return Qt.rgba(
            c1.r + (c2.r - c1.r) * t,
            c1.g + (c2.g - c1.g) * t,
            c1.b + (c2.b - c1.b) * t,
            0.8
        )
    }

    // ── Bar rendering ────────────────────────────────────────────────────────
    // Row of fixed-width columns; each contains a Rectangle that grows upward
    // from the bottom, colored by amplitude.
    Row {
        id: barRow
        anchors.bottom:           parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        height:                   parent.height
        spacing:                  root.barGap

        Repeater {
            model: root.barValues.length

            Item {
                required property int index
                width:  root.barWidth
                height: barRow.height

                Rectangle {
                    width: parent.width
                    property real targetHeight: {
                        const v = root.barValues[index] || 0
                        return v / 1000.0 * root.maxBarHeight
                    }
                    height: targetHeight
                    anchors.bottom: parent.bottom
                    color: root.lerpColor(
                        Colors.vizColorLow,
                        Colors.vizColorHigh,
                        Math.min(1.0, targetHeight / root.maxBarHeight)
                    )

                    Behavior on height {
                        NumberAnimation { duration: 50 }
                    }
                }
            }
        }
    }
}
