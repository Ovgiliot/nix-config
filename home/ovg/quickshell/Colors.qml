// Dynamic color singleton driven by ~/.cache/matugen/qs-colors.json.
// A 1-second timer polls for changes but only calls reload() when the file
// content has actually changed. This avoids the JsonAdapter property-reset
// churn that caused "Unable to assign [undefined] to QColor" errors every
// second. A separate FileView (no JsonAdapter) reads the raw text for
// comparison so the parsed properties are never disturbed unnecessarily.
// Polling is used instead of watchChanges because matugen's atomic rename
// (temp-file + rename) replaces the inode and silently drops inotify watches.

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

    // Raw-text watcher for change detection. No JsonAdapter child, so reload()
    // here does not disturb the parsed color properties.
    FileView {
        id: colorFileCheck
        path: colorFile.path
    }

    property string _lastColorText: ""

    // Poll every second. Only forward to the JsonAdapter (via colorFile.reload())
    // when the file text has actually changed. This prevents the 1-second
    // property-reset churn that caused transient undefined QColor errors.
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            colorFileCheck.reload()
            const t = colorFileCheck.text
            if (t !== _lastColorText) {
                _lastColorText = t
                colorFile.reload()
            }
        }
    }

    // Pill backgrounds: 80% opacity
    readonly property color pillBg:        withAlpha(colors.pillBg, 0.8)
    // Bar track: same hue as pill, fully opaque
    readonly property color barTrack:      withAlpha(colors.pillBg, 1.0)
    // Accent: workspace dot, fully opaque
    readonly property color accent:        withAlpha(colors.accent, 1.0)
    // Bar fills: 90% opacity
    readonly property color barRed:        withAlpha(colors.barRed, 0.9)
    readonly property color barAmber:      withAlpha(colors.barAmber, 0.9)
    readonly property color barGreen:      withAlpha(colors.barGreen, 0.9)
    // Status pill warning/critical
    readonly property color warningBg:     withAlpha(colors.warningBg, 0.8)
    readonly property color criticalBg:    withAlpha(colors.criticalBg, 1.0)
    // Icon tints
    readonly property color btConnected:   withAlpha(colors.btConnected, 1.0)
    readonly property color powerPerf:     withAlpha(colors.powerPerf, 1.0)
    readonly property color powerSaver:    withAlpha(colors.powerSaver, 1.0)
    readonly property color powerBalanced: withAlpha(colors.powerBalanced, 1.0)
    // Language pill RU: 80% opacity
    readonly property color langRu:        withAlpha(colors.langRu, 0.8)
}
