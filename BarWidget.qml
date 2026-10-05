import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Bar toggle for Niri Extras. Click flips the Hyprland config on or off; the
// glyph reflects the current state read back from the toggle script.
BarWidget {
  id: root
  moduleName: "io.github.davy1ex.niri-extras"

  property bool enabled: false

  // The toggle script lives next to this file, inside the plugin directory.
  // bash rather than executing it directly: a plugin directory that arrived
  // without its executable bits would otherwise fail to start the script.
  readonly property string pluginDir: {
    var url = String(Qt.resolvedUrl("."))
    if (url.indexOf("file://") === 0) url = url.substring(7)
    try { url = decodeURIComponent(url) } catch (e) {}
    return url.replace(/\/+$/, "")
  }

  function refresh() {
    if (!status.running) status.running = true
  }

  function toggle() {
    if (!root.bar) return
    root.bar.run("bash " + Util.shellQuote(root.pluginDir + "/bin/niri-extras-toggle") + " extras toggle")
    settleTimer.restart()
  }

  Component.onCompleted: refresh()

  Process {
    id: status
    command: ["bash", root.pluginDir + "/bin/niri-extras-toggle", "extras", "status"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.enabled = String(text).trim() === "on"
    }
  }

  // The toggle script reloads Hyprland; give it a beat before asking again.
  Timer {
    id: settleTimer
    interval: 500
    onTriggered: root.refresh()
  }

  visible: true
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    // Window-maximize / window-restore (Font Awesome, present in Nerd Fonts).
    text: root.enabled ? "\uf2d0" : "\uf2d2"
    fontSize: Style.font.caption
    horizontalMargin: 6
    tooltipText: root.enabled ? "Niri Extras: on (click to disable)" : "Niri Extras: off (click to enable)"
    onPressed: function() { root.toggle() }
  }
}
