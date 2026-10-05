import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Omaniri: niri-style window management for Omarchy's scrolling layout.
//
// Bar icon plus a popup with the on/off switch, the keybindings it installs,
// and a button to re-copy the config after a plugin update. Left-click opens
// the popup, right-click flips the config without opening it.
BarWidget {
  id: root
  moduleName: "io.github.davy1ex.omaniri"

  property bool enabled: false
  property bool loaded: false
  property string error: ""
  property bool panelOpen: false

  // Locate the toggle script next to this QML file, inside the plugin dir.
  readonly property string pluginDir: {
    var url = String(Qt.resolvedUrl("."))
    if (url.indexOf("file://") === 0) url = url.substring(7)
    try { url = decodeURIComponent(url) } catch (e) {}
    return url.replace(/\/+$/, "")
  }

  readonly property color foreground: (bar && bar.foreground !== undefined) ? bar.foreground : Color.foreground
  readonly property color barForeground: (bar && bar.barForeground !== undefined) ? bar.barForeground : Color.foreground
  readonly property color dim: Util.alpha(foreground, 0.65)
  readonly property string fontFamily: (bar && bar.fontFamily !== undefined) ? bar.fontFamily : Style.font.family
  readonly property color iconColor: enabled ? foreground : dim
  readonly property color barIconColor: enabled ? barForeground : Qt.darker(barForeground, 1.55)

  readonly property string statusText: error !== "" ? "Omaniri is unavailable"
    : !loaded ? "Checking status…"
    : (enabled ? "Omaniri is on" : "Omaniri is off")

  readonly property string toggleHint: enabled ? "Turn Omaniri off" : "Turn Omaniri on"

  readonly property var keybinds: [
    { keys: "SUPER + H / J / K / L", what: "Focus left / down / up / right" },
    { keys: "SUPER + SHIFT + H / J / K / L", what: "Move the window — works in fake-fullscreen" },
    { keys: "SUPER + -  /  SUPER + =", what: "Narrow / widen the focused column" },
    { keys: "SUPER + C", what: "Center the column" },
    { keys: "SUPER + F", what: "Fake-fullscreen (stays in the layout)" },
    { keys: "SUPER + ALT + F", what: "Full screen" },
    { keys: "SUPER + ALT + L", what: "Toggle scrolling / dwindle" }
  ]

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function refresh() {
    if (!probe.running) probe.running = true
  }

  function apply(want) {
    if (!root.bar) return
    root.bar.run("bash " + Util.shellQuote(root.pluginDir + "/bin/omaniri-toggle") + " extras " + (want ? "on" : "off"))
    settleTimer.restart()
  }

  // KeyboardPanel.close() calls owner.close() when the owner has one (on
  // outside-click dismissal or Escape). Without this, the panel assigns its own
  // `open` instead, which breaks the `open: root.panelOpen` binding and leaves
  // the state out of sync -- the next bar click then looked like it did nothing.
  function close() { root.panelOpen = false }
  function open() { root.panelOpen = true }
  function togglePanel() { root.panelOpen = !root.panelOpen }

  onPanelOpenChanged: if (panelOpen) root.refresh()

  IpcHandler {
    target: root.moduleName

    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.togglePanel() }
    function status(): string { return !root.loaded ? "unknown" : (root.enabled ? "on" : "off") }
    function enable(): string { root.apply(true); return "on" }
    function disable(): string { root.apply(false); return "off" }
    function refresh(): string { root.refresh(); return "ok" }
  }

  Process {
    id: probe
    command: ["bash", root.pluginDir + "/bin/omaniri-toggle", "extras", "status"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.loaded = true
        root.error = ""
        root.enabled = String(text).trim() === "on"
      }
    }
    onExited: function(code) {
      if (code !== 0) {
        root.loaded = true
        root.error = "toggle script exited " + code
      }
    }
  }

  // The toggle script reloads Hyprland; give it a beat before asking again.
  Timer {
    id: settleTimer
    interval: 500
    onTriggered: root.refresh()
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "\uf2d0"
    foreground: root.barIconColor
    fontSize: Style.bar.iconFont
    horizontalMargin: 6
    tooltipText: root.enabled ? "Omaniri: on (click for options)" : "Omaniri: off (click for options)"
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) root.apply(!root.enabled)
      else root.togglePanel()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.panelOpen
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(400))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    // Safety net: if the panel closes itself for any reason, keep panelOpen in
    // step so the next click reopens instead of being swallowed.
    onOpenChanged: if (!open && root.panelOpen) root.panelOpen = false

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onActivateRequested: root.apply(!root.enabled)
      onCloseRequested: root.close()

      Column {
        id: column
        width: parent.width
        spacing: Style.space(14)

        PanelHero {
          width: parent.width
          title: "Omaniri"
          meta: root.statusText
          foreground: root.foreground
          fontFamily: root.fontFamily
          iconOpacity: root.enabled ? 1.0 : 0.5
          iconComponent: Component {
            Text {
              text: "\uf2d0"
              color: root.iconColor
              font.family: root.fontFamily
              font.pixelSize: Style.font.display
            }
          }
        }

        Toggle {
          id: enableToggle
          width: parent.width
          label: "Enable Omaniri"
          description: "Niri-style focus, move, resize, center and fake-fullscreen for the scrolling layout."
          checked: root.enabled
          foreground: root.foreground
          fontFamily: root.fontFamily
          onClicked: root.apply(!root.enabled)

          property bool isHovering: false
          onHovered: function(hovered) { enableToggle.isHovering = hovered }

          PanelToolTip {
            visible: enableToggle.isHovering
            text: root.toggleHint
            fontFamily: root.fontFamily
          }
        }

        Text {
          width: parent.width
          visible: root.error !== ""
          text: root.error
          wrapMode: Text.WordWrap
          color: Color.urgent
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
        }

        PanelSeparator {
          width: parent.width
          foreground: root.foreground
        }

        PanelSectionHeader {
          width: parent.width
          text: "Keys"
          foreground: root.foreground
          fontFamily: root.fontFamily
        }

        Repeater {
          model: root.keybinds

          delegate: Text {
            width: parent.width
            text: "<b>" + modelData.keys + "</b> — " + modelData.what
            textFormat: Text.RichText
            wrapMode: Text.WordWrap
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
          }
        }

        PanelSeparator {
          width: parent.width
          foreground: root.foreground
        }

        Row {
          spacing: Style.space(10)

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Refresh config"
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
          }

          PanelActionButton {
            id: refreshButton
            iconText: "\uf021"
            tooltipText: "Re-copy the config after a plugin update"
            foreground: root.foreground
            fontFamily: root.fontFamily
            onClicked: {
              root.bar.run("bash " + Util.shellQuote(root.pluginDir + "/bin/omaniri-toggle") + " extras refresh")
              settleTimer.restart()
            }

            property bool isHovering: false
            onHovered: function(hovered) { refreshButton.isHovering = hovered }

            PanelToolTip {
              visible: refreshButton.isHovering
              text: "Refresh config"
              fontFamily: root.fontFamily
            }
          }
        }
      }
    }
  }
}
