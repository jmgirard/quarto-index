-- The three Span passes, in the order the filter returns them: two that only
-- read — one registering sort keys, one deciding which keys are contested —
-- and the emitting pass that rewrites the mark.
--
-- They share the accumulators in `qi_marks` and `qi_latex` rather than passing
-- state between themselves: Pandoc runs each as a separate traversal.

local qi_core = require("./core")
local qi_latex = require("./latex")
local qi_levels = require("./levels")
local qi_marks = require("./marks")
local qi_sortkeys = require("./sortkeys")

local M = {}

-- The collect pass: a full traversal that only reads. It runs before the
-- emitting pass so that a sort key written on ANY mark of an entry is known
-- before the first mark of that entry is emitted — a mark emitted under a key
-- a later mark then contradicts would print the entry twice.
local function CollectSort(span)
  if not span.classes:includes(qi_core.INDEX_CLASS) then
    return nil
  end
  local sort_value = span.attributes["sort"]
  if sort_value == nil then
    -- Only a declaring mark registers anything, so a document that never
    -- writes `sort=` leaves this pass with no state at all.
    return nil
  end
  local entry = span.attributes["entry"]
  local visible = qi_marks.span_text(span)
  local context = qi_marks.describe(entry, visible)
  local declared = 0
  for _, kind in ipairs(qi_core.XREF_KINDS) do
    if span.attributes[kind.attr] ~= nil then
      declared = declared + 1
    end
  end
  local levels, _, kept, depth = qi_marks.derive_levels(entry, visible, declared,
                                              #span.content, context,
                                              sort_value, false)
  if levels == nil then
    return nil
  end
  -- Reported here rather than in the emitting pass: this is the pass that can
  -- see a conflict before anything has been emitted under either key.
  qi_sortkeys.register_sort(levels,
                qi_levels.sort_levels(sort_value, levels, context, true, kept, depth),
                context)
  return nil
end

