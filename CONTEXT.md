# Omadoro

Omadoro is Omarchy's pomodoro, a timer that lives inside omarchy-shell.
This glossary fixes the names used by the code, tests and documentation
when discussing the timer.

## Language

**Phase**:
A continuous part of the cycle with its own duration. There are three: Focus,
Break and Long break.
_Avoid_: stage, period, session

**Focus**:
The work phase. Only a Focus that finishes naturally counts toward the
Long break cadence.
_Avoid_: work, working, pomodoro (as a phase)

**Break**:
The short rest phase that follows a Focus.
_Avoid_: interval, rest

**Long break**:
The longer break that replaces the Break after every N completed Focus phases.
_Avoid_: big break

**Cycle**:
The count of completed Focus phases since the last reset. Determines when
the Long break occurs.
_Avoid_: round, series, sprint

**Completed focus**:
A Focus that reached its end on the clock. Counts toward the Cycle.
_Avoid_: done focus, finished focus

**Skipped focus**:
A Focus ended with the skip button. Does not count toward the Cycle.
_Avoid_: canceled focus, aborted focus

**Clock**:
The timer's time state. It is either running and stores the end instant, or
paused and stores the remaining time. Never both.
_Avoid_: counter, stopwatch, countdown

**End instant**:
The absolute moment when the Phase ends while the Clock is running.
_Avoid_: end, deadline, final time

**Remaining time**:
How much time is left before the Phase ends. Derived from the End instant
while running, stored while paused.
_Avoid_: time left over

**Gap**:
An interval without ticks longer than the suspend threshold. Indicates that
the machine slept or the shell crashed. Rewinds the Phase to its full
length, paused, without a notification.
_Avoid_: hole, jump

**Heartbeat**:
The periodic recording of the last observed instant, solely to detect a Gap
after a restart.
_Avoid_: beat, keepalive

**Resynchronization**:
Adjustment of the Remaining time when a duration changes and the Phase is
paused at its full length. Running or partially elapsed phases do not change.
_Avoid_: resync, duration update

**Event**:
A change request to the reducer: tick, toggle, start, skip, restart, reset
or new configuration.
_Avoid_: action, command, message

**Effect**:
A consequence requested by the reducer and executed by the Service: persist,
notify or play sound.
_Avoid_: side effect, callback

**Chip**:
The plugin's item in the bar: ring plus MM:SS.
_Avoid_: bar widget, icon, module

**Popup**:
The window anchored to the Chip with the Pomodoro and Config tabs.
_Avoid_: panel, window, modal

**Inline entry**:
The plugin object inside the bar layout in `shell.json`, where the user's
configuration lives.
_Avoid_: settings, widget config

**Runtime state**:
Phase, Clock, Cycle and Heartbeat, saved in a dedicated file. Never goes
into the Inline entry.
_Avoid_: state, execution state
