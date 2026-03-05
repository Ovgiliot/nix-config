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
    // Apply alpha to a 6-digit hex color string.
    // Returns a proper QML color object via Qt.rgba() — not a string.
    // Returning a hex string ("#aarrggbb") does not reliably coerce to the
    // QML color type for readonly property color bindings in a Singleton on
    // Qt 6.10, leaving some properties permanently undefined. Qt.rgba()
    // returns a real QColor and makes sub-properties (.r/.g/.b) accessible.
    // Qt.color() from Qt 5 does not exist in Qt 6 and must never be used.
    function withAlpha(hex, alpha) {
        if (!hex || hex.length !== 7 || hex.charAt(0) !== "#")
            return Qt.rgba(0, 0, 0, alpha)
        const r = parseInt(hex[1] + hex[2], 16) / 255
        const g = parseInt(hex[3] + hex[4], 16) / 255
        const b = parseInt(hex[5] + hex[6], 16) / 255
        return Qt.rgba(r, g, b, alpha)
    }

    FileView {
        id: colorFile
        path: StandardPaths.writableLocation(StandardPaths.GenericCacheLocation) + "/matugen/qs-colors.json"

        JsonAdapter {
            id: colors
            // Neutral gray placeholders — visible for ~1 s on first boot until
            // the JSON file is polled. Replaced immediately by matugen output.
            property string pillBg:        "#404040"
            property string accent:        "#808080"
            property string barRed:        "#808080"
            property string barAmber:      "#606060"
            property string barGreen:      "#606060"
            property string warningBg:     "#505050"
            property string criticalBg:    "#707070"
            property string btConnected:   "#808080"
            property string powerPerf:     "#808080"
            property string powerSaver:    "#808080"
            property string powerBalanced: "#808080"
            property string langRu:        "#505050"
        }
    }

    // Raw-text watcher for change detection. No JsonAdapter child, so reload()
    // here does not disturb the parsed color properties.
    // onTextChanged fires AFTER the async read completes — the comparison is
    // done here so we never read .text synchronously right after reload()
    // (which would return stale/undefined content and defeat the comparison).
    FileView {
        id: colorFileCheck
        path: colorFile.path
        onTextChanged: {
            if (!text) return   // ignore empty: FileView may clear text before the async read completes
            if (text !== _lastColorText) {
                _lastColorText = text
                colorFile.reload()
            }
        }
    }

    property string _lastColorText: ""

    // Poll every second. colorFileCheck.onTextChanged handles the actual
    // comparison and only calls colorFile.reload() when content has changed.
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: colorFileCheck.reload()
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
