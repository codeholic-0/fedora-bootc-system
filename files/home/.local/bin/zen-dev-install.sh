#!/bin/bash
# zen-dev installer — fetches the latest zen-dev into ~/.local/bin.
#
# Usage (documented one-liner, works on any flavor):
#   curl -fsSL https://raw.githubusercontent.com/codeholic-0/zen-bootc/main/files/home/.local/bin/zen-dev-install.sh | bash
#
# Trust posture: latest main over TLS — the same class as the upstream
# installers zen-dev itself drives (brew/sdkman/nvm). The OS image keeps
# its full cosign/policy chain; this is user tooling in $HOME.
set -eu

URL="https://raw.githubusercontent.com/codeholic-0/zen-bootc/main/files/home/.local/bin/zen-dev"
TARGET="$HOME/.local/bin/zen-dev"

mkdir -p "$(dirname "$TARGET")"
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
curl -fsSL "$URL" -o "$tmp"
bash -n "$tmp"
grep -q '^# zen-dev' "$tmp"   # never install a 404 page / wrong file
mv "$tmp" "$TARGET" && chmod 0755 "$TARGET"

case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) echo "zen-dev: note: $HOME/.local/bin is not in PATH" >&2 ;;
esac
echo "zen-dev installed at $TARGET"
echo "  zen-dev            list tools + install state"
echo "  zen-dev update     self-update from the repo"
