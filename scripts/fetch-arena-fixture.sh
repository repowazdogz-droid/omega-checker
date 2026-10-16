#!/usr/bin/env bash
# Build the arena layout tests/arena.rs reads, from the pinned Lean Kernel Arena tests tarball.
#
#   scripts/fetch-arena-fixture.sh <dest> [local-tarball]
#
# arena.rs expects <dest>/_build/tests/<stem>.ndjson and <dest>/tests/<stem>.yaml with an
# `outcome:` line. The release tarball encodes the outcome by directory instead: good/ is
# accept, bad/ is reject, good/corner-cases/ has no prescribed outcome (either), as in
# scripts/gate.sh. The tarball is pinned by sha256; a mismatch is a hard failure.
set -euo pipefail
DEST="${1:?usage: fetch-arena-fixture.sh <dest> [local-tarball]}"
URL="https://github.com/leanprover/lean-kernel-arena/releases/download/round-2026-09/lean-arena-round-2026-09-tests.tar.gz"
SHA256="98a69742b538296c5f413d0527dfeef8c4d1815fe64b12c8623cd33de63bee0d"

mkdir -p "$DEST/_build/tests" "$DEST/tests" "$DEST/.src"
TARBALL="${2:-$DEST/.src/tests.tar.gz}"
[ -n "${2:-}" ] || curl -fsSL "$URL" -o "$TARBALL"
echo "$SHA256  $TARBALL" | shasum -a 256 -c -
tar xzf "$TARBALL" -C "$DEST/.src"

n=0
while IFS= read -r f; do
  rel="${f#"$DEST/.src/"}"
  stem="$(basename "$f" .ndjson)"
  case "$rel" in
    good/corner-cases/*) outcome=either ;;
    good/*) outcome=accept ;;
    bad/*) outcome=reject ;;
    *) echo "unexpected path $rel" >&2; exit 1 ;;
  esac
  cp "$f" "$DEST/_build/tests/$stem.ndjson"
  printf 'outcome: %s\n' "$outcome" > "$DEST/tests/$stem.yaml"
  n=$((n + 1))
done < <(find "$DEST/.src" -name '*.ndjson' | sort)
[ "$n" -gt 0 ] || { echo "no .ndjson exports found in the tarball" >&2; exit 1; }
echo "arena fixture: $n exports under $DEST"
