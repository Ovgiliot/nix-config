// Wallpaper picker overlay.
//
// Visibility is driven by ~/.cache/qs-wallpaper-open (JSON: {"show": true/false}).
// External toggle: toggle-wallpaper-picker (niri keybind Mod+Shift+W).
// Internal close: Escape key writes {"show":false} via hide-wallpaper-picker.
//
// Navigation: j/k or Down/Up — move selection, preview updates live.
//             Enter — apply selected wallpaper via set-wallpaper.
//             Escape — close.
//
// Layout: 60% screen width, 25% screen height, top-centred below the bar.
//   Left 1/3 — scrollable filename list.
//   Right 2/3 — image preview.

import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtCore
import QtQuick
import QtQuick.Effects

PanelWindow {
    id: root

    // ── Layer-shell geometry ─────────────────────────────────────────────────
    // left+right anchors with 20% margins each side → 60% effective width.
    // margins.top: 24px bar exclusiveZone + 4px gap.
    anchors {
        top:   true
        left:  true
        right: true
    }
    margins.top:   28
    margins.left:  screen.width  * 0.2
    margins.right: screen.width  * 0.2
    implicitHeight: screen.height * 0.25

    color: "transparent"

    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.namespace:     "wallpaper-picker"
    // Exclusive: steal all keyboard input while visible so j/k work immediately.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    visible: false   // driven by flag file below

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

    // Bind visibility to flag file; refresh list every time the picker opens.
    Binding { target: root; property: "visible"; value: flagData.show }

    onVisibleChanged: {
        if (visible) {
            root.refresh()
            // Give the inner Item keyboard focus as soon as the window appears.
            Qt.callLater(() => content.forceActiveFocus())
        }
    }

    // ── State ────────────────────────────────────────────────────────────────
    property var    wallpapers:       []
    property int    selectedIndex:    0
    property string currentWallpaper: ""   // path from qs-current-wallpaper
    property string wallpaperToApply: ""

    // ── Script paths ─────────────────────────────────────────────────────────
    Scripts { id: scripts }

    // ── Read active wallpaper path ────────────────────────────────────────────
    // Sequential: read current → list wallpapers → pre-select.
    Process {
        id: readCurrentProc
        command: ["sh", "-c",
                  "cat \"$HOME/.cache/qs-current-wallpaper\" 2>/dev/null || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.currentWallpaper = text.trim()
                if (!listProc.running) listProc.running = true
            }
        }
    }

    // ── List wallpapers ───────────────────────────────────────────────────────
    Process {
        id: listProc
        command: [scripts.listWallpapers]
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
                // positionViewAtIndex needs one event-loop tick after model update.
                Qt.callLater(() =>
                    listView.positionViewAtIndex(root.selectedIndex, ListView.Center))
            }
        }
    }

    // ── Apply wallpaper ───────────────────────────────────────────────────────
    Process {
        id: applyProc
        // command is rebuilt whenever wallpaperToApply changes; only runs when
        // applySelected() explicitly sets running = true.
        command: root.wallpaperToApply.length > 0
                 ? [scripts.setWallpaper, root.wallpaperToApply]
                 : ["sh", "-c", "true"]
        onRunningChanged: {
            // Optimistic: once the process exits, record the new active wallpaper.
            if (!running && root.wallpaperToApply.length > 0)
                root.currentWallpaper = root.wallpaperToApply
        }
    }

    // ── Hide picker ───────────────────────────────────────────────────────────
    Process {
        id: hideProc
        command: [scripts.hideWallpaperPicker]
    }

    // ── Helpers ───────────────────────────────────────────────────────────────
    function refresh() {
        if (!readCurrentProc.running) readCurrentProc.running = true
    }

    function applySelected() {
        if (root.wallpapers.length === 0 || applyProc.running) return
        root.wallpaperToApply = root.wallpapers[root.selectedIndex].path
        applyProc.running = true
    }

    function closePicker() {
        if (!hideProc.running) hideProc.running = true
    }

    // ── Background (rendered via MultiEffect for shadow) ─────────────────────
    Rectangle {
        id: bg
        anchors.fill: parent
        color:        Colors.barTrack   // fully opaque pillBg — solid backdrop
        radius:       8
        visible:      false
    }

    MultiEffect {
        source:               bg
        anchors.fill:         bg
        autoPaddingEnabled:   true
        shadowEnabled:        true
        shadowColor:          "#77000000"
        shadowBlur:           0.7
        shadowVerticalOffset: 5
        shadowHorizontalOffset: 0
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
                root.selectedIndex =
                    Math.min(root.selectedIndex + 1, root.wallpapers.length - 1)
                listView.positionViewAtIndex(root.selectedIndex, ListView.Contain)
                event.accepted = true
                break
            case Qt.Key_K:
            case Qt.Key_Up:
                root.selectedIndex = Math.max(root.selectedIndex - 1, 0)
                listView.positionViewAtIndex(root.selectedIndex, ListView.Contain)
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

        // ── Left pane: file list ──────────────────────────────────────────────
        ListView {
            id: listView
            anchors.left:   parent.left
            anchors.top:    parent.top
            anchors.bottom: parent.bottom
            width:          Math.floor(parent.width / 3)
            clip:           true
            model:          root.wallpapers
            currentIndex:   root.selectedIndex

            delegate: Item {
                required property var modelData
                required property int index

                width:  listView.width
                height: 22

                // Selection highlight
                Rectangle {
                    anchors.fill: parent
                    radius:       4
                    color:        index === root.selectedIndex
                                  ? Qt.rgba(Colors.accent.r, Colors.accent.g,
                                            Colors.accent.b, 0.2)
                                  : "transparent"
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left:           parent.left
                    anchors.leftMargin:     6
                    anchors.right:          parent.right
                    anchors.rightMargin:    6
                    // Bullet marks the selected item; two spaces keep others aligned.
                    text:           (index === root.selectedIndex ? "● " : "  ")
                                    + modelData.name
                    font.family:    "FiraMono Nerd Font"
                    font.pixelSize: 13
                    color:          index === root.selectedIndex
                                    ? Colors.accent : "#fafafa"
                    elide:          Text.ElideRight
                }
            }
        }

        // ── Divider ───────────────────────────────────────────────────────────
        Rectangle {
            id:             divider
            anchors.top:    parent.top
            anchors.bottom: parent.bottom
            anchors.left:   listView.right
            anchors.leftMargin: 4
            width:          1
            color:          Qt.rgba(Colors.accent.r, Colors.accent.g,
                                    Colors.accent.b, 0.3)
        }

        // ── Right pane: preview ───────────────────────────────────────────────
        Image {
            anchors.left:        divider.right
            anchors.leftMargin:  4
            anchors.right:       parent.right
            anchors.top:         parent.top
            anchors.bottom:      parent.bottom
            source:              root.wallpapers.length > 0
                                 ? "file://" + root.wallpapers[root.selectedIndex].path
                                 : ""
            fillMode:            Image.PreserveAspectFit
            asynchronous:        true
            smooth:              true
        }

        // Loading placeholder — shown until the list is populated.
        Text {
            anchors.centerIn: parent
            visible:          root.wallpapers.length === 0
            text:             "Loading…"
            font.family:      "FiraMono Nerd Font"
            font.pixelSize:   14
            color:            "#fafafa"
        }
    }
}
