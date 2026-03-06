pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    // Fallback colors — used before the file loads or if it is absent.
    property color pillBg:    "#404040"
    property color barTrack:  "#1a1a1a"
    property color barFill:   "#aaaaaa"
    property color accent:    "#cccccc"
    property color textColor: "#cdc3d2"
    property color outline:   "#4a4a4a"
    // shadow is always #000000 in any scheme; shadowColor adds the opacity.
    property color shadow:    "#000000"
    readonly property color shadowColor: Qt.rgba(shadow.r, shadow.g, shadow.b, 0.47)

    FileView {
        id: colorFile
        path: Scripts.qsColors
        watchChanges: true
        onFileChanged: colorFile.reload()
        onLoaded: {
            try {
                const d = JSON.parse(colorFile.text())
                if (d.pillBg)    pillBg    = d.pillBg
                if (d.barTrack)  barTrack  = d.barTrack
                if (d.barFill)   barFill   = d.barFill
                if (d.accent)    accent    = d.accent
                if (d.textColor) textColor = d.textColor
                if (d.outline)   outline   = d.outline
                if (d.shadow)    shadow    = d.shadow
            } catch (_) {}
        }
    }
}
