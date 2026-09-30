---
status: accepted
---

# Pure QML plugin, no Rust binary

The timer started as a Rust CLI without a daemon because Waybar has no
memory between ticks. omarchy-shell is a resident process that mounts one
Service per plugin, so that premise no longer held. We decided to port the
state machine to `Model.js` and remove Rust. `omarchy plugin add` has no
build step, and a binary would have to be a committed blob per architecture.
The 28 `cargo test` tests were ported under the same names to
`test/model.test.js` before any QML existed, and serve as the port's oracle.

## Considered Options

- Keep `pomo` as a child process communicating through stdout, as agent-bar
  does. Rejected because it creates a second owner of state and a wire
  format between the two.
- Call `pomo` through `Process` every second. Rejected because of its cost
  and because it keeps two writers on the same file.
