#!/usr/bin/env bash
#
# REVIEW-TIME EVIDENCE, NOT A CHECK: the LaTeX back-end's output is unchanged.
#
# A checked-in golden `.tex` would be a snapshot, which run-tests.sh's ORACLE
# RULE forbids. This renders every fixture the merge base carries, twice on one
# machine — once with this branch's filter, once with the merge base's — and
# compares the two `.tex` files byte for byte. The expected diff is empty.
#
# The fixture list comes from the MERGE BASE's own tree, so a fixture this
# branch adds cannot quietly narrow the loop.
#
# Usage:  tests/byte-diff.sh

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

FILTER=_extensions/index/index.lua
WORK=tests/.work/byte-diff

DEFAULT=$(git symbolic-ref --short refs/remotes/origin/HEAD | sed 's|^origin/||')
BASE=$(git merge-base HEAD "$DEFAULT")

[ -z "$(git status --porcelain -- "$FILTER")" ] \
  || { printf 'FAIL: %s has uncommitted changes; commit them first, or the "branch" render is not the branch.\n' "$FILTER" >&2; exit 1; }

# The branch's filter is checked out again whatever happens below, so an
# interrupted run never leaves the merge base's filter in the working tree.
restore() { git checkout HEAD -- "$FILTER"; }
trap restore EXIT

rm -rf "$WORK"
mkdir -p "$WORK/base" "$WORK/branch"

FIXTURES=$(git ls-tree --name-only "$BASE" examples/ | grep '\.qmd$')
[ -n "$FIXTURES" ] || { printf 'FAIL: the merge base carries no fixtures to render.\n' >&2; exit 1; }

render_all() {
  local into="$1" fixture name
  for fixture in $FIXTURES; do
    name=$(basename "$fixture" .qmd)
    quarto render "$fixture" --to latex > "$WORK/$name-$into.log" 2>&1 \
      || { tail -20 "$WORK/$name-$into.log" >&2; printf 'FAIL: %s failed to render to LaTeX with the %s filter.\n' "$fixture" "$into" >&2; exit 1; }
    cp "examples/$name.tex" "$WORK/$into/$name.tex"
  done
}

printf 'merge base: %s\n' "$BASE"
printf 'fixtures:\n%s\n\n' "$FIXTURES"

render_all branch
git checkout "$BASE" -- "$FILTER"
render_all base
restore

STATUS=0
for fixture in $FIXTURES; do
  name=$(basename "$fixture" .qmd)
  if diff -u "$WORK/base/$name.tex" "$WORK/branch/$name.tex" > "$WORK/$name.diff"; then
    printf 'ok   %s.tex is byte-identical to the merge base\n' "$name"
  else
    printf 'DIFF %s.tex differs from the merge base (%s)\n' "$name" "$WORK/$name.diff"
    head -40 "$WORK/$name.diff"
    STATUS=1
  fi
done

git status --porcelain -- "$FILTER" | grep -q . \
  && { printf 'FAIL: %s was left modified; the branch filter was not restored.\n' "$FILTER" >&2; exit 1; }

[ "$STATUS" -eq 0 ] \
  && printf '\nEvery merge-base fixture renders byte-identically.\n' \
  || printf '\nAt least one fixture changed; read the diffs above.\n'
exit "$STATUS"
