pragma ComponentBehavior: Bound
import QtQuick
import qs.Commons
import qs.Ui
import "Model.js" as Model

// The popup: two tabs, Pomodoro and Config. The root MUST be qs.Ui.Panel
// with zero `required` properties because BarWidget.qml loads it through a
// Loader, which cannot fill required properties. The actual KeyboardPanel
// (with required anchorItem/bar) is nested inside, with properties filled
// manually by `injectPanel()` in the host.
//
// `manageIpc: false`: IPC target "pomodoro" lives in the singleton Service.
// This panel exists once per monitor; registering the same target twice
// would cause the same bug that chime avoids this way.
Panel {
  id: root
  manageIpc: false

  // moduleName is inherited from qs.Ui.Panel, not redeclared: qmllint rejects
  // shadowing a base property. Bound to the widget that loaded us, which gets
  // its id from the host. The plugin id exists as text only in manifest.json.
  moduleName: hostWidget ? hostWidget.moduleName : ""

  property var anchorItem: null // PLAIN, not `required` — injected manually
  property var hostWidget: null
  property var service: null

  // The host identifies a panel by the widget mounted in the slot, rather
  // than this nested object: requestPopout and switchPanelFrom use the widget.
  readonly property var barIdentity: hostWidget || root

  readonly property color fg: bar ? bar.foreground : Color.foreground
  readonly property color dim: Util.alpha(fg, 0.6)
  readonly property color accent: Color.accent
  readonly property color cardColor: Util.alpha(fg, 0.05)
  readonly property color cardBorder: Util.alpha(fg, 0.08)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  readonly property var cfg: service ? service.config : Model.normalizeConfig({})

  // Frozen while the popup is closed: otherwise every row reevaluates each
  // second behind a window nobody sees.
  // service.view is already recalculated every second for the bar; freezing
  // a copy here would create a second source of truth and a ring that animates again on opening.
  readonly property var vm: service ? service.view : Model.view(Model.initialTimer(root.cfg), root.cfg, Date.now())

  property string tab: "pomodoro" // no TabBar; ButtonGroup + visible

  readonly property real sliderHeight: Style.space(36) // click area, not visual size

  // Ui/Panel.switchPanel passes `root` (this nested object) to the host,
  // which only recognizes the widget mounted in the slot. Without this
  // override, Tab inside the popup silently does nothing.
  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  function commitSetting(name, value) {
    if (root.service) root.service.setConfig(name, value)
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    bar: root.bar
    owner: root.barIdentity
    open: root.opened
    focusTarget: keys
    contentWidth: panel.fittedContentWidth(Style.space(320))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    // KeyboardPanel rather than PopupCard: Escape only arrives through
    // PanelKeyCatcher, which needs focus; PopupCard has none. The catcher
    // consumes arrows and Enter even without handlers, so they get a use:
    // arrows switch tabs, Enter/Space pauses or resumes.
    PanelKeyCatcher {
      id: keys
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onMoveRequested: function(dx, dy) { if (dx !== 0) root.tab = dx > 0 ? "config" : "pomodoro" }
      onActivateRequested: if (root.service) root.service.toggle()
      onReturnRequested: if (root.service) root.service.toggle()

      Column {
        id: column
        anchors.fill: parent
        spacing: Style.space(14)

        ButtonGroup {
          width: parent.width
          options: ["Pomodoro", "Config"]
          value: root.tab === "pomodoro" ? "Pomodoro" : "Config"
          foreground: root.fg
          fontFamily: root.fontFamily
          onChanged: function(value) { root.tab = value === "Pomodoro" ? "pomodoro" : "config" }
        }

        // -------------------------------------------------------- Pomodoro

        Column {
          visible: root.tab === "pomodoro"
          width: parent.width
          spacing: Style.space(16)

          // Card behind the ring
          Rectangle {
            width: parent.width
            height: ring.height + Style.space(32)
            radius: Style.space(16)
            color: root.cardColor
            border.width: 1
            border.color: root.cardBorder

            Ring {
              id: ring
              anchors.centerIn: parent
              size: 184
              thickness: 10
              progress: root.vm.progress
              phase: root.vm.phase
              paused: !root.vm.running

              Column {
                anchors.centerIn: parent
                spacing: Style.space(4)

                Text {
                  textFormat: Text.PlainText
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: root.vm.mmss
                  color: root.fg
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.displayLarge
                  font.bold: true
                  font.letterSpacing: 1
                }

                // Phase name in the same color as the ring, small caps look
                Text {
                  textFormat: Text.PlainText
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: String(root.vm.phaseLabel).toUpperCase()
                  color: root.vm.running ? ring.fill : root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body - 2
                  font.bold: true
                  font.letterSpacing: 2
                }
              }
            }
          }

          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Style.space(14)

            // Three icons from the same family (Nerd Font, through Button.iconText)
            // at the same size: an emoji instead of an icon leaves the shell font
            // and appears in color from another font.
            // Button sizes itself by the glyph; the restart button sets the size.
            Button {
              id: restartButton
              iconText: "󰜉"
              tooltipText: "Restart phase"
              bordered: true
              foreground: root.fg
              fontFamily: root.fontFamily
              onClicked: if (root.service) root.service.restart()
            }

            Button {
              width: restartButton.implicitWidth
              height: restartButton.implicitHeight
              iconText: root.vm.running ? "󰏤" : "󰐊"
              tooltipText: root.vm.running ? "Pause" : "Resume"
              bordered: true
              selected: true
              foreground: root.fg
              fontFamily: root.fontFamily
              onClicked: if (root.service) root.service.toggle()
            }

            Button {
              width: restartButton.implicitWidth
              height: restartButton.implicitHeight
              iconText: "󰒭"
              tooltipText: "Skip phase"
              bordered: true
              foreground: root.fg
              fontFamily: root.fontFamily
              onClicked: if (root.service) root.service.skip()
            }
          }

          // Keyboard hint
          Text {
            textFormat: Text.PlainText
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "Space: pause/resume  ·  ←/→: switch tab"
            color: Util.alpha(root.fg, 0.4)
            font.family: root.fontFamily
            font.pixelSize: Style.font.body - 2
          }
        }

        // ---------------------------------------------------------- Config

        Rectangle {
          visible: root.tab === "config"
          width: parent.width
          height: configColumn.implicitHeight + Style.space(32)
          radius: Style.space(16)
          color: root.cardColor
          border.width: 1
          border.color: root.cardBorder

          Column {
            id: configColumn
            x: Style.space(16)
            y: Style.space(16)
            width: parent.width - Style.space(32)
            spacing: Style.space(12)

            ConfigSlider { label: "Focus time"; configKey: "work"; minimum: 5; maximum: 60 }
            ConfigSlider { label: "Short break"; configKey: "short"; minimum: 1; maximum: 20 }
            ConfigSlider { label: "Long break"; configKey: "long"; minimum: 10; maximum: 45 }

            Column {
              width: parent.width
              spacing: Style.space(4)

              SettingHeader {
                label: "Cycles until long break"
                valueText: String(Math.round(longEverySlider.dragging ? longEverySlider.liveValue : longEverySlider.value))
              }

              PanelSlider {
                id: longEverySlider
                width: parent.width
                height: root.sliderHeight
                bar: root.bar
                minimum: 2
                maximum: 8
                step: 1
                integer: false
                tickCount: 7
                value: root.cfg.longEvery
                onReleased: function(v) { root.commitSetting("longEvery", Math.round(v)) }
              }
            }

            Toggle {
              width: parent.width
              label: "Auto-start next phase"
              checked: root.cfg.autoStartNext
              foreground: root.fg
              fontFamily: root.fontFamily
              onClicked: root.commitSetting("autoStartNext", !checked)
            }
          }
        }
      }
    }
  }

  // Inline components can only be direct children of the QML document root
  // (they cannot be nested inside Column/PanelKeyCatcher), so they live here
  // as siblings of KeyboardPanel, even though referenced inside it.

  // Label on the left, current value in the accent color on the right.
  component SettingHeader: Item {
    id: header
    required property string label
    required property string valueText
    width: parent.width
    height: labelText.implicitHeight

    Text {
      id: labelText
      textFormat: Text.PlainText
      anchors.left: parent.left
      text: header.label
      color: root.fg
      font.family: root.fontFamily
      font.pixelSize: Style.font.body
    }

    Text {
      textFormat: Text.PlainText
      anchors.right: parent.right
      text: header.valueText
      color: root.accent
      font.family: root.fontFamily
      font.pixelSize: Style.font.body
      font.bold: true
    }
  }

  component ConfigSlider: Column {
    id: field
    required property string label
    required property string configKey
    required property int minimum
    required property int maximum
    width: parent.width
    spacing: Style.space(4)

    readonly property real shownValue: slider.dragging ? slider.liveValue : slider.value

    SettingHeader {
      label: field.label
      valueText: Math.round(field.shownValue) + " min"
    }

    PanelSlider {
      id: slider
      width: parent.width
      height: root.sliderHeight
      bar: root.bar
      minimum: field.minimum
      maximum: field.maximum
      step: 1
      // Continuous: integer makes the knob jump in steps instead of following the mouse.
      integer: false
      value: root.cfg[field.configKey]
      // `released` saves once, on mouse-up: writing shell.json for every dragged
      // pixel would be wasteful and, with `allowMultiple: false`, cause a storm
      // of widget rebuilds.
      onReleased: function(v) { root.commitSetting(field.configKey, Math.round(v)) }
    }
  }
}



