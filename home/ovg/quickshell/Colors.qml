// Static color palette. No dynamic loading — colors are hardcoded.
// To update colors, edit this file directly and rebuild.

import Quickshell
import QtQuick

Singleton {
    readonly property color pillBg:   Qt.rgba(0.13, 0.13, 0.13, 0.85)
    readonly property color barTrack: "#1a1a1a"
    readonly property color barFill:  "#5a8c5a"
    readonly property color accent:   "#a0a0a0"
}
