pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "Model.js" as Model

// The plugin's sole state owner: the shell mounts ONE Service per process,
// and each BarWidget (one per monitor) finds it through `bar.shell.serviceFor`.
// Everything the reducer (Model.step) decides must happen in the real world
// — persist, notify, play sound — goes through `runEffect`, the repository's
// only code with side effects. This makes notifications testable under node
// in test/model.test.js, without Qt.
Item {
  id: root

  // ---- Injected by the host (duck-typed: names must match exactly).
  property string omarchyPath: ""
  property var shell: null
  property var manifest: null

  // The id lives only in manifest.json; this fallback is only for cases
  // (tests, incomplete injection) where `manifest` has not arrived yet.
  readonly property string pluginId: manifest && manifest.id ? String(manifest.id) : "tarik.pomodoro"

  // ---- Configuration: read from shell.json through the host facade, written
  //      from here only through `setConfig`. Two entries with the same id
  //      (two monitors) merge by key: first wins, the same rule chime uses
  //      for `settingsMerged`.
  function mergedSettings(barConfig) {
    var out = {}
    var layout = barConfig && Util.isPlainObject(barConfig.layout) ? barConfig.layout : null
    if (!layout) return out
    var regions = ["left", "center", "right"]
    for (var r = 0; r < regions.length; r++) {
      var entries = Array.isArray(layout[regions[r]]) ? layout[regions[r]] : []
      for (var i = 0; i < entries.length; i++) {
        var entry = entries[i]
        if (!Util.isPlainObject(entry) || Util.canonicalWidgetId(entry.id) !== root.pluginId) continue
        for (var key in entry) {
          if (key !== "id" && out[key] === undefined) out[key] = entry[key]
        }
      }
    }
    return out
  }

  // The host returns barConfig one write behind (see
  // docs/development-pitfalls.md): the entry we just wrote remains
  // authoritative until the host returns that exact entry.
  readonly property var hostEntry: mergedSettings(root.shell ? root.shell.barConfig : null)
  property var pendingEntry: null
  // Delayed delivery of our own write is not an external change.
  property var writtenHistory: []
  readonly property var config: Model.normalizeConfig(root.pendingEntry || root.hostEntry)

  onHostEntryChanged: {
    if (!root.pendingEntry) return
    var arrived = JSON.stringify(root.hostEntry)
    if (arrived === JSON.stringify(root.pendingEntry) || root.writtenHistory.indexOf(arrived) === -1)
      root.pendingEntry = null
  }
  // Snapshot of the previous config, only for `stepConfig` resync, which
  // compares the OLD duration with the new one. Not a live binding:
  // reassigned manually below, once per actual `config` change.
  property var previousConfig: Model.normalizeConfig({})

  onConfigChanged: {
    var prev = root.previousConfig
    root.previousConfig = root.config
    if (prev.sound !== root.config.sound) {
      root.soundBroken = false
      root.soundFailures = 0
    }
    if (!root.ready) return
    root.adopt(Model.step(root.timer, { kind: "config", next: root.config }, prev, root.nowMs))
  }

  // ---- Public surface: timer is opaque to the UI; view is what it reads.
  property var timer: Model.initialTimer(root.config)
  // Plain bool written in adopt: `timer` changes reference on every tick,
  // and binding precision to it (or view) closes a loop the shell logs as
  // "Binding loop detected" (measured live in both forms).
  property bool running: false
  property bool ready: false
  readonly property var view: Model.view(root.timer, root.config, root.nowMs)

  property double nowMs: Date.now()

  // Seconds while counting, minutes while stopped: follows wall-clock time
  // and corrects itself after suspend. A Timer counting intervals would not
  // do this.
  SystemClock {
    id: clock
    precision: root.running ? SystemClock.Seconds : SystemClock.Minutes
    onDateChanged: {
      root.nowMs = date.getTime()
      root.dispatch("tick")
    }
  }

  // ---- The reducer. ONE gate for every system transition; `dispatch` uses
  //      a string rather than five identical methods (a pass-through red
  //      flag), and the boundary validates against Model.EVENTS.
  function dispatch(kind) {
    if (Model.EVENTS.indexOf(kind) === -1) {
      console.warn("pomodoro: unknown event '" + kind + "'")
      return false
    }
    // When stopped, SystemClock ticks only once per minute: toggle/skip using
    // that last tick's nowMs would shorten the new phase by up to 59 s.
    root.nowMs = Date.now()
    root.adopt(Model.step(root.timer, { kind: kind }, root.config, root.nowMs))
    return true
  }

  // One-liners over dispatch(), so QML reads names instead of strings.
  function toggle() { return root.dispatch("toggle") }
  function start() { return root.dispatch("start") }
  function skip() { return root.dispatch("skip") }
  function restart() { return root.dispatch("restart") }
  function reset() { return root.dispatch("reset") }

  // The ONLY configuration write gate in the entire repository.
  function setConfig(key, value) {
    if (!root.shell || typeof root.shell.updateEntryInline !== "function") return false
    // updateEntryInline replaces the whole entry: starting from the live
    // entry preserves keys that are not ours (the host discards `id` itself).
    var base = root.pendingEntry || root.hostEntry
    var entry = {}
    for (var k in base) entry[k] = base[k]
    entry[key] = value
    var history = root.writtenHistory.slice(-7)
    history.push(JSON.stringify(entry))
    root.writtenHistory = history
    root.pendingEntry = entry
    return root.shell.updateEntryInline(root.pluginId, entry)
  }

  function adopt(stepResult) {
    root.timer = stepResult.timer
    root.running = stepResult.timer.clock.state === "running"
    var effects = stepResult.effects
    // Order matters: the reducer always returns persist before notify/sound.
    // If the shell dies between them, a notification is lost, never duplicated.
    for (var i = 0; i < effects.length; i++) root.runEffect(effects[i])
  }

  function runEffect(effect) {
    if (effect.kind === "persist") {
      root.saveWanted = true
      if (!root.dirReady) return
      // Phase changes and repairs save immediately: debounce is for heartbeats
      // and bursts of clicks, not the interval between saving and notifying.
      if (effect.reason === "phase" || effect.reason === "repair") { saveTimer.stop(); saveTimer.triggered() }
      else saveTimer.restart()
    } else if (effect.kind === "notify") {
      root.sendNotification(effect)
    } else if (effect.kind === "sound") {
      root.playSound(effect.file)
    }
  }

  // ---------------------------------------------------------- notification
  //
  // `--exec` consumes the rest of argv as the click action. With
  // autoStartNext off (the default), the user finishes focus and faces a
  // stopped break; the notification becomes the "start" button. `start` is
  // idempotent, so clicking twice does not restart anything.
  function sendNotification(effect) {
    var exec = (root.omarchyPath || "/usr/share/omarchy") + "/bin/omarchy-shell"
    Quickshell.execDetached([
      "omarchy-notification-send",
      "--app-name", "Pomodoro",
      "-g", effect.glyph,
      "-u", effect.urgency,
      "-t", "8000",
      Model.plainLabel(effect.title, 80),
      Model.plainLabel(effect.body, 200),
      "--exec", exec, "pomodoro", "start"
    ])
  }

  // ---------------------------------------------------------------- sound
  //
  // Portable chain (chime): pw-play -> paplay -> mpv -> ffplay. exitCode 3
  // (or three consecutive quick failures) latches `soundBroken` instead of
  // spinning on disk without audio.
  readonly property string soundScript: 'f="$1"; [[ -f "$f" && -r "$f" ]] || { sleep 2; exit 3; }; '
    + 'if command -v pw-play >/dev/null 2>&1; then exec pw-play -- "$f"; fi; '
    + 'if command -v paplay >/dev/null 2>&1; then exec paplay -- "$f"; fi; '
    + 'if command -v mpv >/dev/null 2>&1; then exec mpv --no-video --no-terminal --really-quiet -- "$f"; fi; '
    + 'if command -v ffplay >/dev/null 2>&1; then exec ffplay -nodisp -autoexit -loglevel quiet "$f"; fi; '
    + 'sleep 2; exit 3'

  property bool soundBroken: false
  property int soundFailures: 0

  function playSound(file) {
    if (root.soundBroken || soundProc.running) return
    soundProc.command = ["bash", "-c", root.soundScript, "pomodoro-sound", file]
    soundProc.running = true
  }

  Process {
    id: soundProc
    onExited: function(exitCode) {
      if (exitCode === 0) {
        root.soundFailures = 0
        return
      }
      root.soundFailures = root.soundFailures + 1
      if (exitCode === 3 || root.soundFailures >= 3) {
        root.soundBroken = true
        console.warn("pomodoro: could not play sound (missing pw-play/paplay/mpv/ffplay, or file unreadable); silencing")
      }
    }
  }

  // ---------------------------------------------------------- persistence
  readonly property string stateHome: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state"))
  readonly property string stateDir: root.stateHome + "/" + root.pluginId
  readonly property string statePath: root.stateDir + "/state.json"

  property bool dirReady: false
  property bool saveWanted: false

  // FileView does not create directories: saves queue in `saveWanted` until
  // this Process exits (same pattern as chime).
  Process {
    id: mkdirProc
    command: ["mkdir", "-p", root.stateDir]
    onExited: function(exitCode) {
      root.dirReady = true
      if (root.saveWanted) saveTimer.restart()
    }
  }

  FileView {
    id: stateFile
    path: root.statePath
    watchChanges: false
    atomicWrites: true
    printErrors: false
    // Restoring is literally a tick with a large gap: the same rule handles
    // suspend and shell restart. One code path, two scenarios.
    onLoaded: {
      root.ready = true
      root.adopt(Model.restore(text(), root.config, Date.now()))
    }
    onLoadFailed: {
      root.ready = true
      root.adopt(Model.restore("", root.config, Date.now()))
    }
    onSaveFailed: function(error) {
      console.warn("pomodoro: could not write " + root.statePath + ": " + String(error))
    }
  }

  Timer {
    id: saveTimer
    interval: 250
    repeat: false
    onTriggered: {
      root.saveWanted = false
      stateFile.setText(Model.serialize(root.timer))
    }
  }

  Component.onCompleted: mkdirProc.running = true

  // -------------------------------------------------------------------- IPC
  //
  // ONE handler here in the singleton service. The panel has
  // `manageIpc: false`: it exists per monitor, and registering the same target
  // twice (two monitors) would cause the same bug chime avoids this way.
  IpcHandler {
    target: "pomodoro"

    function open(): void { if (root.shell) root.shell.summon(root.pluginId, "{}") }
    function close(): void { if (root.shell) root.shell.hide(root.pluginId) }
    function toggle(): void { if (root.shell) root.shell.toggle(root.pluginId, "{}") }

    // `pause` only pauses and `start` only starts: a binding named "pause"
    // that starts counting would be a trap. `toggleRunning` toggles.
    function pause(): void { if (root.timer.clock.state === "running") root.dispatch("toggle") }
    function toggleRunning(): void { root.dispatch("toggle") }
    function start(): void { root.dispatch("start") }
    function skip(): void { root.dispatch("skip") }
    function restart(): void { root.dispatch("restart") }
    function reset(): void { root.dispatch("reset") }

    // Proves the plugin is alive without reading state.json.
    function health(): string {
      return JSON.stringify({
        phase: root.timer.phase,
        running: root.timer.clock.state === "running",
        remainingMs: Model.remainingMs(root.timer, root.nowMs),
        completedWork: root.timer.completedWork
      })
    }
  }
}
