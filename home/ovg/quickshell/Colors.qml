pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    // Fallback colors — used before the file loads or if it is absent.
    property color pillBg:   "#404040"
    property color barTrack: "#1a1a1a"
    property color barFill:  "#aaaaaa"
    property color accent:   "#cccccc"

    FileView {
        id: colorFile
        path: Scripts.qsColors
        watchChanges: true
        onFileChanged: colorFile.reload()
        onLoaded: {
            try {
                const d = JSON.parse(colorFile.text())
                if (d.pillBg)   pillBg   = d.pillBg
                if (d.barTrack) barTrack = d.barTrack
                if (d.barFill)  barFill  = d.barFill
                if (d.accent)   accent   = d.accent
            } catch (_) {}
        }
    }
}
