// Dynamic color singleton driven by ~/.cache/matugen/qs-colors.json.
// Colors are polled every second: simpler and immune to the inotify watch
// loss caused by matugen's atomic rename (temp-file + rename replaces the
// inode, which silently drops QFileSystemWatcher's existing watch).

import Quickshell
import Quickshell.Io
import QtCore
import QtQuick

Singleton {
    // Helper: apply alpha to a hex color string.
    // Guard against empty/invalid hex during a partial JSON reload so that
    // property bindings don't propagate undefined and break downstream QColor
    // assignments (observed as "Unable to assign [undefined] to QColor").
    function withAlpha(hex, alpha) {
        if (!hex || hex.charAt(0) !== "#") return Qt.rgba(0, 0, 0, alpha)
        const c = Qt.color(hex)
        if (!c || !c.valid) return Qt.rgba(0, 0, 0, alpha)
        return Qt.rgba(c.r, c.g, c.b, alpha)
    }

    FileView {
        id: colorFile
        path: StandardPaths.writableLocation(StandardPaths.GenericCacheLocation) + "/matugen/qs-colors.json"

        JsonAdapter {
            id: colors
            // Defaults: Space Cat wallpaper (--mode dark --type scheme-content)
            property string pillBg:        "#474854"
            property string accent:        "#c0c5e4"
            property string barRed:        "#ffb4ab"
            property string barAmber:      "#816278"
            property string barGreen:      "#656a86"
            property string warningBg:     "#816278"
            property string criticalBg:    "#ffb4ab"
            property string btConnected:   "#c0c5e4"
            property string powerPerf:     "#ffb4ab"
            property string powerSaver:    "#c5c5d3"
            property string powerBalanced: "#c0c5e4"
            property string langRu:        "#656a86"
        }
    }

    // Poll every second. This avoids relying on inotify watches which break
    // when matugen atomically replaces the file via rename().
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: colorFile.reload()
    }

    // Pill backgrounds: 80% opacity
    readonly property color pillBg:        withAlpha(colors.pillBg, 0.8)
    // Bar track: same hue as pill, fully opaque
    readonly property color barTrack:      withAlpha(colors.pillBg, 1.0)
    // Accent: workspace dot, fully opaque
    readonly property color accent:        Qt.color(colors.accent)
    // Bar fills: 90% opacity
    readonly property color barRed:        withAlpha(colors.barRed, 0.9)
    readonly property color barAmber:      withAlpha(colors.barAmber, 0.9)
    readonly property color barGreen:      withAlpha(colors.barGreen, 0.9)
    // Status pill warning/critical
    readonly property color warningBg:     withAlpha(colors.warningBg, 0.8)
    readonly property color criticalBg:    Qt.color(colors.criticalBg)
    // Icon tints
    readonly property color btConnected:   Qt.color(colors.btConnected)
    readonly property color powerPerf:     Qt.color(colors.powerPerf)
    readonly property color powerSaver:    Qt.color(colors.powerSaver)
    readonly property color powerBalanced: Qt.color(colors.powerBalanced)
    // Language pill RU: 80% opacity
    readonly property color langRu:        withAlpha(colors.langRu, 0.8)
}
