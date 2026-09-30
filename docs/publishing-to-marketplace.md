# How to publish and update the plugin in the Omarchy marketplace

This guide covers the first listing at <https://plugins.omarchy.org> and
subsequent updates. Sources: `SUBMISSION.md`, `SECURITY.md` and
`VERIFICATION.md` from `omacom/omarchy-plugin-marketplace`, read on 2026-09-15.

## Listing status

- 2026-09-15: first submission opened by larissa, issue
  [omacom/omarchy-plugin-marketplace#7069](https://github.com/omacom/omarchy-plugin-marketplace/issues/7069),
  category Productivity, tags bar and quickshell.
- 2026-09-23: #7069 closed because `master` advanced after validation.
  New submission at
  [omacom/omarchy-plugin-marketplace#8386](https://github.com/omacom/omarchy-plugin-marketplace/issues/8386).
  Review requested removing the root `CLAUDE.md`; its content moved to
  `docs/development-pitfalls.md`.

A push to `master` after validation invalidates the submission. After every
push, edit the issue body with the new SHA to rerun the bots.

Update this list after every submission, verification or commit promotion.

## What the marketplace requires from the repository

- Public GitHub repository, submitted using its root URL, without `/tree/...`.
- A single plugin, with `manifest.json` at the root.
- Root README with installation and removal instructions.
- Root license file and documented external dependencies.
- Unique id outside the `omarchy.*` namespace. The id is permanent: a listed,
  retired or renamed id never becomes available again (ADR-0006).
- Optional: a root `preview.png` image (or jpg, jpeg, webp, avif). The
  marketplace resizes it automatically. Limit: 50 MB and 40 megapixels.

This repository has met all these requirements since PR #4 was merged.

## What automatic validation checks

Submission opens an issue in the marketplace repository. A bot validates
the current commit of the default branch: repository structure, manifest
and compatibility with Omarchy Quattro. This is not a security review.

A second bot, the Automated Security Baseline, reads the same commit without
executing anything and looks for a fixed set of patterns: downloading
directly into a shell, `cargo install --git` without `--rev`, executing
external git code without a pinned commit, dangerous sudoers `NOPASSWD`,
and privileged process control using a PID in `/tmp`. It also flags
capabilities requiring human review: installers, package managers, `sudo`
or `pkexec`, remote builds, executable binaries, `systemctl` or `systemd-run`,
and sudoers. This plugin uses none of them. The expected result is `passed`.

A maintainer then applies `approved-and-verified`, and the listing goes live
linked to the exact validated SHA.

## Submit for the first time

1. Confirm that `master` contains everything to be listed. A new branch
   commit after validation invalidates the validation.
2. Activate the repository owner's account in `gh`:

   ```bash
   gh auth switch --user larissa04alves
   ```

3. Write the issue body. The six sections must appear in this order, and
   the wording of the five checklist items must remain unchanged:

   ```markdown
   ### Repository URL

   https://github.com/larissa04alves/omadoro

   ### Category

   Productivity

   ### Tags

   bar, quickshell

   ### Suggest a missing tag

   _No response_

   ### Maintainer notes

   Runs entirely inside omarchy-shell (QML + JS, no binary, no build step).
   Writes only its own state file under $XDG_STATE_HOME/larissa04alves.omadoro/
   and its own inline entry in shell.json through the shell API. Sound uses
   whichever of pw-play, paplay, mpv or ffplay exists; notifications use
   omarchy-notification-send. scripts/ and test/ are development-only.

   ### Submission checklist

   - [x] The repository is public and contains installation and removal instructions.
   - [x] I have documented the plugin license and any external dependencies.
   - [x] I confirm that I own or have permission to submit this plugin and its preview assets.
   - [x] The plugin does not overwrite user configuration without explicit consent.
   - [x] I understand that approval is for listing and is not a security review.
   ```

   Valid categories: Appearance, Desktop, Developer Tools, Hardware, Kids,
   Productivity, System, Widgets, Other. Valid tags, one to three: ai,
   bar, education, games, hyprland, kids, launcher, media, power-management,
   quickshell, security, system, workspaces.

4. Open the issue using the form at
   <https://github.com/omacom/omarchy-plugin-marketplace/issues/new?template=submit-plugin.yml>
   or the CLI:

   ```bash
   gh issue create \
     --repo omacom/omarchy-plugin-marketplace \
     --title "[Plugin]: Omadoro" \
     --body-file /tmp/omarchy-plugin-submission.md
   ```

5. Follow the issue. The bot maintains validation and security baseline
   comments, updating them on every attempt. If something fails, fix the
   repository or edit the issue. Do not open a second submission.

## Update the listing after a merge

The listing points to an exact SHA. When `master` advances, the marketplace
shows "Update unverified" until someone requests promotion of the new commit.

1. Record the full SHA of `master`: `git rev-parse origin/master`.
2. Open the verification form at
   <https://github.com/omacom/omarchy-plugin-marketplace/issues/new?template=verify-plugin.yml>,
   choose "Verify and publish a newer upstream commit" and provide id
   `larissa04alves.omadoro`, the repository's root URL and the SHA.
3. The same two bots run on the new commit. The old listing stays live until
   a maintainer approves it.

The `omarchy plugin add` and `omarchy plugin update` commands clone the
branch HEAD rather than the listed SHA. Installers always receive current `master`.
