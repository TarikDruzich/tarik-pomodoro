#!/bin/bash
# Copy this checkout into ~/.config/omarchy/plugins/<id>, as
# `omarchy plugin add` would (the validator rejects symlinks inside the
# plugin directory, so a symlink to the repo cannot be used for development).
#
#   scripts/dev.sh                       # sync + validate + rescan
#   scripts/dev.sh --restart             # also restart the shell
#   scripts/dev.sh --enable [placement]  # also enable the bar widget,
#                                         # e.g.: --enable --after omarchy.clock
#
# BarWidget.qml e Panel.qml recarregam a quente (~150ms). Service.qml só
# recarrega com a shell reiniciada: `keepLoaded: true` é o que mantém o
# timer contando com o widget desmontado, e é o que impede o hot-reload do
# serviço (shell.qml:1024-1049) — daí o --restart.
set -euo pipefail

usage() {
  sed -n '2,11p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

restart=0
enable=0
placement=()
while (($# > 0)); do
  case "$1" in
    --restart) restart=1; shift ;;
    --enable) enable=1; shift; placement=("$@"); break ;;
    -h|--help) usage; exit 0 ;;
    *) echo "dev: unknown option '$1'" >&2; usage >&2; exit 2 ;;
  esac
done

here=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
command -v jq >/dev/null || { echo "dev: jq not found" >&2; exit 1; }
id=$(jq -r '.id' "$here/manifest.json")
dest="$HOME/.config/omarchy/plugins/$id"

mkdir -p "$dest"
rsync -a --delete --exclude '.git' --exclude 'test' --exclude 'scripts' --exclude '.verify' --exclude 'CLAUDE.local.md' "$here/" "$dest/"
omarchy plugin validate "$dest"
omarchy-shell -q shell rescanPlugins

if ((restart)); then
  if ! omarchy restart shell >/dev/null 2>&1; then
    echo "dev: synced, but 'omarchy restart shell' failed" >&2
    exit 1
  fi
fi

if ((enable)); then
  sleep 1
  omarchy plugin enable "$id" "${placement[@]}"
fi

echo "Installed $id into $dest"
