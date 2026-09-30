---
status: accepted
---

# Always-active SystemClock, precision bound to a plain bool

The phase-end notification is the product and must fire with the Popup
closed, so the Service always ticks, using a `SystemClock` that follows
wall-clock time and corrects itself after suspend. Precision drops to
minutes when the timer is stopped. We decided to bind precision to a
`property bool running` written in `adopt`, rather than `view.running` or
`timer.clock.state`. Both derived forms close a binding loop that the shell
logs as "Binding loop detected", measured live for both. The bool duplicates
a value the model considers derived, and this is deliberate.

## Consequences

- When stopped, the clock only ticks once per minute. Every user Event
  refreshes `nowMs` before the reducer; otherwise the new Phase is shortened
  by up to 59 seconds.
