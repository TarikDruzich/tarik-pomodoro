---
status: accepted
---

# Runtime state in a dedicated file, inline configuration in shell.json

Runtime state changes every 30 seconds while the timer runs. User
configuration changes a few times a week. We decided to separate by owner
and cadence: State goes to `$XDG_STATE_HOME/<id>/state.json` through
`FileView` with atomic writes, and durations stay in the plugin's Inline
entry in `shell.json`, written only through `updateEntryInline`. A single
file for everything would require rewriting the user's bar layout at every
Heartbeat, while a second configuration file would create a second source
of truth alongside the one read by `omarchy bar set`.

## Consequences

- Changing the plugin id changes the State directory. The timer starts over paused.
- The Service reads configuration through the host facade and never copies it locally.
