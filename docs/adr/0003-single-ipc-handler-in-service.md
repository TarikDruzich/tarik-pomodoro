---
status: accepted
---

# One IpcHandler in the Service; the Popup registers no IPC target

`Ui/Panel` provides an IPC target automatically, but the Popup exists once
per monitor. With two monitors, the same target would be registered twice
and the shell would discard one. We decided that the sole `IpcHandler`
lives in the singleton Service, with `manageIpc: false` on the Popup. Window
verbs (`open`, `close`, `toggle`) go through the plugin's own `shell.summon`,
`shell.hide` and `shell.toggle`, which route to the correct monitor. This is
the same arrangement used by the Chime plugin and nine first-party shell panels.
