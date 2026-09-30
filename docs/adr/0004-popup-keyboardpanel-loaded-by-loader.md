---
status: accepted
---

# Popup with a Ui/Panel root and nested KeyboardPanel, loaded by Loader

The BarWidget loads the Popup through a `Loader`, and a `Loader` does not
fill `required` properties. `KeyboardPanel` declares `anchorItem` and `bar`
as `required`, so it cannot be the root. We decided that the root of
`Panel.qml` is a `Ui/Panel` with no required properties, with the
`KeyboardPanel` nested inside. The BarWidget injects `bar`, `service`,
`anchorItem` and `hostWidget` after `onLoaded`, testing `"name" in target`.
We chose `KeyboardPanel` rather than `PopupCard` because `Esc` only arrives
through `PanelKeyCatcher`, which needs focus, and `PopupCard` has no focus.

## Consequences

- `switchPanel` needs an override to pass the slot widget to the host;
  otherwise `Tab` inside the Popup does nothing.
- Saving `Panel.qml` may serve an old copy until the shell restarts.
