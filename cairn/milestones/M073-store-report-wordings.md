# M073: A store report names the record it met as the record it was

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2, GP1
- **Resolves:** —
- **Branch/PR:** `m073-store-report-wordings`

## Goal

In an HTML book, a record no render has written whose chapter's source also
cannot be read is reported as one no render has written rather than as one that
could not be read, and a record file that decodes to a table carrying no
version number this render recognizes is reported as one that could not be read
rather than as one another version of this extension wrote.

## Scope

Surface tier: **user-facing** — the deliverable is the warning text an
installed extension prints to an author, and the site prose about it.

**In:** the two record states the code mis-names. A sixth wording for a
never-written record whose chapter source cannot be read, drawn where the other
never-written wordings are drawn today; and a version test that fires only on a
record carrying a version number this render does not write, so a truncated or
hand-emptied record joins the wordings for a record that could not be read.
The superseding decision each change needs, the site and changelog prose, and
the suite legs and planted defects for both.

**Out:** where the never-written reports are drawn and how often → M074.
The n(n-1) source parsing a store-less book pays (KI227) → stands.
The `first == nil` gate half never exercised for a refused entry (KI237) →
stands as its known issue.

## Acceptance criteria

- [ ] AC1: In an HTML book, a chapter that reads the store, meets a record no
      listing of the store directory carries, and cannot read that chapter's
      own source draws a report naming the chapter, saying no render has
      written a record for it and that its source could not be read either;
      the message is neither equal to nor a prefix of any other `warn()`
      message in the filter source, which `tests/scans/warn-distinct.py`
      holds. Evidence: the `m069-lostsource` leg (`tests/run-tests.sh:9071`)
      counts the new wording's grep key once and `WARN_STORE_UNREADABLE_LOST`
      zero times.
- [ ] AC2: A record that WAS written, cannot be decoded, and whose chapter's
      source also cannot be read keeps the wording naming both. Evidence: a
      new leg over a copy of `examples/book-placement` that overwrites one
      chapter's record with bytes that do not decode as JSON and breaks that
      same chapter's source, rendering one named other chapter alone, counts
      `WARN_STORE_UNREADABLE_LOST` once and AC1's key zero times.
- [ ] AC3: A record file that decodes to a JSON table whose `version` field is
      absent, and one whose `version` is not a number, are both reported by
      the wordings for a record that could not be read and by none of the
      three different-version wordings. Evidence: three new legs over a filled
      `examples/book-extensions` copy rewriting `one.qmd`'s record — the
      `version` field deleted and every other field left as written, `version`
      as a string, `version` as a boolean — each rendered from `index.qmd`
      alone, counting the three `WARN_STORE_STALE_*` keys at zero and
      `WARN_STORE_UNREADABLE_RECOVERED` at one.
- [ ] AC4: A record carrying a numeric `version` this render does not write is
      still reported as one a different version of this extension wrote, at
      the count it has now. Evidence: the `m072` `version` leg
      (`tests/run-tests.sh:24505`) passes with its counts unchanged.
- [ ] AC5: The store-reports section of `site/books.qmd` and the unreleased
      section of `CHANGELOG.md` state the wording set and the version-field
      partition as the shipped code has them: a grep over those two regions
      returns no sentence saying a record carrying no version is read as one
      another version wrote, and the books page's claim ledger
      (`tests/run-tests.sh:21763`) carries a row for each sentence added.
- [ ] AC6: `tests/run-tests.sh` passes; `tests/run-tests.sh --self-test`
      passes, and its M073 battery shows red against the pre-fix code each
      plant names: (a) the never-written-and-unreadable-source branch
      collapsed back into the shared could-not-be-read wording, (b) the
      classification test at `book.lua:1008` restored to
      `data.version ~= STORE_VERSION`, pinned by its `ok and type(data) ==
      "table"` context rather than by the same text in `valid_record`, and
      (c) that test made nil-only, so a non-number version still reads as
      skew.

## Coverage

- AC1 → T1, T4
- AC2 → T4
- AC3 → T2, T4
- AC4 → T2, T4
- AC5 → T6
- AC6 → T5, T7

## Tasks

- [ ] T1: Add the sixth wording in `store_read`
      (`_extensions/index/modules/book.lua:1057-1071`) on the
      `never_written and rebuilt == nil` path, sharing no prefix with the five
      standing wordings; add its grep key beside the others
      (`tests/run-tests.sh:871-889`) and raise `warn-distinct.py`'s
      `EXPECTED` 83 → 84 with its own arithmetic line.
- [ ] T2: Narrow the classification test at `book.lua:1008` to a record whose
      `version` is a number other than `STORE_VERSION`; leave `valid_record`
      (`book.lua:365`) alone, so a decoded table with no version still fails
      validation and takes the unusable path.
- [ ] T3: Re-read all six store wordings and the prose naming their states
      against the narrowed sets, per the M38 lesson — a clause goes false in
      silence when what it is computed over changes.
- [ ] T4: Suite legs: extend `m069-lostsource`'s assertions (AC1); the
      undecodable-plus-broken-source leg over `examples/book-placement`
      (AC2); the three version-form legs over `examples/book-extensions`
      (AC3), reading `STORE_VERSION` through `run_scan store-version` rather
      than spelling it (the M06 lesson). Hand-derive every count.
- [ ] T5: The three planted defects of AC6 under `--self-test`, each shown red
      before its fix, each a single substitution (`spliced_copy` fails a
      zero-match plant).
- [ ] T6: `site/books.qmd`, `CHANGELOG.md`, the books claim-ledger rows, and
      the recovery prose plus KI230 and KI236 in `cairn/DESIGN.md`.
- [ ] T7: Full `tests/run-tests.sh` and `--self-test` runs; D-entry
      superseding D-045's clause that a never-written record whose source
      cannot be read draws the existing wording for that outcome, and
      recording the version-field partition.

## Work log

- 2026-09-03: created by /milestone-plan, promoting the held store-reports candidate row (its KI230 and KI236 halves); the other two halves are M074.
- 2026-09-03: plan gate chose a sixth wording, drawn where the never-written wordings already are, over reusing the could-not-be-read wording, because the latter asserts a record existed; falsified by an author reporting the two states read the same to them.
- 2026-09-03: plan gate chose reading a versionless record as one that could not be read over giving it a wording of its own, because a seventh sentence buys a distinction no author acts on differently; falsified by an author reporting they needed to know the file held a record's bytes rather than a damaged record.
- 2026-09-03: implement gate chose the sixth wording's own opening clause over sharing the never-written recovery wording's, because that clause is the grep key the suite counts that report by and a shared opening would make one key count both; falsified by an author reporting the two never-written reports read as unrelated to them.
- 2026-09-03: criteria audit ran in full mode over two passes ([O], fresh context); pass 1 returned four instrument-bound criteria and one unreachable approach, pass 2 returned eight findings over the rewrite — an unenumerable "opening" clause, two counts stated per render that are per reading chapter, `{}` conflating two probe forms, an ambiguous plant site, a missing nil-only plant, and two documentation promises over whole files — all disposed into the criteria above.

## Decisions

## Review
