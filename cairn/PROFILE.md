# Toolchain profile: generic

<!-- A cairn *toolchain profile*: the language/toolchain-specific slots the
     operational skills read. cairn-init instantiates the chosen reference
     profile into the repo's `cairn/PROFILE.md`. The oracle / Validation
     doctrine is UNIVERSAL and deliberately NOT a slot here — it is the
     orthogonal domain axis (D-024/D-025), stated once in
     skills/shared/validation-doctrine.md (referenced from tracking-rules).
     Every profile defines all seven `## <slot>` sections below; a slot with no
     toolchain-specific content says so explicitly rather than being omitted
     (cairn_validate FAILs on a missing or empty slot). -->

The language-agnostic default: cairn's core with no toolchain-specific gates.
Selected by `cairn-init` when no `DESCRIPTION` (or other recognized toolchain
marker) is present. A repo replaces the placeholder in `verify` with its own
test command; the other slots stand as-is until a richer profile is authored.

## verify
The command(s) `/milestone-implement` and `/hotfix` run to check a task before
ticking it off:

    tests/run-tests.sh

Add `--self-test` to also run the planted-defect self-test (one manifest
entry removed, one altered, one spurious added), which the pre-review check
uses:

    tests/run-tests.sh --self-test

The script fails loudly (`set -euo pipefail`) and refuses to skip its
end-to-end PDF check: a missing TinyTeX, `makeindex`, or `pdftotext` is an
error, never a silent pass.

## consistency-gate
Toolchain checks `/milestone-review` runs *in addition to* the universal
cairn-file checks (`cairn_validate`, coverage completeness, `cairn_impact`).
Generic default: **none** — the universal cairn-file checks are the whole
consistency gate.

## test-doctrine
Toolchain-specific test expectations layered on the universal "What gets a
test" rules in tracking-rules. Generic default: **none beyond the universal
rules** — every bug fix gets a regression test, every documented claim a test,
contract-not-implementation, and the oracle doctrine for any numeric result.

## release-walk
The release procedure `/cairn-release` follows. Generic default: a minimal
language-agnostic walk — no package-registry submission; the tag is the release:
- Decide the version bump (patch/minor/major) from the declared changelog
  (`## changelog` slot; "none" → derive the bump from git history).
- Consolidate the declared changelog: retitle the dev heading to the version,
  group entries, prune noise ("none" → skip this step).
- Bump the repo's version marker and commit the release prep to the default
  branch (docs/metadata only).
- Tag `v<version>` and push the tag at the user's approval — no registry step.
- Where the `origin` remote is GitHub and `gh` is available, the handoff also
  provides a `gh release create` command whose body is the new changelog
  section (provided, never run — the universal step 4).

## init-detection
How `cairn-init` recognizes this toolchain. Generic is the **fallback**: no
`DESCRIPTION` and no other recognized toolchain marker.

## greenfield-openers
Opener questions `cairn-init` asks in a new/empty repo of this type. Generic
default: **no language-specific openers** — the universal opener layer
(distribution ambition, rendered here as a **tagged public release** vs.
internal-only choice, and numeric-work-needs-oracle-verification) is the whole
greenfield flow for a generic repo; a richer profile adds its own on top.

## changelog
The repo's changelog file, read by `/hotfix`, the release-walk, and the
consistency-gate:

    CHANGELOG.md

Added at the 0.1.0 release, whose section is the file's first. Entries are
grouped under the version heading by what they touch (marking syntax, output,
project), and name behavior rather than milestones — the DESIGN "changelog
discipline from the start" commitment, which had no file until then.
