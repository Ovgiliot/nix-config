// Dynamic color singleton driven by ~/.cache/matugen/qs-colors.json.
// A 1-second timer polls for content changes. JSON is parsed manually via
// JSON.parse() so there is no JsonAdapter involved — JsonAdapter caused
// "Unable to assign [undefined] to QColor" crashes every reload cycle, and
// the dual-FileView workaround around it introduced a starvation bug where
// colors would never load if the file was absent at startup.
// Polling is used instead of watchChanges because matugen uses an atomic
// rename (temp-file + rename) that replaces the inode and silently drops
// inotify watches.

import Quickshell
import Quickshell.Io
import QtCore
import QtQuick

Singleton {
    // Apply alpha to a 6-digit hex color string.
    // Returns a proper QML color object via Qt.rgba().
    function withAlpha(hex, alpha) {
        if (!hex || hex.length !== 7 || hex.charAt(0) !== "#")
            return Qt.rgba(0.25, 0.25, 0.25, alpha)
        const r = parseInt(hex[1] + hex[2], 16) / 255
        const g = parseInt(hex[3] + hex[4], 16) / 255
        const b = parseInt(hex[5] + hex[6], 16) / 255
        return Qt.rgba(r, g, b, alpha)
    }

    // ── Raw color strings from matugen (updated on each successful parse) ──────
    // Defaults are neutral grays — visible only until the first successful
    // poll of the cache file (typically within 1 second of startup).
    property string _pillBg:        "#404040"
    property string _accent:        "#808080"
    property string _barRed:        "#808080"
    property string _barAmber:      "#606060"
    property string _barGreen:      "#606060"
    property string _warningBg:     "#505050"
    property string _criticalBg:    "#707070"
    property string _btConnected:   "#808080"
    property string _powerPerf:     "#808080"
    property string _powerSaver:    "#808080"
    property string _powerBalanced: "#808080"
    property string _langRu:        "#505050"

    FileView {
        id: colorFile
        path: StandardPaths.writableLocation(StandardPaths.GenericCacheLocation)
              + "/matugen/qs-colors.json"

        onTextChanged: {
            if (!text) return
            try {
                const d = JSON.parse(text)
                if (d.pillBg)        _pillBg        = d.pillBg
                if (d.accent)        _accent        = d.accent
                if (d.barRed)        _barRed        = d.barRed
                if (d.barAmber)      _barAmber      = d.barAmber
                if (d.barGreen)      _barGreen      = d.barGreen
                if (d.warningBg)     _warningBg     = d.warningBg
                if (d.criticalBg)    _criticalBg    = d.criticalBg
                if (d.btConnected)   _btConnected   = d.btConnected
                if (d.powerPerf)     _powerPerf     = d.powerPerf
                if (d.powerSaver)    _powerSaver    = d.powerSaver
                if (d.powerBalanced) _powerBalanced = d.powerBalanced
                if (d.langRu)        _langRu        = d.langRu
            } catch (_) {}
        }
    }

    // Poll every second. If the file content changed, onTextChanged fires and
    // the properties above are updated — downstream bindings re-evaluate automatically.
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: colorFile.reload()
    }

    // ── Public color properties ───────────────────────────────────────────────
    // Pill backgrounds: 80% opacity
    readonly property color pillBg:        withAlpha(_pillBg, 0.8)
    // Bar track: same hue as pill, fully opaque
    readonly property color barTrack:      withAlpha(_pillBg, 1.0)
    // Accent: workspace dot, fully opaque
    readonly property color accent:        withAlpha(_accent, 1.0)
    // Bar fills: 90% opacity
    readonly property color barRed:        withAlpha(_barRed, 0.9)
    readonly property color barAmber:      withAlpha(_barAmber, 0.9)
    readonly property color barGreen:      withAlpha(_barGreen, 0.9)
    // Status pill warning/critical
    readonly property color warningBg:     withAlpha(_warningBg, 0.8)
    readonly property color criticalBg:    withAlpha(_criticalBg, 1.0)
    // Icon tints
    readonly property color btConnected:   withAlpha(_btConnected, 1.0)
    readonly property color powerPerf:     withAlpha(_powerPerf, 1.0)
    readonly property color powerSaver:    withAlpha(_powerSaver, 1.0)
    readonly property color powerBalanced: withAlpha(_powerBalanced, 1.0)
    // Language pill RU: 80% opacity
    readonly property color langRu:        withAlpha(_langRu, 0.8)
}
