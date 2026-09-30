# Issue tracker: GitHub

Issues and specs for this repository live in GitHub Issues at
`larissa04alves/omadoro`. Every operation uses the `gh` CLI inside the clone,
which infers the repository from `git remote`.

## Conventions

- **Create an issue**: `gh issue create --title "..." --body "..."`. Use a
  heredoc or `--body-file` for multiline bodies.
- **Read an issue**: `gh issue view <n> --comments`.
- **List**: `gh issue list --state open --json number,title,body,labels`.
- **Comment**: `gh issue comment <n> --body "..."`.
- **Labels**: `gh issue edit <n> --add-label "..."` and `--remove-label "..."`.
- **Close**: `gh issue close <n> --comment "..."`.

## Pull requests as a request channel

**PRs as requests: no.** Change to `yes` if external PRs become feature
requests; `/triage` reads this flag.

## When a skill says "publish to the issue tracker"

Create a GitHub issue.

## When a skill says "fetch the ticket"

Run `gh issue view <n> --comments`.

## Account

The repository belongs to larissa. Actions attributed to the owner
(marketplace submissions, releases) use her active `gh` account:
`gh auth switch --user larissa04alves`.
