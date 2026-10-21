# M122: Merged-entry reports are checked where they name their index

**Status:** done (2026-10-21, PR #122 https://github.com/jmgirard/quarto-index/pull/122)

**Goal:** The suite checks each of the four reports about an index entry that merges different marks in the form that names its index.

**Outcome:** `examples/xref-conflict-named.qmd` declares `plants` and `places`,
marks Alder, Cedar, Hazel and Oak for the four merged shapes in `plants`, and
Willow once in each index. M122-AC1 renders it to PDF and holds each log line
that holds one of the eight literals, whole and `(W) ` prefix included, to a
four-line hand list; colour codes are removed, the log is split on `\n`, and
each copied literal must still be in `index.lua`. Plants for the `document`
form, a removed report, text before or after a report, a `\r`, colour, and
missing, directory, unreadable, non-UTF-8, empty and stale inputs. Registered
in `site/gallery.yml` and the M14 corpus. KI320 struck; KI60 narrowed to the
unchecked refusal of a non-string `role` (removing `role = mark.role` turns
M21-AC5 red); KI327 added (the Examples page claims the whole corpus).

**Decisions:** none.

**Review:** three four-lens passes; two defect returns on AC1 (the check held
a span of each line); the user chose the whole-line repair. 48 fixed, 3 to
KI327, 15 rejected. Suite 1896 green alone; CI green. Graduated "Exercise two
paths no fixture reaches"; M120 lesson extended; PROFILE run note; none unparked.