-- The key pass: a second full traversal that only reads, running after every
-- sort key is registered and before anything is emitted. It exists because
-- whether a key is contested is a fact about the WHOLE document — one mark
-- cannot know that another names the same key a different way — and the repair
-- has to be applied to every mark of that key alike.
--
-- LaTeX-only: contestation is makeindex's rule about its own encapsulation
-- channel, and the HTML back-end has no such channel.
local function CollectKeys(span)
  if not span.classes:includes(qi_core.INDEX_CLASS) or not qi_core.is_latex_derived() then
    return nil
  end
  local entry = span.attributes["entry"]
  local visible = qi_marks.span_text(span)
  local context = qi_marks.describe(entry, visible)
  local xrefs, declared = {}, 0
  for _, kind in ipairs(qi_core.XREF_KINDS) do
    local value = span.attributes[kind.attr]
    if value ~= nil then
      declared = declared + 1
      local target, wrote = qi_marks.target_levels(value, kind.attr, context,
                                                   false)
      if target then
        xrefs[#xrefs + 1] = { kind = kind, levels = target,
                              written_depth = wrote }
      end
    end
  end
  local levels, _, _, entry_written =
    qi_marks.derive_levels(entry, visible, declared, #span.content,
                           context, span.attributes["sort"], false)
  if levels == nil then
    return nil
  end
  -- The format-neutral self-target drop, which the emitting pass makes too: a
  -- target naming its own entry never reaches an encapsulation, so it cannot
  -- contest anything.
  local own_key = qi_levels.levels_key(levels)
  local surviving = {}
  for _, xref in ipairs(xrefs) do
    if qi_levels.levels_key(xref.levels) ~= own_key then
      surviving[#surviving + 1] = xref
    end
  end
  local source, printed_path, _, kept =
    qi_latex.latex_plan(levels, qi_sortkeys.sort_for(levels), surviving, context,
                        false, nil, entry_written)
  qi_latex.record_contest(source, printed_path, kept)
  return nil
end

-- The encapsulation a role adds to a mark's own `\index` command, or the
-- empty string where there is none. Only a mark that CONTRIBUTES a locator
-- ever reaches it: a mark carrying a cross-reference had its role dropped and
-- reported before the back-end branch, and a cross-reference mark of a
-- contested key emits no command at all.
local function principal_encap(role)
  if role ~= "principal" then
    return ""
  end
  qi_latex.principal_emitted = true
  return "|" .. qi_core.PRINCIPAL_COMMAND
end

local function Span(span)
  local forged = span.attributes[qi_core.HTML_PENDING_ATTR] ~= nil
  if forged then
    -- The pending tag is this filter's own plumbing (see qi_core.HTML_PENDING_ATTR).
    -- One written by the author — on any span, a cross-reference mark
    -- included — would hijack a real mark's anchor in assign_anchors, so it
    -- is discarded wherever it is found.
    span.attributes[qi_core.HTML_PENDING_ATTR] = nil
  end
  if not span.classes:includes(qi_core.INDEX_CLASS) then
    if forged then
      return span
    end
    return nil
  end

  local entry = span.attributes["entry"]
  local visible = qi_marks.span_text(span)
  local context = qi_marks.describe(entry, visible)
  local sort_value = span.attributes["sort"]

  -- Cross-references are parsed and validated before the format branch below,
  -- so their misuse warnings fire in every format.
  local xrefs, declared = {}, 0
  for _, kind in ipairs(qi_core.XREF_KINDS) do
    local value = span.attributes[kind.attr]
    if value ~= nil then
      declared = declared + 1
      local levels, wrote = qi_marks.target_levels(value, kind.attr, context,
                                                   true)
      if levels then
        xrefs[#xrefs + 1] = { kind = kind, levels = levels,
                              written_depth = wrote }
      end
    end
  end
  if declared > 1 then
    -- Probably an author error, but IP2 forbids dropping either one, so every
    -- usable target is kept and the author is told. The message deliberately
    -- does not claim both were emitted: one of the two may have had no usable
    -- target, which its own warning above already reported.
    qi_core.warn("index mark carries both see= and see-also=; this is probably a "
         .. "mistake, and neither is dropped for being one of two")
  end

  -- The role attribute, read once here and resolved further down. It is not
  -- resolved yet because whether the mark has a locator to emphasize is not
  -- settled until the entry is derived and the self-referential targets are
  -- dropped, and a role reported against a cross-reference that is itself
  -- about to be dropped contradicts the drop's own report (review F2).
  local mention = span.attributes[qi_core.MENTION_ATTR]

  -- Derived once, and before the back-end branch: the levels are the author's
  -- text whatever format this is, and the empty-level warnings the derivation
  -- emits would otherwise fire twice for one mark.
  local levels, disposition, _, entry_written =
    qi_marks.derive_levels(entry, visible, declared, #span.content, context,
                           sort_value, true)
  if levels == nil then
    -- A mark that indexes nothing has no locator to emphasize either, and
    -- derive_levels has just said why it indexes nothing; the role's own
    -- report follows it in the same shape the dropped cross-reference uses
    -- (review F11).
    qi_marks.mention_role(mention, context, { unindexed = true }, true)
    return disposition == "drop" and {} or nil
  end

  -- A cross-reference target naming the entry it is written on says nothing:
  -- "Cats, see Cats" in print, and in HTML a link from an entry to itself. The
  -- target is dropped and the mark then indexes as usual — dropping the whole
  -- mark would lose the term, which is the corruption IP2 forbids, and keeping
  -- the target would leave the useless output in place.
  --
  -- Compared on the PRINTED levels rather than on the filing key: a sort key
  -- never appears in the index a reader reads, so a target matching the printed
  -- text is a self-reference whatever the mark files under. Before the back-end
  -- branch, like every other judgement about what the author wrote.
  --
  -- Neither side can carry an empty level any more: a target drops its own
  -- when it is parsed (qi_marks.target_levels) and an entry drops its own when it is
  -- derived (qi_levels.drop_empty_levels), so `entry="Cats!"` and a target of `Cats` are
  -- one printed path and compare equal without the comparison knowing anything
  -- about emptiness. M10 reconciled the two spellings here instead, because
  -- the entry side kept what it was written with.
  local own_key = qi_levels.levels_key(levels)
  local surviving = {}
  for _, xref in ipairs(xrefs) do
    if qi_levels.levels_key(xref.levels) == own_key then
      qi_core.warn(("%s= on %s names the entry it is written on; a cross-reference to "
            .. "itself says nothing, so it is dropped and the term is indexed "
            .. "as usual"):format(xref.kind.attr, context))
    else
      surviving[#surviving + 1] = xref
    end
  end
  xrefs = surviving
  -- Now that the self-referential targets are gone, what the mark actually
  -- contributes is settled: a mark with a surviving cross-reference emits one
  -- in the locator's place, and any other mark emits a locator. Before the
  -- back-end branch, like every other judgement about what the author wrote,
  -- so both reports fire in every format. The blocker names EVERY surviving
  -- attribute, in the fixed `see` before `see also` order xrefs are built in.
  local blocker_attrs = {}
  for _, xref in ipairs(xrefs) do
    blocker_attrs[#blocker_attrs + 1] = xref.kind.attr
  end
  local role = qi_marks.mention_role(mention, context,
                                     #blocker_attrs > 0 and
                                       { attrs = blocker_attrs } or nil, true)
  -- Resolved by the collect pass, which has already seen every mark of this
  -- entry: whichever mark declared the sort key, every mark of the entry files
  -- under it.
  local sort = qi_sortkeys.sort_for(levels)
  -- Every path from here indexes the mark in whichever back-end is running:
  -- one `\index` command in LaTeX, one record in HTML, nothing at all where
  -- there is no back-end. The count is what the marker's no-marks warning and
  -- both back-ends read.
  qi_marks.marks_seen = qi_marks.marks_seen + 1

  -- The LaTeX plan is built BEFORE the resolution set is recorded, because in
  -- that back-end the set is what entries PRINT rather than what the author
  -- wrote: its fold rewrites an entry's path and a target's alike, and a
  -- comparison run on one side's written form against the other's printed form
  -- is the divergence D-005 settles — it reported a folded target as naming
  -- nothing while the fold had just called the same target a self-reference,
  -- and said nothing at all about a written target the fold had moved out from
  -- under. No other format folds, so there the two lists are one and this runs
  -- not at all.
  local source, printed_path, filing_path
  local indexed = levels
  if qi_core.is_latex_derived() then
    source, printed_path, filing_path, xrefs, indexed =
      qi_latex.latex_plan(levels, sort, xrefs, context, true, nil,
                          entry_written)
  end

  -- Recorded after every drop: every path this mark indexes, each parent path
  -- included, in the space its own back-end resolves a target in. A target
  -- dropped as a self-reference is not among the pending ones below — neither
  -- the format-neutral drop above nor the fold's inside latex_plan.
  qi_marks.record_marked(indexed)
  for _, xref in ipairs(xrefs) do
    -- Two spellings, because they answer different questions. `levels` is what
    -- the author wrote, which is what a report quotes: a derived string names
    -- nothing they can search their source for (M09). `resolve` is the path
    -- this back-end judges the target against, which is the folded one where
    -- the fold moved it.
    qi_marks.pending_xrefs[#qi_marks.pending_xrefs + 1] =
      { attr = xref.kind.attr, levels = xref.written or xref.levels,
        resolve = xref.levels, context = context }
  end

  if qi_core.is_html() then
    local record = { levels = levels, sort = sort, xrefs = xrefs,
                     context = context, role = role }
    qi_marks.html_marks[#qi_marks.html_marks + 1] = record
    if #xrefs == 0 then
      -- Only a locator-contributing mark needs somewhere to link back to; a
      -- cross-reference mark takes the place of the locator and so has no
      -- anchor of its own. WHICH id anchors it — the author's own, or a
      -- minted one — is settled in the Pandoc pass, which can see every id
      -- in the document and every heading a mark sits in.
      span.attributes[qi_core.HTML_PENDING_ATTR] = tostring(#qi_marks.html_marks)
    end
    return span
  end

  if not qi_core.is_latex_derived() then
    -- Formats with no index back-end pass the visible text through
    -- untouched, with no artifacts.
    return nil
  end

  -- Recorded for every mark whatever it emits: a cross-reference mark files
  -- under the same key a plain one does, so it contests a printed path just
  -- as a locator mark would.
  qi_marks.record_clamped(printed_path, filing_path)

  local result = pandoc.List(span.content)

  -- A key more than one mark describes differently. Every mark of it emits the
  -- SAME command, which is what makeindex folds together instead of rejecting.
  -- WHERE the cross-references go depends on whether the entry has a locator,
  -- because makeindex's term delimiter is printed either way. See "Contested
  -- keys" above.
  local seen = qi_latex.contested_keys[source]
  if qi_latex.is_contested(seen) then
    if seen.plain then
      -- Some mark of this key is a plain locator mark, so the entry prints
      -- page numbers and the delimiter before them has work to do. The
      -- cross-references go into the printed text instead, and every plain
      -- mark carries them; a cross-reference mark of the same key emits
      -- nothing, so a cross-reference still contributes no locator — what this
      -- extension documents and what print convention expects. Nothing is
      -- lost: its target is in the text every plain mark emits.
      if #xrefs == 0 then
        local folded = select(1, qi_latex.latex_plan(levels, sort, xrefs, context,
                                            false, qi_latex.fold_xrefs(seen)))
        result:insert(pandoc.RawInline("latex",
          "\\index{" .. folded .. principal_encap(role) .. "}"))
      end
      return result
    end
    -- No mark of this key is a plain locator mark, so the entry has no page
    -- numbers and the delimiter's only job is to separate the term from its
    -- cross-references — which is the job it already does for an uncontested
    -- cross-reference mark. The targets stay in the encapsulation channel,
    -- rendered by one command over the key's whole list so that every mark
    -- carries the same string.
    qi_latex.xref_list_emitted = true
    result:insert(pandoc.RawInline("latex",
      "\\index{" .. source .. "|" .. qi_core.XREF_LIST_COMMAND ..
      "{" .. qi_latex.fold_xrefs(seen) .. "}}"))
    return result
  end

  -- `|` opens makeindex's encap channel, and `\see`/`\seealso` discard the
  -- page number handed to them, which is what makes a cross-reference replace
  -- the locator. hyperref rewrites the encap into
  -- `|hyperxindexformat{\see{...}}` before makeindex runs; that is transparent
  -- here. imakeidx, which this back-end already loads, defines `\see`,
  -- `\seealso`, `\seename` and `\alsoname` with `\providecommand`, so nothing
  -- needs injecting for the single-target forms; the both-targets form needs
  -- qi_core.XREF_BOTH_COMMAND, which is injected only in a document that uses it.
  local encap = qi_latex.mark_encap(xrefs)
  if encap == "" then
    result:insert(pandoc.RawInline("latex",
      "\\index{" .. source .. principal_encap(role) .. "}"))
  else
    if #xrefs > 1 then
      qi_latex.xref_both_emitted = true
    end
    result:insert(pandoc.RawInline("latex",
      "\\index{" .. source .. "|" .. encap .. "}"))
  end
  return result
end

-- Exported through the bracket form, never `M.NAME = NAME`: the source
-- scans take the FIRST match for `NAME =` over the whole source set, and
-- the M16-AC3 probe relocates a definition into another file — a plain
-- `NAME =` line left behind here would then mask it (M16 review F3).
M["CollectSort"] = CollectSort
M["CollectKeys"] = CollectKeys
M["Span"] = Span

return M
