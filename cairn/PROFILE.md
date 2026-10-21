# Toolchain profile: quarto-extension

<!-- From cairn's quarto-extension reference profile. The oracle doctrine is
     universal and not a slot. cairn_validate FAILs on a missing or empty slot. -->

The deliverable is the Quarto filter extension `_extensions/index/`. Users
install it with `quarto add jmgirard/quarto-index`, which reads `main`, so a
merge reaches users at once. A `v<version>` tag and a GitHub release mark the
version for `quarto add jmgirard/quarto-index@v<version>`.

## verify
`/milestone-implement` and `/hotfix` run this on a task before they tick it:

    tests/run-tests.sh

The pre-review check adds `--self-test`, which also runs the planted-defect
self-test (one manifest entry removed, one altered, one spurious added):

    tests/run-tests.sh --self-test

The script fails loudly (`set -euo pipefail`). A missing TinyTeX, `makeindex`,
or `pdftotext` fails its end-to-end PDF check, never a silent skip.

Run it SEQUENTIALLY, never two invocations at once. The script does
`rm -rf "$WORK"` at startup, so a second run wipes the first's work directory
mid-flight. The abort then surfaces as an unrelated missing-artifact failure
in whatever check reads next, not as a collision (M46 review round 3). A
reviewer or subagent that needs one check's behavior extracts it into its own
scratch directory instead of invoking the suite. The Claude desktop app can
report a background command as finished while its suite still runs (M122).
Before you start another run, look in `ps` for a live `bash tests/run-tests.sh`.

Do not edit `tests/run-tests.sh` while a run reads it from the same checkout.
Bash reads a script by byte offset as it goes, so an edit can break the run in
progress (M108). Two runs in separate git worktrees are safe, each with its
own `tests/.work`. M108 ran Quarto 1.5.52 and 1.10.18 side by side that way.

Quarto 1.10.18 sometimes crashes during a suite render. The log shows
`Segmentation fault: 11` from Quarto's own Deno at `/usr/local/bin/quarto`
line 210, and the check that rendered fails with "failed to render". M109 saw
it twice, on renders the branch did not change, and each re-run passed. If a
run fails this way, re-run it before you read the failure as the change's.

The suite needs a `python3` with PyYAML (D-030). On this machine the first
`python3` on `PATH`, `/usr/local/bin/python3`, has none (observed 2026-10-10,
M110), and the run stops at its PyYAML check. For the run, put a `python3`
link to `/usr/bin/python3` first on `PATH`.

## consistency-gate
Toolchain checks `/milestone-review` runs *in addition to* the universal
cairn-file checks (`cairn_validate`, coverage completeness, `cairn_impact`):
- Every version marker that `release-walk` names holds the same version.
- The `verify` command succeeds on the review head.
- The declared changelog (`## changelog` slot) has an entry for this
  milestone's user-visible changes. A milestone whose work log carries a
  `feature series:` line is in a series (tracking-rules "Feature series").
  Where the series has an entry, such a milestone edits that entry. A
  milestone before the series' last with no user-visible change needs no entry.

## test-doctrine
Test expectations layered on the universal "What gets a test" rules in
tracking-rules. An extension is tested by rendering, not by calling functions:
- To test a filter change, render a fixture document that uses it and read
  the output (a string in the output, or a snapshot of it).
- A bug fix gets a fixture document that renders wrong before the fix.
- The extension ships no JavaScript or CSS that browsers cache by a versioned
  path, so no asset change raises the version.

## release-walk
The release procedure `/cairn-release` follows. The one version marker is
`version:` in `_extensions/index/_extension.yml`, and it rises at release, not
at merge. Before step 1 of `/cairn-release`, run `git fetch --tags <base>`.
Then read the remote default branch's tip:
`python3 "${CLAUDE_PLUGIN_ROOT}/scripts/cairn_versions.py" _extensions/index/_extension.yml --at <base>/main`.
If `CLAUDE_PLUGIN_ROOT` is unset, use the cairn plugin's install directory.
The script refuses a shallow clone. It prints the tip's version, the first
commit of that version's unbroken run of first-parent commits (`start`), and
whether a `v<version>` tag exists.
- **Release-time arm** (tag present, the usual case). Decide the bump
  (patch/minor/major) from `CHANGELOG.md`. Retitle its development heading to
  the version, group entries, and prune noise. Raise the marker and commit the
  release prep to `main`. At the user's approval, tag that commit
  `v<version>` and push the tag.
- **Tag-only arm** (tag absent). The tip's version is unreleased. Raise
  nothing and make no prep commit. Find the `CHANGELOG.md` section at the
  remote tip whose heading names the version (`## 1.2.9`, not `## 1.2.90`).
  Step 1 asks the user to approve the version and `start` (its subject)
  instead of choosing a bump. Step 2 makes no edit, but its
  claim-read runs on that section against the code at `start`. At the user's
  approval, tag the run's start with `git tag -a v<version> <start>
  -m "v<version>"` and push the tag.
- **Stops.** A changelog with no section for the version, a false claim, or the
  user's refusal ends the run with the reason and no tag. A merged changelog
  edit clears a missing section or a false claim: retitle the development
  heading, reword the claim, or move a later entry back under the development
  heading. Then run `/cairn-release` again.
- **Release notes.** The notes are the `CHANGELOG.md` section for the
  version. Where `gh` is available, the handoff gives a `gh release create`
  command with these notes. cairn never runs it (the universal step 4). No
  registry step applies: the tag is the release.

## init-detection
`cairn-init` picks this profile from `_extensions/*/_extension.yml` or `.yaml`
with no language, plugin, or `Dockerfile` marker. This repo adopted cairn on
the generic profile and moved to this one after the 0.5.0 release.

## greenfield-openers
None apply, because this repo is past greenfield. The reference openers are
settled above: the extension is a filter, and its version rises at release.

## changelog
The repo's changelog file, read by `/hotfix`, the release-walk, and the
consistency-gate:

    CHANGELOG.md

The 0.1.0 release added it. Entries are grouped under the version heading by
what they touch (marking syntax, output, project). They name behavior rather
than milestones, per the DESIGN commitment to "changelog discipline".
