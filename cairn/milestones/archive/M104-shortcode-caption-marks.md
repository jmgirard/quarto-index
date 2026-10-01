# M104: A caption mark beside a shortcode files one locator

**Status:** done (2026-10-01, PR #104 https://github.com/jmgirard/quarto-index/pull/104)

**Goal:** If the caption of a figure with no id also holds a Quarto shortcode,
a mark in that caption files one locator in every back-end.

**Outcome:** `marks.declass_caption_copies` compares a figure's caption with
the image's alt-text copy. Before it compares, `without_custom_ids` drops the
`__quarto_custom_id` of each `__quarto_custom` span at every depth. Quarto
gives each inline shortcode in the caption and in the copy a different id, so
the two never matched before. `examples/figure-marks.qmd` gains a case
beside two shortcodes: `juniper` on page 7 and a `larch` range to page 8. The
four manifests carry its rows. A `custom-id` self-test plant restores the old
comparison and shows the log check red in all four formats. The exception
left `site/syntax.qmd` and `CHANGELOG.md`. KI299 closed.

**Decisions:** none.

**Review:** one round, three lenses, 11 merged findings. Six wording and
test items were fixed at the gate: the CHANGELOG sentence, a cedar-at-0
check in the plant, and four comments. Five were rejected with reasons.
The suite passed 1732 checks on c73fa48. The version matrix passed on
1.5.52, 1.10.18 and the release channel, and the PR checks passed. Nothing
graduated or retired.
