pragma ComponentBehavior: Bound
import QtQuick
import qs.Commons
import qs.Ui

// One instance per monitor. The plugin id lives only in manifest.json:
// never assign `moduleName` here. The host injects it through
// ModuleSlot.injectProps, and `service` is looked up using that value. The
// popup lives in Panel.qml, loaded through a Loader because its root carries
// `required` properties (KeyboardPanel/anchorItem) that a Loader cannot fill.
// See the contract in how-synthesis.md.
BarWidget {
  id: root

  readonly property var service: bar && bar.shell && typeof bar.shell.serviceFor === "function"
    ? bar.shell.serviceFor(moduleName) : null

  // If the service is unavailable, keep an empty ring and explain why in the tooltip.
  readonly property var view: service ? service.view : ({
    mmss: "--:--", progress: 0, phase: "work", running: false,
    tooltip: "Omadoro: service did not load (see the omarchy-shell log)"
  })

  // Style.bar.iconCanvas is the same 16px that the ring prototype (ring.qml)
  // proved crisp with CurveRenderer: the bar's natural icon slot.
  readonly property real ringSize: Style.bar.iconCanvas

  implicitWidth: vertical ? barSize : ringSize
  implicitHeight: vertical ? ringSize : barSize

  // ---- Bar.findPanelWidget contract: tested on the bar-widget ROOT, not
  //      the popup. Satisfying it provides summon/hide/toggle routing to the
  //      correct monitor, Tab navigation between bar panels, and the
  //      indicator dot drawn by the host.
  function open() { if (panelLoader.item) panelLoader.item.open() }
  function close() { if (panelLoader.item) panelLoader.item.close() }
  function toggle() { if (panelLoader.item) panelLoader.item.toggle() }
  function closeForPopoutSwitch() { if (panelLoader.item) panelLoader.item.closeForPopoutSwitch() }
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  Loader {
    id: panelLoader
    active: true
    visible: false
    source: Qt.resolvedUrl("Panel.qml")
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }
  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()
  onServiceChanged: injectPanel()

  // Manual duck typing: Panel.qml has a regular qs.Ui.Panel root with zero
  // `required` properties, filled after loading because a Loader cannot
  // supply required properties in createObject.
  function injectPanel() {
    var t = panelLoader.item
    if (!t) return
    if ("bar" in t) t.bar = root.bar
    if ("settings" in t) t.settings = root.settings
    if ("service" in t) t.service = root.service
    if ("anchorItem" in t) t.anchorItem = button
    if ("hostWidget" in t) t.hostWidget = root
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    // The ring is custom content; keep the button visible without its label.
    labelVisible: false
    hasVisualContent: true
    tooltipText: root.view.tooltip

    // One handler for all three buttons: WidgetButton supplies the code.
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) {
        if (root.service) root.service.toggle()
      } else if (buttonCode === Qt.MiddleButton) {
        if (root.service) root.service.restart()
      } else {
        root.toggle() // left click: popup
      }
    }

    Ring {
      anchors.centerIn: parent
      size: root.ringSize
      thickness: Math.max(2, root.ringSize * 0.16)
      progress: root.view.progress
      phase: root.view.phase
      paused: !root.view.running
      baseColor: button.foreground
    }
  }
}
