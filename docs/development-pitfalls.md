# Development pitfalls: mistakes already made here

- **No agent instruction files in the distributed repository.**
  `omarchy plugin add` clones the whole repository, and marketplace review
  rejected the root `CLAUDE.md` because Claude Code loads it automatically
  in any directory beneath it (issue #8386). This file is loaded into the
  local agent through a `CLAUDE.local.md` containing
  `@docs/development-pitfalls.md`, listed in `.git/info/exclude`.
- **`schemaVersion` is the number `1`, not the string `"1"`.** The string
  fails both validators (the host's and `omarchy-plugin-validate`), and the
  plugin cannot even be installed.
- **Symlinks inside the plugin directory are rejected by the validator**
  (`omarchy-plugin-validate:121`, except under `.git`). The development loop
  uses `rsync` through `scripts/dev.sh`, never a link from the repository to
  `~/.config/omarchy/plugins`.
- **`keepLoaded: true` freezes hot reload of `Service.qml`.**
  `unloadPluginServices()` deliberately skips services with `keepLoaded`, so
  after a reload the service keeps running the old code. `BarWidget.qml` and
  `Panel.qml` reload on save; `Service.qml` requires `omarchy restart shell`.
- **A `Loader` does not fill `required` properties.** `KeyboardPanel`
  declares `anchorItem` and `bar` as `required`, and an object that fails to
  construct results in a click with no effect and no error. That is why
  `Panel.qml` has a `Ui/Panel` root (zero `required` properties) with the
  `KeyboardPanel` nested inside, and the `BarWidget` injects properties
  manually after `onLoaded`, testing `"name" in target`.
- **A custom `MouseArea` never receives clicks.** The outer `MouseArea` of
  `ModuleSlot` swallows the press. The target must be a `Ui/WidgetButton`
  (or an item passed to `bar.registerClickTarget`); left, right and middle
  clicks arrive in the same `onPressed(button)`.
- **Only one `IpcHandler`, living in the `Service`.** `Panel.qml` uses
  `manageIpc: false`: there is one panel per monitor, and the automatic
  `Ui/Panel` handler would register the same IPC target twice on two screens.
  Window verbs go through `shell.summon`, `shell.hide` and `shell.toggle`.
- **`updateEntryInline` only patches the entry in place with
  `allowMultiple: false`.** With duplicate entries, the host rebuilds the
  widgets and the popup closes mid-drag. Save configuration on `released`,
  never on `moved`.
- **`seenAt` advances only on heartbeat and phase changes, not every tick.**
  Advancing `seenAt` on every tick prevents `now - seenAt` from reaching
  30 s: the heartbeat never fires, the last observed instant never reaches
  disk, and the 120 s gap after suspend is no longer detected.
- **The host returns `barConfig` one write behind.** `syncPluginApis` runs
  on `onShellConfigChanged` and reads `shell.barConfig` before the binding
  reevaluates; `FileView` does not reemit its own write. Measured across three
  consecutive clicks: the service always has the previous value. That is
  why the `Service` stores `pendingEntry` (the entry it just wrote) and
  `setConfig` starts from it rather than the host; otherwise the second
  slider reverts the first. Side effect: manual edits to `shell.json` only
  appear on the next write or restart.
- **After `scripts/dev.sh` without `--restart`, the popup draws the previous
  build while input goes to the new one.** Screenshots and clicks do not
  match; test pointer input only after `--restart`. There is no `ydotool`;
  the wlr virtual pointer (`zwlr_virtual_pointer_v1`, about 60 lines of C)
  moves and clicks without root, and `hyprctl dispatch movecursor` is broken
  (Lua parser).
- **`qmllint` and `qmltestrunner` exist only in `/usr/lib/qt6/bin`.** Nothing
  is on this machine's PATH: no stub and no Qt5 version. Never use
  `command -v qmllint`.
- **Expected `qmllint` noise.** `Unqualified access` and `missing-property`
  for `bar`, `shell` and `settings` refer to properties injected by the host:
  filter the output rather than trying to fix the code. The two third-party
  plugins used as precedents do the same.

## Agent skills

### Issue tracker

Issues live in this repository's GitHub Issues, accessed through `gh`. See
`docs/agents/issue-tracker.md`.

### Domain docs

Sole context: root `CONTEXT.md` and `docs/adr/`. See `docs/agents/domain.md`.
