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
--   [term]{.index mention="..."}    the role this mention of the term plays
--   [term]{.index range="open"}     where a discussion of the term begins
--   [term]{.index range="close"}    and where it ends: one locator, not two
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
--
-- A range's two marks are paired by the entry they index, so nothing extra is
-- written; the pairing takes the whole document (and, in a book, the whole
-- book) to settle, which is why it has a pass of its own. A range this filter
-- cannot pair is never emitted as one: the index tool logs a warning for an
-- unmatched range and Quarto fails the render on it, so the mark degrades to
-- an ordinary locator and the author is told.

-- The filter itself. Everything below the requires is the Pandoc pass and the
-- list of passes handed back to Pandoc; every other definition lives in a
-- module beside this file. Required here are the seven this file itself
-- reaches; the other two, `levels.lua` and `sortkeys.lua`, arrive through
-- them. They are listed in dependency order — `core` requires nothing, `book`
-- requires most of the rest — and bound under `qi_` names, so no local can
-- shadow a module (`levels`, `marks` and `marker` are all ordinary local names
-- in this filter).
local qi_core = require("./modules/core")
local qi_indexes = require("./modules/indexes")
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
  -- A book chapter is not the whole document: the marks the marker places are
  -- mostly in other chapters, so "no marks here" says nothing about whether
  -- there is an index to place, and the book path reports what it finds
  -- across the whole store instead.
  --
  -- Computed here rather than after resolution because the marker reports name
  -- the chapter they are about, and resolution is what draws them. Nothing
  -- below the marker reports reads it any earlier than it used to, and the
  -- decisions that need the whole context still run after resolution. The
  -- `is_html` gate is what makes a chapter file mean a chapter: only the HTML
  -- book renders a chapter per Pandoc process, so every other format reaches
  -- the no-chapter wording by the path a single document takes.
  local book = qi_core.is_html() and qi_book.book_context(doc) or nil
  local marker = qi_marker.resolve_markers(doc, book and book.file or nil)
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
  -- Drawn for every format, and before any back-end branch: a target that names
  -- no indexed term is broken wherever the mark is rendered, including in a
  -- format that builds no index at all. What is NOT format-neutral any more is
  -- the set it is judged against — a back-end with a level ceiling records the
  -- paths it prints and folds targets to match, so the comparison runs in that
  -- back-end's printed space (D-005, corrected M18). A book chapter is not the document its targets are judged
  -- against — the whole store is, and the last chapter in book order draws
  -- that report instead (qi_book.report_book_dangling).
  -- Not on the degraded book path (review F6): there Quarto called this page
  -- a book chapter and withheld what it takes to aggregate one, so the page
  -- was indexed on its own and the warning above says so. Every cross-chapter
  -- target on it would then be reported as naming nothing indexed, which is
  -- false of the book the author is writing and buries the one warning that
  -- is true.
  -- One index at a time, in declared order (M38): a target is resolved against
  -- the paths of the index its own mark files in, so a `see=` in one index
  -- naming a term marked only in another is the dangling target it is to a
  -- reader. A document with one index has one namespace and one pass here.
  if not book and not (qi_core.is_html() and doc.meta.book ~= nil) then
    for _, name in ipairs(qi_indexes.names()) do
      -- The scope the report names is the set the target was judged against,
      -- which is this ONE index wherever the document declares several
      -- (review O1): "this document" there is a set no judgement was made
      -- over, and the term it says nothing indexes may be marked two sections
      -- up, in the other index. A document declaring nothing or one, and any
      -- folded back-end, keep the "document" they have always printed.
      qi_marks.report_dangling(qi_marks.marked_paths[name] or {},
                               qi_marks.xrefs_for(name),
                               qi_indexes.scope_phrase(name, "document"))
    end
  end
  -- The range reports, held rather than emitted where they were found so they
  -- print after the per-mark reports. Under D-009 every Pandoc process is its
  -- own pairing scope — a single document, or one chapter of an HTML book —
  -- so the pairing reports are always this process's to draw; only the WORD
  -- naming the scope differs, so an author is sent looking in the right set.
  -- The book's cross-chapter report is a separate message qi_book owns.
  -- A merged (non-HTML) book render is one process spanning every chapter, so
  -- its scope word is "book" — "document" would send an author looking inside
  -- the one chapter file they are editing. The degraded HTML book path keeps
  -- "document": that page was indexed on its own, and its own text is the set.
  local range_scope = "document"
  if book then
    range_scope = "chapter"
  elseif doc.meta.book ~= nil and not qi_core.is_html() then
    range_scope = "book"
  end
  qi_marks.report_ranges(range_scope)

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
    -- A document with no marks gets no section. (The LaTeX path keeps three
    -- preamble lines even then — the gobbling stand-ins, whose reason is a
    -- surviving `.aux` no HTML render has.)
    if qi_marks.marks_seen == 0 then
      return qi_marker.place_index(doc, nil)
    end
    return qi_marker.place_index(doc,
      qi_html.html_index_blocks(qi_marks.html_marks, taken))
  end

  if not qi_core.is_latex_derived() then
    return qi_marker.place_index(doc, nil)
  end
  if qi_marks.marks_seen == 0 then
    -- A document with no marks gets no preamble — except the stand-ins
    -- (M22): its `.aux` may still carry the typeset-time subsystem's lines
    -- from a render whose marks have since been deleted, and reading those
    -- against no definition fails the render, which is the IP2 break the
    -- subsystem exists to avoid. Injection needs Quarto;
    -- plain pandoc has no preamble channel. Silent where the marked path
    -- below warns about the same missing channel, and deliberately: that
    -- warning is about marks whose index setup is being skipped, and this
    -- document has no marks to report anything about.
    if quarto and quarto.doc and quarto.doc.include_text then
      quarto.doc.include_text("in-header", qi_core.PRINCIPAL_GOBBLERS)
      -- And the two cross-reference definitions (M31). Not for the same
      -- reason as the block above: this branch emits no `\printindex`, which
      -- is the only command that reads an `.ind`, so no leftover index can
      -- reach a document with no marks — where the `.aux` above IS read, at
      -- `\begin{document}`, whether an index is printed or not. They ride
      -- here so that "every LaTeX-derived render defines them" holds without
      -- a branch to remember, which is what makes the containment sweep a
      -- predicate over the artifacts rather than a list of exempt shapes.
      quarto.doc.include_text("in-header", qi_core.XREF_BOTH_DEFINITION)
      quarto.doc.include_text("in-header", qi_core.XREF_LIST_DEFINITION)
    end
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
  for _, name in ipairs(qi_indexes.names()) do
    for path, filings in pairs(qi_marks.clamped_paths[name] or {}) do
      local keys = {}
      for filing in pairs(filings) do
        keys[#keys + 1] = filing
      end
      if #keys > 1 then
        table.sort(keys)
        contested[#contested + 1] = { path = path, keys = keys }
      end
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
  -- Unconditional, not gated on this document emitting the command (M31).
  -- Both cross-reference commands reach the compiled `.ind`, which outlives
  -- the marks that wrote it exactly as the `.aux` does, so a document that has
  -- since lost its both-attributes mark or its all-cross-reference contested
  -- key still reads them at `\printindex`. Each is stateless — it renders its
  -- own arguments and remembers nothing — so its live definition already IS
  -- its stand-in, and injecting it everywhere needs no second block and no
  -- one-of-two invariant to keep. `\providecommand` so a document defining
  -- its own version keeps it. `\seename`/`\alsoname` are resolved where the
  -- command is used, in the generated index, not where it is defined — so
  -- nothing here depends on this landing after imakeidx.
  quarto.doc.include_text("in-header", qi_core.XREF_BOTH_DEFINITION)
  quarto.doc.include_text("in-header", qi_core.XREF_LIST_DEFINITION)
  if qi_latex.principal_emitted then
    -- Same discipline again: defined only in a document some mark of which
    -- declares the principal role, and with `\providecommand` so a document
    -- wanting different emphasis defines its own and keeps it. The emphasis
    -- command goes in first and on its own, because it is the one an author
    -- redefines; the subsystem that applies it follows as one block.
    quarto.doc.include_text("in-header", qi_core.PRINCIPAL_DEFINITION)
    quarto.doc.include_text("in-header", qi_core.PRINCIPAL_SUBSYSTEM)
  else
    -- Where the subsystem is not defined, its gobbling stand-ins are (M22):
    -- this document's `.aux` may still carry the subsystem's lines from a
    -- render whose principal marks have since been deleted. Exactly one of
    -- the two blocks per document, never both — each defines with
    -- `\providecommand*`, so whichever landed first would win, and a
    -- gobbled subsystem emphasizes nothing while looking installed.
    quarto.doc.include_text("in-header", qi_core.PRINCIPAL_GOBBLERS)
  end

  -- One `\printindex`, under the one index a LaTeX-derived render builds:
  -- every mark and every marker naming another was folded to this one and told
  -- its author so.
  return qi_marker.place_index(doc,
    { [qi_indexes.default()] =
        pandoc.Blocks({ pandoc.RawBlock("latex", "\\printindex") }) })
end

-- The Span pass records the marks; every anchor decision that needs the
-- whole document — which ids are taken, which marks sit inside headings —
-- waits for the Pandoc pass.
--
-- The reset comes first, and is a document hook rather than an element one so
-- that it runs before the first mark of the document is seen: Pandoc applies
-- each table in this list in turn, and a table with no element function is one
-- traversal of the document alone. The modules' accumulators are cached by
-- `require` for the life of the Lua state, so a state reused across documents
-- would otherwise hand the second document whatever the first left behind
-- (M26). Nothing in Quarto reuses one today — it runs a process per document —
-- which is why this is written as a guarantee rather than as a fix.
return {
  { Pandoc = qi_passes.Reset },
  { Span = qi_passes.CollectSort },
  { Span = qi_passes.CollectKeys },
  -- The range pass carries a document hook as well as an element one: an
  -- opening still waiting when the traversal ends was never closed, and
  -- Pandoc runs a filter's `Pandoc` function after its element functions.
  { Span = qi_passes.CollectRanges, Pandoc = qi_passes.FinishRanges },
  { Span = qi_passes.Span },
  { Pandoc = Pandoc },
}
