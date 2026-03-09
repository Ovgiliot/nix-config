// Wallpaper picker carousel overlay.
//
// Visibility is driven by ~/.cache/qs-wallpaper-open (JSON: {"show": true/false}).
// External toggle: toggle-wallpaper-picker (niri keybind Mod+Shift+W).
// Internal close: Escape key writes {"show":false} via hide-wallpaper-picker.
//
// Navigation: j/k — spin carousel left/right, center item is the selection.
//             Enter — apply the center wallpaper via set-wallpaper.
//             Escape — close.
//
// Layout: 60% screen width, top-centred below the bar.
//   Horizontal carousel showing 5 wallpaper thumbnails with filenames beneath.
//   The center item is visually highlighted as the current selection.
//   7 images are loaded at all times (5 visible + 1 off-screen on each side).

import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtCore
import QtQuick

PanelWindow {
    id: root

    // ── Layout constants ─────────────────────────────────────────────────────
    readonly property int visibleCount: 5
    readonly property int filenameHeight: 22
    readonly property int cellSpacing: 8
    readonly property int contentMargin: 8   // anchors.margins on content Item

    // Effective width available for cells (screen width minus layer-shell
    // margins minus the content Item's own margins on both sides).
    readonly property real contentWidth: screen.width * 0.6 - contentMargin * 2
    readonly property real cellWidth: contentWidth / visibleCount
    // Thumbnail image width/height inside each cell (16:9 aspect ratio).
    readonly property real thumbWidth:  cellWidth - cellSpacing
    readonly property real thumbHeight: thumbWidth * 9 / 16

    // ── Layer-shell geometry ─────────────────────────────────────────────────
    anchors {
        top:   true
        left:  true
        right: true
    }
    margins.top:   28
    margins.left:  screen.width  * 0.2
    margins.right: screen.width  * 0.2
    // Height derived from 16:9 thumbnails + filename + spacing + margins.
    implicitHeight: thumbHeight + filenameHeight + 4 + contentMargin * 2

    color: "transparent"

    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.namespace:     "wallpaper-picker"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    visible: false

    Component.onCompleted: {
        if (!hideProc.running) hideProc.running = true
    }

    // ── Flag file: {"show": true/false} ─────────────────────────────────────
    FileView {
        id: flagFile
        path:         StandardPaths.writableLocation(StandardPaths.GenericCacheLocation)
                      + "/qs-wallpaper-open"
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: flagData
            property bool show: false
        }
    }

    Binding { target: root; property: "visible"; value: flagData.show }

    onVisibleChanged: {
        if (visible) {
            root.refresh()
            Qt.callLater(() => content.forceActiveFocus())
        }
    }

    // ── State ────────────────────────────────────────────────────────────────
    property var    wallpapers:       []
    property int    selectedIndex:    0
    property string currentWallpaper: ""
    property string wallpaperToApply: ""

    // ── Read active wallpaper path via FileView ───────────────────────────────
    FileView {
        id: currentWallpaperFile
        path: StandardPaths.writableLocation(StandardPaths.GenericCacheLocation)
              + "/qs-current-wallpaper"
        onTextChanged: {
            root.currentWallpaper = (currentWallpaperFile.text() || "").trim()
        }
    }

    // ── List wallpapers ───────────────────────────────────────────────────────
    Process {
        id: listProc
        command: [Scripts.listWallpapers]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n").filter(l => l.length > 0)
                root.wallpapers = lines.map(p => ({
                    path: p,
                    name: p.split("/").pop().replace(/\.[^.]+$/, "")
                }))
                const idx = root.wallpapers.findIndex(
                    w => w.path === root.currentWallpaper)
                root.selectedIndex = idx >= 0 ? idx : 0
                Qt.callLater(() => carousel.positionViewAtIndex(
                    root.selectedIndex, ListView.Center))
            }
        }
    }

    // ── Apply wallpaper ───────────────────────────────────────────────────────
    Process {
        id: applyProc
        command: root.wallpaperToApply.length > 0
                 ? [Scripts.setWallpaper, root.wallpaperToApply]
                 : ["sh", "-c", "true"]
        onExited: (code) => {
            if (code === 0 && root.wallpaperToApply.length > 0)
                root.currentWallpaper = root.wallpaperToApply
        }
    }

    // ── Hide picker ───────────────────────────────────────────────────────────
    Process {
        id: hideProc
        command: [Scripts.hideWallpaperPicker]
    }

    // ── Helpers ───────────────────────────────────────────────────────────────
    function refresh() {
        currentWallpaperFile.reload()
        if (!listProc.running) listProc.running = true
    }

    function applySelected() {
        if (root.wallpapers.length === 0 || applyProc.running) return
        root.wallpaperToApply = root.wallpapers[root.selectedIndex].path
        applyProc.running = true
    }

    function closePicker() {
        if (!hideProc.running) hideProc.running = true
    }

    // ── Background ────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color:        Colors.pickerBg
        radius:       8
    }

    // ── Content ───────────────────────────────────────────────────────────────
    Item {
        id: content
        anchors.fill:    parent
        anchors.margins: 8
        focus:           true

        Keys.onPressed: event => {
            switch (event.key) {
            case Qt.Key_J:
            case Qt.Key_Down:
            case KeyMap.cyrillicJ:
                root.selectedIndex =
                    Math.min(root.selectedIndex + 1, root.wallpapers.length - 1)
                event.accepted = true
                break
            case Qt.Key_K:
            case Qt.Key_Up:
            case KeyMap.cyrillicK:
                root.selectedIndex = Math.max(root.selectedIndex - 1, 0)
                event.accepted = true
                break
            case Qt.Key_Return:
            case Qt.Key_Enter:
                root.applySelected()
                event.accepted = true
                break
            case Qt.Key_Escape:
                root.closePicker()
                event.accepted = true
                break
            default:
                break
            }
        }

        // ── Horizontal carousel ──────────────────────────────────────────────
        ListView {
            id: carousel
            anchors.fill: parent
            orientation:  ListView.Horizontal
            clip:         true
            model:        root.wallpapers
            currentIndex: root.selectedIndex

            // Snap so one item is always perfectly centered.
            snapMode:              ListView.SnapOneItem
            highlightRangeMode:    ListView.StrictlyEnforceRange
            preferredHighlightBegin: root.cellWidth * 2
            preferredHighlightEnd:   root.cellWidth * 3

            // Smooth animated scrolling when j/k is pressed.
            highlightMoveDuration: 200

            // Preload 1 off-screen item on each side → 7 total delegates alive.
            cacheBuffer: Math.ceil(root.cellWidth)

            // Disable interactive drag — keyboard-only navigation.
            interactive: false

            delegate: Item {
                id: del
                required property var modelData
                required property int index

                width:  root.cellWidth
                height: carousel.height

                readonly property bool isCurrent: index === root.selectedIndex
                readonly property bool isApplied: modelData.path === root.currentWallpaper

                // ── Thumbnail card ───────────────────────────────────────────
                Column {
                    anchors.fill: parent
                    anchors.margins: root.cellSpacing / 2
                    spacing: 4

                    // Image container with selection border (16:9 aspect)
                    Rectangle {
                        width:  root.thumbWidth
                        height: root.thumbHeight
                        radius: 6
                        color:  "transparent"
                        border.width: del.isCurrent ? 2 : 0
                        border.color: Colors.selectionBg

                        // Clip the image to the rounded rectangle
                        Rectangle {
                            id: imageClip
                            anchors.fill:    parent
                            anchors.margins: del.isCurrent ? 2 : 0
                            radius:          del.isCurrent ? 4 : 6
                            color:           "transparent"
                            clip:            true

                            Image {
                                anchors.fill: parent
                                source:       "file://" + modelData.path
                                fillMode:     Image.PreserveAspectCrop
                                asynchronous: true
                                smooth:       true
                                // Dim non-center items
                                opacity:      del.isCurrent ? 1.0 : 0.5
                            }
                        }

                        // Applied-wallpaper indicator (checkmark badge)
                        Rectangle {
                            visible: del.isApplied
                            anchors.top:    parent.top
                            anchors.right:  parent.right
                            anchors.topMargin:   4
                            anchors.rightMargin: 4
                            width:  18
                            height: 18
                            radius: 9
                            color:  Colors.selectionBg

                            Text {
                                anchors.centerIn: parent
                                text:             "✓"
                                font.pixelSize:   11
                                font.family:      "FiraMono Nerd Font"
                                color:            Colors.selectionText
                            }
                        }
                    }

                    // Filename label
                    Text {
                        width:              parent.width
                        height:             root.filenameHeight
                        text:               modelData.name
                        font.family:        "FiraMono Nerd Font"
                        font.pixelSize:     12
                        font.bold:          del.isCurrent
                        color:              del.isCurrent
                                            ? Colors.selectionText : Colors.onSurface
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment:   Text.AlignVCenter
                        elide:              Text.ElideRight
                        opacity:            del.isCurrent ? 1.0 : 0.6
                    }
                }
            }
        }

        // Loading placeholder
        Text {
            anchors.centerIn: parent
            visible:          root.wallpapers.length === 0
            text:             "Loading…"
            font.family:      "FiraMono Nerd Font"
            font.pixelSize:   14
            color:            Colors.textColor
        }
    }
}
