# M074: A record no render has written is reported by the chapter that prints the section, once

**Status:** done (2026-09-04, PR #74 https://github.com/jmgirard/quarto-index/pull/74)

**Goal:** In an HTML book, the reports about a record no render has written are drawn at the site that knows whether this chapter prints an index section, each wording once per chapter that reads the store and naming every chapter it covers, rather than inline once per record met by every chapter the recovery gate admits.

**Outcome:** `store_read` hands back a third table — the never-written chapters split into refused / recovered / lost, in book order — and `html_book` draws one line per list at the existing report site, under the `builds or first == nil` gate, after the stale and refiled loops. `chapter_list` joins the names with commas and a final "and" inside the message's own `:format()`, so `warn-distinct.py` still reads one message and `check_extension_warning_count` still counts one line. The refusal drawn on that path moved with it. A chapter that reads the store and prints no section is now silent; a book with no placement marker anywhere still hears once, from the chapter that builds nothing. Indexes are unchanged.

Suite: `check_warning_names` and `check_warning_names_nth` assert which chapters a line names; new legs for the silent last chapter, its unplaced positive control, and the no-marker book; counts rederived by hand across eleven legs; M069 T6's whole-gate plant retired where the moved draw site left it nothing to discriminate on.

**Decisions:** D-053.

**Review:** Two rounds, three-lens fan-out each. Round 1 returned at the gate — AC5 failed on three sentences still claiming one report per record — plus six fix-now and two follow-ups (KI239, KI240). Round 2: all six criteria passed (699-check plain run, 1296-check self-test, both exit 0); twelve findings — three stale comment clauses fixed now, three suite-hardening items absorbed into the check-discrimination candidate row, three rejected, two already filed. Nothing retired or graduated at hygiene.
