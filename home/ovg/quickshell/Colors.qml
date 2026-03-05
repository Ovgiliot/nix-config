// Static color palette. No dynamic loading — colors are hardcoded.
// To update colors, edit this file directly and rebuild.

import Quickshell
import QtQuick

Singleton {
    readonly property color pillBg:   Qt.rgba(0.25, 0.25, 0.25, 0.90)
    readonly property color barTrack: "#1a1a1a"
    readonly property color barFill:  "#aaaaaa"
    readonly property color accent:   "#cccccc"
}
