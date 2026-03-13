pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    // Fallback colors — used before the file loads or if it is absent.
    property color pillBg:       "#404040"
    property color barTrack:     "#1a1a1a"
    property color barFill:      "#aaaaaa"
    property color accent:       "#cccccc"
    property color primaryTrack: "#211e24"
    property color errorFill:    "#ffb4ab"
    property color errorTrack:   "#93000a"
    property color textColor:    "#cdc3d2"
    property color outline:      "#4a4a4a"
    // shadow is always #000000 in any scheme; shadowColor adds the opacity.
    property color shadow:       "#000000"
    readonly property color shadowColor: Qt.rgba(shadow.r, shadow.g, shadow.b, 0.47)
    // Picker / dialog surface tokens
    property color pickerBg:          "#2a2a2a"
    property color onSurface:         "#e6e1e5"
    property color selectionBg:       "#4a4458"
    property color selectionText:     "#ccc2dc"
    property color outlineVariant:    "#49454f"
    // Visualizer gradient: surface_container_highest (quiet) → tertiary_container (peak)
    property color vizColorLow:       "#534b52"
    property color vizColorHigh:      "#4d2532"

    FileView {
        id: colorFile
        path: Scripts.qsColors
        watchChanges: true
        onFileChanged: colorFile.reload()
        onLoaded: {
            try {
                const d = JSON.parse(colorFile.text())
                if (d.pillBg)       pillBg       = d.pillBg
                if (d.barTrack)     barTrack     = d.barTrack
                if (d.barFill)      barFill      = d.barFill
                if (d.accent)       accent       = d.accent
                if (d.primaryTrack) primaryTrack = d.primaryTrack
                if (d.errorFill)    errorFill    = d.errorFill
                if (d.errorTrack)   errorTrack   = d.errorTrack
                if (d.textColor)    textColor    = d.textColor
                if (d.outline)      outline      = d.outline
                if (d.shadow)       shadow       = d.shadow
                if (d.pickerBg)         pickerBg         = d.pickerBg
                if (d.onSurface)        onSurface        = d.onSurface
                if (d.selectionBg)      selectionBg      = d.selectionBg
                if (d.selectionText)    selectionText    = d.selectionText
                if (d.outlineVariant)   outlineVariant   = d.outlineVariant
                if (d.vizColorLow)      vizColorLow      = d.vizColorLow
                if (d.vizColorHigh)     vizColorHigh     = d.vizColorHigh
            } catch (_) {}
        }
    }
}
