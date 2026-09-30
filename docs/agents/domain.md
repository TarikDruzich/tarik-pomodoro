# Domain docs

How engineering skills consume this repository's domain documentation.

## Before exploring, read

- Root `CONTEXT.md`: the glossary. The sole context.
- `docs/adr/`: the decisions affecting the area you will change.

If a file does not exist, continue silently. `/domain-modeling` creates
both when a term or decision is actually resolved.

## Structure

```
/
├── CONTEXT.md
├── docs/
│   ├── adr/
│   │   ├── 0001-pure-qml-plugin-without-binary.md
│   │   └── ...
│   ├── agents/
│   └── publishing-to-marketplace.md
└── *.qml, Model.js
```

## Use the glossary's vocabulary

When text names a domain concept (issue title, test name, hypothesis), use
the term as defined in `CONTEXT.md`. Do not drift toward the synonyms listed
under `_Avoid_`. A concept without a glossary entry is a signal: either it
is invented language, or it is a gap for `/domain-modeling`.

## Flag conflicts with ADRs

If the output contradicts an ADR, say so explicitly rather than overriding it:

> _Contradicts ADR-0003 (single IPC handler in Service), but is worth reopening because..._
