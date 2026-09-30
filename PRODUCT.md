# PRODUCT.md

## What it is

Omadoro is Omarchy's pomodoro (Hyprland). A bar widget shows the progress
ring and countdown. Clicking opens a popup with two tabs: **Pomodoro**
(ring, pause, skip, restart) and **Config** (durations, auto-start). The
plugin runs inside omarchy-shell, with no binary of its own. The state
stores the instant when the phase ends, rather than a counter.

## Who uses it

One person: the machine's owner, a Linux/Hyprland developer, all day, on a
desktop with a dark theme. The popup appears for seconds (to adjust/check
the timer) and disappears.

## Register

`product`: the UI serves the task (controlling the timer) and should fade
into it. No decoration. Microinteractions only communicate state (running
or paused, focus or break, hover and press), 150 to 250 ms, with no blur or
heavy shadow. The widget lives inside the shell process, so compositing
cost matters.

## Visual identity

- No palette of its own. Colors come from the Omarchy theme through
  `Color.accent` and `Color.foreground`. Changing the theme changes the
  timer's color too.
- One color at three intensities: full `Color.accent` during focus,
  `Color.accent` at 55% during a break, `Color.foreground` at 55% when paused.
- Progress ring drawn with `QtQuick.Shapes`. Its thickness is 14 px in the
  popup. In the bar, the same component takes the icon slot's size.
- Font and scale come from the shell (`bar.fontFamily`, `Style.space`). No
  fixed pixel sizes outside the ring.

## Technical UI constraints

- QML inside omarchy-shell, through Quickshell. The view uses the shell's
  `Ui/` components (`Panel`, `KeyboardPanel`, `PanelKeyCatcher`, `PanelSlider`,
  `WidgetButton`, `ButtonGroup`), rather than custom controls.
- The popup is a `KeyboardPanel` rather than a `PopupCard`, because the
  Config tab has sliders and a switch that need keyboard focus, and because
  `Esc` only arrives through `PanelKeyCatcher`, which needs focus.
- No custom backdrop. Outside clicks and `Esc` come from the shell.
- The popup freezes its own clock while closed to avoid reevaluating
  bindings behind a window nobody sees.
- The bar's ring and MM:SS keep updating with the popup closed: the phase-end
  notification is the product and must fire without the window open.
