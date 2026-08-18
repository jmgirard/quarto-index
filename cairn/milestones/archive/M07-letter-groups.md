# M07: Letter-group headings in the HTML index

**Status:** done (2026-08-18, PR #7 https://github.com/jmgirard/quarto-index/pull/7)

**Goal:** The HTML index partitions its top-level entries into letter groups —
one Symbols group first, then A–Z — each introduced by a stylable heading block.

**Outcome:** `group_label` labels an entry by the string it FILES under (sort
key, else printed text): first character uppercased when an ASCII letter, else
`Symbols`. `group_rank` maps Symbols to `""`, below every letter, and runs ahead
of `collate` in `number_entries`' comparator at the root only (`node.key ==
nil`). `grouped_blocks` emits a `qi-letter` Div plus a BulletList per group —
never a Header, which Quarto copies into the TOC and mints an id for — via
`entry_items`, split out of `entry_list`; books share `html_index_blocks`. LaTeX
byte-identical across 19 fixtures; `letter_sweep` pins each label's element.

**Decisions:** Two, milestone-local: a label derives from the filing string, so
one `sort=` lever moves entries within and across groups; only ASCII letters
open a group, since folding accented ones would overpromise the collation.

**Review:** Three-lens fan-out ([O] lens needed five spawns; four died on 529s).
Nine findings actioned, seven fixed on the branch — load-bearing: nothing
asserted the heading is a Div not a Header, AC1's one unevidenced clause, now
pinned by tag/class/id against a planted Header. Two latent findings to
candidate rows; no lesson retired, two captured.
