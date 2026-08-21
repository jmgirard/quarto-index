-- What every back-end needs from a mark, derived once: its visible text, its
-- levels, its cross-reference targets, and the document-wide accumulators the
-- three passes and the Pandoc pass all read.
--
-- `marks_seen` is a field rather than a local because a scalar cannot be
-- shared by aliasing: the Span pass increments it and the Pandoc pass reads
-- it, and `require` hands them both this one table.

local qi_core = require("./core")
local qi_levels = require("./levels")

local M = {}

local function span_text(span)
  return pandoc.utils.stringify(span.content)
end

-- Parse one cross-reference target into levels. This is the format-neutral
-- layer, so it runs whatever the output format is and a misused mark is
-- diagnosed everywhere, not only where a back-end happens to exist.
--
-- An empty level is dropped rather than kept: a target is typeset prose, not
-- an index key, so an empty one would leave a dangling separator mid-sentence
-- in the printed index. It is warned about, never dropped silently (IP2).
--
-- Returns the surviving levels and the depth the author actually wrote, the
-- second so the LaTeX fold report can name both counts where they differ
-- (D-006) — the same pair `drop_empty_levels` returns for an entry, for the
-- same reason.
local function target_levels(value, attr, context, report)
  local kept = {}
  local parsed = value == "" and {} or qi_levels.parse_levels(value)
  -- An entirely empty value has no levels to complain about individually; it
  -- falls straight through to the one warning that names the real problem.
  for _, level in ipairs(parsed) do
    if level == "" then
      if report then
        qi_core.warn(("empty level in %s= on %s; dropped from the cross-reference "
              .. "target"):format(attr, context))
      end
    else
      kept[#kept + 1] = level
    end
  end
  if #kept == 0 then
    -- Says only what is true in every branch and every format: the mark may
    -- go on to be indexed plainly, or not to be indexed at all if it has no
    -- source entry either, or to reach a format with no index back-end.
    if report then
      qi_core.warn(("%s= on %s has no usable target text; no cross-reference will be "
            .. "emitted for this mark"):format(attr, context))
    end
    return nil
  end
  return kept, #parsed
end

-- Describe a mark for a warning message, by whichever of its parts names it.
local function describe(entry, visible)
  if entry ~= nil and entry ~= "" then
    return 'entry="' .. entry .. '"'
  elseif visible ~= "" then
    return 'term "' .. visible .. '"'
  end
  return "a mark with no source entry"
end

-- Set by the Span pass, read by the Pandoc pass: the preamble and the index
-- itself are emitted only when the document actually has marks. Counted before
-- the back-end branch, so "this document has marks" means the same thing in
-- every format — the marker's no-marks warning is format-neutral and cannot be
-- asked of a per-back-end accumulator.
M["marks_seen"] = 0
-- The HTML back-end's equivalent: one record per mark, in document order,
-- each carrying the mark's parsed levels, its cross-reference targets, and
-- (for a locator-contributing mark) the id of the anchor that links back to
-- it. The Pandoc pass builds the whole index section out of these.
local html_marks = {}

-- Every level path this document's marks index, each mark's parent levels
-- included, as `qi_levels.levels_key` strings. This is the set a cross-reference target
-- is resolved against. Whether a target names a term the document indexes is
-- still a fact about what the author wrote (IP1) rather than about a back-end,
-- and the report is still drawn once for every format — but the PATHS the fact
-- is read off are the ones the running back-end prints, so where a level
-- ceiling folds an entry it folds the target too and what is recorded here is
-- the folded path (D-005, corrected M18). Where nothing folds, this is the
-- written path exactly as before. The HTML entry tree could answer the same
-- question, but it exists in one format only, so the answer would too.
local marked_paths = {}
-- Every surviving cross-reference target, in document order, carrying the
-- mark it was written on. Held until the Pandoc pass, which is the first
-- point that has seen every mark: a target may name an entry marked further
-- down the page, and judging it at the mark would call that broken.
local pending_xrefs = {}

local function record_marked(levels)
  for i = 1, #levels do
    marked_paths[qi_levels.level_path(levels, i)] = true
  end
end

-- One report per mark per target that names nothing the marks index. `scope`
-- is what the path set was drawn from — one document, or a whole book —
-- because the two are different claims, and an author told "this document" in
-- a book would go looking in the wrong file.
local function report_dangling(paths, xrefs, scope)
  for _, xref in ipairs(xrefs) do
    -- The target as the author wrote it: `qi_levels.levels_key` doubles a literal `!`
    -- back, exactly as it must be typed, so the string in the report is the
    -- string to search the source for. Its empty levels are already gone, and
    -- were already reported when they were dropped.
    local target = qi_levels.levels_key(xref.levels)
    -- Judged on `resolve` and quoted as `target`: where a back-end folds, the
    -- two differ, and the author is told about the string they typed while the
    -- lookup runs against the path that back-end actually prints (D-005). Every
    -- other format, and the book store, carry no `resolve` and fall back to the
    -- one spelling they have.
    if not paths[qi_levels.levels_key(xref.resolve or xref.levels)] then
      qi_core.warn(('%s= on %s points at "%s", which no index mark in this %s indexes; a reader following the cross-reference finds no such entry, so mark that term somewhere or correct the target'):format(xref.attr, xref.context, target, scope))
    end
  end
end

-- Printed level path (AFTER the three-level fold) -> the set of filing paths
-- the document emitted for it. Sort keys are declared against the level paths
-- the author wrote, and the fold does not change those, so two entries whose
-- paths differ before the fold and agree after it keep a key each: the index
-- tool receives two keys, stores the one printed entry twice, and prints it
-- twice, in two places, identically, with nothing in the log to say so.
-- Neither key is this filter's to drop (IP2) and which of the two the author
-- meant is not recoverable from the document, so the pair is reported.
--
-- LaTeX-only, unlike the sort-key reports about a mark: the fold is the index
-- tool's ceiling rather than a property of what the author wrote, and the HTML
-- back-end applies none, so there the two entries are genuinely two.
local clamped_paths = {}

local function record_clamped(path, filing)
  local seen = clamped_paths[path]
  if not seen then
    seen = {}
    clamped_paths[path] = seen
  end
  seen[filing] = true
end

-- The one place a mark's index levels are derived from what the author wrote.
-- Both Span passes call it, so they cannot drift on what an entry's levels
-- are; only the emitting pass passes `report`, so a mark's warnings fire once
-- however many passes read it.
--
-- Returns `levels, nil` when there is something to index, and
-- `nil, "drop"|"keep"` when there is not — "drop" removing a genuinely empty
-- mark, "keep" leaving content the author wrote untouched (IP2).
local function derive_levels(entry, visible, declared, content_count, context,
                             sort_value, report)
  -- Set once the author has already been told WHY nothing is indexable, so
  -- the generic messages below never claim they wrote no entry= when the
  -- value they wrote is right there in the warning above.
  local explained = false
  if entry ~= nil and entry ~= "" then
    local levels, kept, depth = qi_levels.drop_empty_levels(qi_levels.parse_levels(entry), context,
                                                  report)
    if #levels > 0 then
      return levels, nil, kept, depth
    end
    -- Every level empty. The per-level warning above did not fire for this
    -- mark: one message about the value as a whole says more than a count of
    -- levels none of which printed anything.
    if visible ~= "" then
      if report then
        qi_core.warn(("%s is only empty levels, which print nothing; the mark indexes "
              .. "under its visible text instead"):format(context))
      end
      -- An EMPTY `kept`, not a nil one: every level the author wrote is gone,
      -- so no sort key they wrote belongs to the level this falls back to.
      -- Passing nil would re-align the whole sort value onto that level and
      -- put a key on a level it was never written for (M11 review F3).
      return { visible }, nil, {}, depth
    end
    if report then
      qi_core.warn(("%s is only empty levels, which print nothing; nothing to index")
           :format(context))
    end
    explained = true
  elseif visible ~= "" then
    -- A visible term is one literal level; `!` in it is not a separator.
    return { visible }, nil
  end

  -- Nothing to index. A sort key says where an entry files, so one on a mark
  -- that indexes no entry is asking for something that cannot happen — the
  -- one warning every branch below shares.
  if report and sort_value ~= nil then
    qi_core.warn(("sort= on %s has nothing to sort; the mark indexes no entry")
         :format(context))
  end

  if declared > 0 then
    -- A cross-reference needs something to hang off. This is its own warning
    -- rather than either of the two below, because the fix is different: give
    -- the mark an entry= or some visible text.
    if report then
      if explained then
        -- The entry has already been reported; what this adds is that the
        -- cross-reference went with it (M11 review F4).
        qi_core.warn(("the cross-reference on %s has no source entry left to hang "
              .. "off, so it was dropped too; give the mark an entry= that "
              .. "prints something, or some visible text"):format(context))
      else
        qi_core.warn("cross-reference mark has no source entry (no entry= and no "
             .. "visible text); nothing to index")
      end
    end
    -- Same content policy as the two cases below: an empty mark is dropped,
    -- a mark with content keeps every bit of it.
    return nil, content_count == 0 and "drop" or "keep"
  end
  if content_count == 0 then
    if report and not explained then
      qi_core.warn("index mark with no visible term and no entry=; nothing to index")
    end
    -- Genuinely empty and nothing to index: drop the mark rather than leave
    -- an empty group behind in the output.
    return nil, "drop"
  end
  -- The span HAS content, it just yields no text to derive an entry from
  -- (an image with empty alt text, say). Index nothing, but never remove
  -- the content — deleting what the author wrote would be IP2 corruption.
  if report and not explained then
    qi_core.warn("index mark whose content has no text and no entry=; nothing to "
         .. "index, content left untouched")
  end
  return nil, "keep"
end

-- Exported through the bracket form, never `M.NAME = NAME`: the source
-- scans take the FIRST match for `NAME =` over the whole source set, and
-- the M16-AC3 probe relocates a definition into another file — a plain
-- `NAME =` line left behind here would then mask it (M16 review F3).
M["span_text"] = span_text
M["target_levels"] = target_levels
M["describe"] = describe
M["html_marks"] = html_marks
M["marked_paths"] = marked_paths
M["pending_xrefs"] = pending_xrefs
M["record_marked"] = record_marked
M["report_dangling"] = report_dangling
M["clamped_paths"] = clamped_paths
M["record_clamped"] = record_clamped
M["derive_levels"] = derive_levels

return M
