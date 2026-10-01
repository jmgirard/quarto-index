<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M103: The two site-check clauses M46 withdrew hold again

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP6
- **Resolves:** —
- **Surface tier:** internal, because it changes checks over the repo's own documentation site and no author-facing behavior
- **Branch/PR:** —

## Goal

The site link check and the pre-release sweep report every link and page they
read, where today one link shape escapes the capture and one page shape
raises an exception.

## Scope

**In:** the two clauses M46's descope amendment withdrew, from the candidate
row the 2026-09-30 status audit promoted. `tests/sitecheck.py links` resolves
a link against the regular files that a walk of the capture lists, in place of
the symlink-resolving containment test (KI153). The base-segment test runs on
the normalized path (KI158). The pre-release sweep reports a page that does
not decode as UTF-8, by name, where today it raises (KI152).

**Out:**

- A tracked path whose name does not decode as UTF-8 (KI156) stays on the
  candidate row. This Mac's file system refuses such a name, so no plant can
  build one here.
- The publishing path (KI160, KI161, KI162) leaves the candidate row and
  stays in DESIGN.md Known issues, by the plan gate's choice. Each one needs
  a scan of the workflow source or a real deploy run.
- The gallery checks, the book-log partition gaps in `tests/m29book.py`
  (KI84, KI85), the floor (KI155) and the claim ledger (KI249) stay on the
  candidate row.

## Acceptance criteria

- [ ] AC1: `tests/sitecheck.py links` counts the path part of a link as
      resolved only if its normalized target, or that target joined with
      `index.html`, is in one set. The set holds the regular files, not
      symlinks, that one `os.walk` of the capture lists without following
      directory links. The claim covers the definition of `check_links`,
      read top to bottom: no other call in it reads the file system to
      decide resolution.
- [ ] AC2: `tests/sitecheck.py links` reports each link below with a report
      line that contains `names no file under`:
  - `../outside.html`
  - `/sub/../../outside.html`
  - a link through a symlink inside the capture that points above it
  - a link through a symlink inside the capture that points inside it
    (`alias/syntax.html`, where `alias` links to the capture root)
  - a link to a directory whose `index.html` is a symlink to a file above
    the capture

      A relative link and a directory link to pages that the render wrote
      still resolve, and the unplanted capture passes.
- [ ] AC3: The base-segment test reads the normalized path. Under base path
      `docs`, `/./docs/index.html` resolves. Under base path `docs`,
      `/docs/../index.html` and `/docs/sub/../../outside.html` are each
      reported with a line that contains `carries no`.
- [ ] AC4: Run the `prerelease-absent` and `phrase-absent` modes of
      `tests/sitecheck.py` with an overlay that holds a domain page that
      does not decode as UTF-8. Each mode exits non-zero and prints a
      failure report, and one line of that report names the page. Neither
      mode prints a Python traceback.
- [ ] AC5: The `verify` slot in `cairn/PROFILE.md` runs clean, with
      `--self-test`.

## Coverage

- AC1 → T1
- AC2 → T1, T2
- AC3 → T1, T2
- AC4 → T3
- AC5 → T4

## Tasks

- [ ] T1: Rewrite the resolution in `check_links` (`tests/sitecheck.py:241`)
      over the walked set of regular files. Normalize the path before the
      base-segment test. Delete the `realpath` and `abspath` containment
      branch and its comments. Keep the `looked for` clause that the
      encoded-absolute plant reads.
- [ ] T2: In `tests/run-tests.sh`, each link plant gets its own copy of the
      captured site through `m40_plant_link`. Point the escape plants at the
      `names no file under` report, and the base-path escape plant at the
      `carries no` report. Invert the `linkinsidelink` plant, which today
      requires the link to resolve. Add a plant for the directory
      `index.html` symlink and the two base-normalization cases. Show that
      the pre-change `sitecheck.py` exits 0 on the directory symlink plant,
      so that plant fails against the old code.
- [ ] T3: Make `sweep_rows` (`tests/sitecheck.py:569`) report a page that
      does not decode as UTF-8 as unreadable, by name. Add one plant per
      mode with a non-UTF-8 page that also carries a retired sentence. Show
      each plant raising a traceback against the pre-change code.
- [ ] T4: Records. Write a D-entry that supersedes the D-029 withdrawal of
      the report clause. Update the site-check paragraph of DESIGN.md
      (near line 770) and strike KI152, KI153 and KI158. Run the `verify`
      slot with `--self-test`.

## Work log

- 2026-09-30: created by /milestone-plan, from the candidate row the status audit promoted.
- 2026-09-30: criteria audit (reduced mode, internal tier) returned three wording fixes, all made: the base-path escape moved to AC3, AC4 names the page on a report line rather than the `FAIL:` line, and T2 says the new plant fails against the old code. It also found the `linkinsidelink` plant, which the gate settled.
- 2026-09-30: plan gate chose resolving links against the walked file set over patching the containment test in place, because the containment code failed four times in M46 and a fifth patch keeps its shape; falsified by a Quarto render that writes a symlink into the site.
- 2026-09-30: plan gate chose failing on a non-UTF-8 page, by name, over sweeping it with bad bytes replaced, because a docs page with bad bytes is a defect in its own right; falsified by a tracked docs page that legitimately holds non-UTF-8 bytes.

## Decisions

## Review
