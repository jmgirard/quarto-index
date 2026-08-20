-- quarto-index: format-neutral index marks -> per-format back-ends.
--
-- Mark syntax (all values are structured, format-neutral data; never raw
-- back-end code):
--   [term]{.index}                  index the visible term
--   [term]{.index entry="..."}      index a custom entry, term stays visible
--   []{.index entry="..."}          invisible entry
--   [term]{.index see="..."}        cross-reference: "see <target>"
--   [term]{.index see-also="..."}   cross-reference: "see also <target>"
--   [term]{.index sort="..."}       file the entry under different text
--
-- In `entry=`, a single `!` separates sub-entry levels and `!!` is a literal
-- `!`, scanned left-to-right longest-match. Each level is literal text: the
-- LaTeX back-end makes every character literal itself, by whichever mechanism
-- that character needs (see qi_core.LATEX_LITERAL). A visible term is always a single
-- literal level, so an `!` inside it is literal too.
--
-- A cross-reference target uses those same level semantics. Its source entry
-- is `entry=` when present, else the visible term, and the cross-reference
-- takes the place of the locator, as printed indexes do.
--
-- `sort=` uses those same level semantics again, and lines up position by
-- position with the entry's levels: the Nth sort level says where the Nth
-- entry level files, and a level with no sort level of its own files under
-- its own printed text. The value is ordinary author text like every other
-- mark value (IP1) — the back-end alone writes whatever syntax its index
-- tool needs. `sort=` is not accepted on a cross-reference target: a target
-- is prose naming another entry, and that entry carries its own sort key.

-- The filter itself. Everything below the requires is the Pandoc pass and the
-- list of passes handed back to Pandoc; every other definition lives in a
-- module beside this file. Required here are the seven this file itself
-- reaches; the other two, `levels.lua` and `sortkeys.lua`, arrive through
-- them. They are listed in dependency order — `core` requires nothing, `book`
-- requires most of the rest — and bound under `qi_` names, so no local can
-- shadow a module (`levels`, `marks` and `marker` are all ordinary local names
-- in this filter).
local qi_core = require("./modules/core")
local qi_latex = require("./modules/latex")
local qi_marks = require("./modules/marks")
local qi_passes = require("./modules/passes")
local qi_html = require("./modules/html")
local qi_marker = require("./modules/marker")
local qi_book = require("./modules/book")

-- `intoc` lists the index in the table of contents, as printed books normally
-- do. imakeidx only runs makeindex itself under `-shell-escape`, which Quarto
-- does not enable; what actually builds the index is Quarto's own PDF loop
-- reacting to the emitted `.idx` file (GP2: we emit correct output and stop).
local function Pandoc(doc)
  -- Before any back-end branch: the marker is the author's syntax, so its
  -- misuse is diagnosed in every format and its residue removed in every
  -- format, whether or not that format has an index to place.
  qi_marker.report_marker_sites(doc)
  local marker = qi_marker.resolve_markers(doc)
  -- A book chapter is not the whole document: the marks the marker places are
  -- mostly in other chapters, so "no marks here" says nothing about whether
  -- there is an index to place, and the book path reports what it finds
  -- across the whole store instead.
  local book = qi_core.is_html() and qi_book.book_context(doc) or nil
  if qi_core.is_html() and book == nil and doc.meta.book ~= nil then
    -- Falling back to a per-chapter index is not a safe default in a book: it
    -- is the shipped-before-M05 defect, one index per chapter and none of them
    -- the book's. Whatever Quarto did not tell us, the author hears about it
    -- rather than finding a stray index on a page later.
    qi_core.warn("this looks like a book, but the chapter list and output paths this "
         .. "extension needs were not available, so this page was indexed on "
         .. "its own instead of contributing to the book's index")
  end
  if marker and qi_marks.marks_seen == 0 and not book then
    qi_core.warn("index placement marker in a document with no index marks; there is "
         .. "no index to place")
  end
  -- Format-neutral, and before any back-end branch, like every other judgement
  -- about what the author wrote (IP1): a target that names no indexed term is
  -- broken wherever the mark is rendered, including in a format that builds no
  -- index at all. A book chapter is not the document its targets are judged
  -- against — the whole store is, and the last chapter in book order draws
  -- that report instead (qi_book.report_book_dangling).
  -- Not on the degraded book path (review F6): there Quarto called this page
  -- a book chapter and withheld what it takes to aggregate one, so the page
  -- was indexed on its own and the warning above says so. Every cross-chapter
  -- target on it would then be reported as naming nothing indexed, which is
  -- false of the book the author is writing and buries the one warning that
  -- is true.
  if not book and not (qi_core.is_html() and doc.meta.book ~= nil) then
    qi_marks.report_dangling(qi_marks.marked_paths, qi_marks.pending_xrefs, "document")
  end

  if qi_core.is_html() then
    -- Anchors are assigned before either path decides what to place: they are
    -- what a locator links back to, and in a book they are read by whichever
    -- chapter builds the index rather than by this one. A page with no marks
    -- that places no index needs none of it, and is not walked for ids.
    local taken = {}
    if qi_marks.marks_seen > 0 or book then
      taken = qi_html.taken_identifiers(doc)
    end
    if qi_marks.marks_seen > 0 then
      doc = qi_html.relocate_heading_anchors(doc)
      doc = qi_html.assign_anchors(doc, taken)
    end
    if book then
      return qi_book.html_book(doc, book, marker, taken)
    end
    -- A document with no marks gets no section, exactly as one with no marks
    -- gets no LaTeX preamble.
    if qi_marks.marks_seen == 0 then
      return qi_marker.place_index(doc, nil)
    end
    return qi_marker.place_index(doc, qi_html.html_index_blocks(qi_marks.html_marks, taken))
  end

  if qi_marks.marks_seen == 0 or not qi_core.is_latex_derived() then
    return qi_marker.place_index(doc, nil)
  end

  -- Reported here rather than at the mark, because it takes the whole document
  -- to know that a term has been marked both ways. Read from the map that
  -- DECIDED the emission, not from what was emitted: every mark of a contested
  -- key now emits the same argument, so a report reading emitted encaps back
  -- would find no two that differ and say nothing. Keys are walked in sorted
  -- order so the report does not depend on Lua's table iteration order.
  --
  -- It no longer warns of a failed render, because the emission no longer
  -- risks one; it says what the author's two marks print as, which is the one
  -- thing about the outcome they did not write down.
  --
  -- Two shapes, two messages, because the outcome they describe differs: a key
  -- with a plain mark keeps its page numbers, and a key with none has never
  -- had any. One message covering both would tell the author of a `see=`
  -- against a `see-also=` that their entry prints page numbers it does not.
  local conflicting = {}
  for _, seen in pairs(qi_latex.contested_keys) do
    if qi_latex.is_contested(seen) then
      conflicting[#conflicting + 1] = { printed = seen.printed,
                                        plain = seen.plain }
    end
  end
  table.sort(conflicting, function(a, b) return a.printed < b.printed end)
  for _, clash in ipairs(conflicting) do
    if clash.plain then
      qi_core.warn(('index entry %s carries both a plain locator and a cross-reference; they are printed as one entry with its page numbers and its cross-reference together, so check that is the entry you meant'):format(clash.printed))
    else
      qi_core.warn(('index entry %s carries two different cross-references; they are printed as one entry carrying both targets and, since neither mark contributes one, no page numbers at all, so check that is the entry you meant'):format(clash.printed))
    end
  end

  -- The level-fold collision, reported the same way and for the same reason:
  -- it takes the whole document to know that a second entry prints where the
  -- first one does. Once per contested printed path rather than once per key
  -- or once per mark — the author's fix is a single choice between the keys,
  -- and the message has to show all of them to let them make it. Paths are
  -- walked in sorted order, and so are the keys within one, so the report does
  -- not depend on Lua's table iteration order.
  local contested = {}
  for path, filings in pairs(qi_marks.clamped_paths) do
    local keys = {}
    for filing in pairs(filings) do
      keys[#keys + 1] = filing
    end
    if #keys > 1 then
      table.sort(keys)
      contested[#contested + 1] = { path = path, keys = keys }
    end
  end
  table.sort(contested, function(a, b) return a.path < b.path end)
  for _, clash in ipairs(contested) do
    local named = {}
    for i, key in ipairs(clash.keys) do
      if key == clash.path then
        -- Not a key the author wrote: it is what an entry carrying no sort
        -- key files under. Quoting it back as one would name a string they
        -- never typed and cannot search for — and it is the printed path
        -- already quoted earlier in the same sentence.
        named[i] = "its printed text, which is what an entry with no sort "
          .. "key there files under"
      else
        named[i] = '"' .. key .. '"'
      end
    end
    local last = table.remove(named)
    qi_core.warn(('index entries printed as "%s" file under more than one key (%s), '
          .. 'so the index tool stores one key each and prints that entry '
          .. 'once per key, in as many places; give them one sort key, or '
          .. 'write them as one entry')
         :format(clash.path, table.concat(named, ", ") .. " and " .. last))
  end
  if not (quarto and quarto.doc and quarto.doc.use_latex_package
          and quarto.doc.include_text) then
    -- Running under plain pandoc rather than Quarto: emit the marks, but do
    -- not pretend we can inject a preamble.
    qi_core.warn("preamble injection needs Quarto; \\index commands emitted without "
         .. "imakeidx setup")
    return qi_marker.place_index(doc, nil)
  end

  if marker then
    -- Quarto emits the package load as
    -- `\@ifpackageloaded{imakeidx}{}{\usepackage[noautomatic]{imakeidx}}`, so a
    -- document whose template or header-includes loads imakeidx FIRST takes
    -- the empty branch and never gets the option — and then every mark below
    -- the marker is dropped from the index, which is the silent corruption the
    -- option exists to prevent. Nothing emitted here can reach a load that
    -- already happened, so the unfixable case is made loud instead: a
    -- begin-document check that says what will be missing and why. It warns
    -- rather than erroring, because a marked-up document must still render
    -- (IP2). `\PassOptionsToPackage` is deliberately NOT emitted alongside it:
    -- it registers the option on the already-loaded package, which would make
    -- this check report success on exactly the document it exists to catch.
    quarto.doc.include_text("in-header",
      "\\makeatletter\\AtBeginDocument{\\@ifpackagewith{imakeidx}{noautomatic}"
      .. "{}{\\PackageWarning{quarto-index}{This document loads imakeidx "
      .. "itself without the noautomatic option, so terms marked after the "
      .. "index placement marker will be missing from the index}}}"
      .. "\\makeatother")
    -- `\printindex` closes the `.idx` file it has just read, so every `\index`
    -- written after it goes to the log instead — silently, and only the marks
    -- BELOW the marker are lost, which is exactly the corruption IP2 forbids.
    -- imakeidx skips that close under `noautomatic`, which costs a document
    -- nothing here: the automatic run needs `-shell-escape`, which Quarto does
    -- not enable, so the index was always built by Quarto's own PDF loop
    -- (GP2). The option is emitted only where a marker made it necessary, so a
    -- document without one keeps the preamble it has always had.
    quarto.doc.use_latex_package("imakeidx", "noautomatic")
  else
    quarto.doc.use_latex_package("imakeidx")
  end
  quarto.doc.include_text("in-header", "\\makeindex[intoc]")
  if qi_latex.xref_both_emitted then
    -- `\providecommand` so a document defining its own version keeps it.
    -- `\seename`/`\alsoname` are resolved where the command is used, in the
    -- generated index, not where it is defined — so nothing here depends on
    -- this landing after imakeidx.
    quarto.doc.include_text("in-header", qi_core.XREF_BOTH_DEFINITION)
  end
  if qi_latex.xref_list_emitted then
    -- Same discipline: defined only in a document that has a contested key no
    -- plain mark contributes to, and with `\providecommand` so a document
    -- defining its own keeps it.
    quarto.doc.include_text("in-header", qi_core.XREF_LIST_DEFINITION)
  end

  return qi_marker.place_index(doc,
    pandoc.Blocks({ pandoc.RawBlock("latex", "\\printindex") }))
end

-- The Span pass records the marks; every anchor decision that needs the
-- whole document — which ids are taken, which marks sit inside headings —
-- waits for the Pandoc pass.
return {
  { Span = qi_passes.CollectSort },
  { Span = qi_passes.CollectKeys },
  { Span = qi_passes.Span },
  { Pandoc = Pandoc },
}
