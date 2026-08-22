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

-- The role one mention of a term declares, from the value the author wrote.
-- Derived before any back-end is chosen, like every other judgement about
-- what the author wrote, so both reports below fire in every format — a
-- misused mark is diagnosed where there is no index back-end at all.
--
-- Returns the role, or nil where there is none to apply. `blocker` names what
-- leaves the mark with no locator to emphasize, or is nil where the mark
-- contributes one: `{ attrs = {...} }` for the cross-references that take the
-- locator's place — EVERY one the mark still carries, because a mark writing
-- both attributes is told about both and a message naming only the first
-- describes half its own mark (review F12) — and `{ unindexed = true }` for a
-- mark that indexes no entry at all, whose role is otherwise dropped in
-- silence though it is as unusable as the other (review F11). `report` follows
-- the convention the rest of this file uses: only the emitting pass says
-- anything.
--
-- An unrecognized value is reported BEFORE either blocker, and no two of the
-- three ever fire together: a value naming no role is the more basic mistake,
-- and telling an author their unknown role was ignored for want of a locator
-- would send them looking in the wrong place. An EMPTY value is unrecognized
-- rather than absent — it is a value the author wrote, and reading it as
-- absence would swallow a typo silently.
--
-- The caller derives `blocker` from the cross-references that SURVIVE the
-- self-reference drop, never from the declared ones: a target naming its own
-- entry is dropped and the mark then indexes plainly, so it takes no locator's
-- place, and a role reported as displaced by it would contradict the drop's
-- own report about the same mark one line later (review F2).
local function mention_role(value, context, blocker, report)
  if value == nil then
    return nil
  end
  if not qi_core.MENTION_ROLES[value] then
    if report then
      qi_core.warn(('%s= on %s names no role this extension knows ("%s"); the mark indexes as though the attribute were absent'):format(qi_core.MENTION_ATTR, context, value))
    end
    return nil
  end
  if blocker ~= nil and blocker.unindexed then
    if report then
      qi_core.warn(('%s="%s" on %s; the mark indexes nothing, so there is no locator to emphasize and the role is dropped too'):format(qi_core.MENTION_ATTR, value, context))
    end
    return nil
  end
  if blocker ~= nil and #blocker.attrs > 0 then
    -- One attribute reads `see=`, two `see= and see-also=`, in the fixed order
    -- the caller passes them.
    local named = {}
    for _, attr in ipairs(blocker.attrs) do
      named[#named + 1] = attr .. "="
    end
    if report then
      qi_core.warn(('%s="%s" on %s carries %s as well, and a cross-reference takes the place of a locator, so this mark has no locator to emphasize; the role is dropped and the mark indexes as it would without it'):format(qi_core.MENTION_ATTR, value, context, table.concat(named, " and ")))
    end
    return nil
  end
  return value
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

-- ---------------------------------------------------------------------------
-- Page ranges.
--
-- A range is two marks of one entry — an opening and a closing — that the
-- index prints as one locator spanning both. Which mark is which end is a fact
-- about what the author wrote, so it is judged here, before any back-end
-- branch, and every back-end reads the same verdict.
--
-- Pairing takes a pass of its own, for the reason the contested keys do:
-- whether an opening is ever closed takes the WHOLE document to know, and the
-- LaTeX back-end cannot emit a range opening until it does. makeindex writes a
-- transcript warning for an unmatched, extra or inconsistently encapsulated
-- range, and Quarto fails a render on exactly that warning — so a range this
-- extension cannot pair must never reach the index tool at all (IP2). Every
-- refusal below therefore degrades the mark to an ordinary locator, which
-- indexes the term at its own page and breaks nothing.
--
-- The two halves are separate because their SCOPES are. Whether a mark names
-- an end at all, and whether it has a locator for a range to span, are facts
-- about that one mark; whether an opening is closed is a fact about the
-- document — and in a book, about the whole book, since a range opened in one
-- chapter and closed in another is unmatched in both and neither chapter's
-- render may say so. So `range_end` is drawn per mark wherever the mark is
-- rendered, and `pair_ranges` is run once over whatever set is the right one:
-- this document's marks here, every chapter's records in `qi_book`.
-- ---------------------------------------------------------------------------

-- One range finding, reported. Every message is written at its own `warn()`
-- call rather than composed where the finding is made and handed in: the
-- message-distinctness scan reads the string literals INSIDE a `warn()` call,
-- and a message built elsewhere is text no such scan can see — the blindness
-- M13 and M19 both hit, in the two shapes recorded on the acceptance-suite
-- candidate row. So a finding travels as what was found, never as prose.
--
-- `scope` is the set an opening had to be closed within, which is the word the
-- pairing messages use: an author told "this document" in a book would go
-- looking in the wrong file.
local function report_range(found, scope)
  if found.kind == "unrecognized" then
    qi_core.warn(('%s= on %s names neither end of a range ("%s"); the mark indexes as though the attribute were absent'):format(qi_core.RANGE_ATTR, found.context, found.value))
  elseif found.kind == "displaced" then
    qi_core.warn(('%s="%s" on %s carries %s as well, and a cross-reference takes the place of a locator, so there is no locator for a range to span; the range is dropped and the mark indexes as it would without it'):format(qi_core.RANGE_ATTR, found.value, found.context, found.named))
  elseif found.kind == "already-open" then
    qi_core.warn(('%s="open" on %s opens a range for a term whose range is already open; the earlier opening is the one the next closing pairs with, so this mark indexes as an ordinary page number instead'):format(qi_core.RANGE_ATTR, found.context))
  elseif found.kind == "never-opened" then
    qi_core.warn(('%s="close" on %s closes a range this %s never opens; the mark indexes as an ordinary page number instead'):format(qi_core.RANGE_ATTR, found.context, scope))
  else
    qi_core.warn(('%s="open" on %s is never closed in this %s; the mark indexes as an ordinary page number instead of opening a range'):format(qi_core.RANGE_ATTR, found.context, scope))
  end
end

-- Which end one mark names, from the value the author wrote. Returns the end,
-- or nil with the finding that says why there is none.
--
-- `blocked` is the cross-reference attributes that take the locator's place,
-- in the fixed order the caller passes them, or nil where the mark contributes
-- a locator — the same shape as `mention_role`'s blocker and derived the same
-- way, from the targets that SURVIVE the self-reference drop, so a target that
-- is itself about to be dropped never displaces a range.
--
-- The unrecognized value is judged first and the two never fire together: a
-- value naming neither end is not a range yet, and telling an author their
-- range was displaced by a cross-reference would send them looking in the
-- wrong place. An EMPTY value is unrecognized rather than absent, exactly as
-- it is for a mention role: it is a value the author wrote, and reading it as
-- absence would swallow a typo silently.
local function range_end(value, context, blocked)
  if not qi_core.RANGE_ENDS[value] then
    return nil, { kind = "unrecognized", context = context, value = value }
  end
  if blocked ~= nil then
    -- One attribute reads `see=`, two `see= and see-also=`, in the fixed order
    -- the caller passes them.
    local named = {}
    for _, attr in ipairs(blocked) do
      named[#named + 1] = attr .. "="
    end
    return nil, { kind = "displaced", context = context, value = value,
                  named = table.concat(named, " and ") }
  end
  return value, nil
end

-- Pair a set of range marks. `items` is every mark that named an end, in the
-- order they are indexed, each `{ key, ending, principal, context }`. Returns
-- a verdict per item — `{ ending, principal }` for a mark that keeps its end,
-- `false` for one that is refused — and the pairing findings.
--
-- The role is the RANGE's, not either end's: two marks of one span are one
-- discussion, so a role written on either end is a role on the span, and both
-- verdicts carry it. Settled once here so that makeindex's requirement — the
-- two ends of a range must not differ by any byte of encapsulation — is met by
-- construction rather than by both ends happening to agree. Reading each end's
-- own attribute instead dropped a role written on the closing mark in silence
-- (review F2).
local function pair_ranges(items)
  local verdicts, found, pending, waiting = {}, {}, {}, {}
  for i, item in ipairs(items) do
    if item.ending == "open" then
      if pending[item.key] ~= nil then
        verdicts[i] = false
        found[#found + 1] = { kind = "already-open", context = item.context }
      else
        verdicts[i] = { ending = "open", principal = item.principal }
        pending[item.key] = i
        -- The OPENING's own position, not its key: a key opened, closed and
        -- opened again appends twice, and walking by key below would then
        -- report the second opening in the first one's place. Entries whose
        -- key has since moved on are skipped there.
        waiting[#waiting + 1] = i
      end
    else
      local at = pending[item.key]
      if at == nil then
        verdicts[i] = false
        found[#found + 1] = { kind = "never-opened", context = item.context }
      else
        pending[item.key] = nil
        local principal = verdicts[at].principal or item.principal
        -- Written back onto the OPENING's verdict too, which is what makes a
        -- role declared on the closing reach the end that registers the
        -- range's start page and, in HTML, the end that carries the locator.
        verdicts[at].principal = principal
        verdicts[i] = { ending = "close", principal = principal }
      end
    end
  end
  -- Whatever is still open was never closed. Walked in the order the openings
  -- were written rather than by table iteration, so the findings do not depend
  -- on Lua's hash order.
  for _, at in ipairs(waiting) do
    if pending[items[at].key] == at then
      pending[items[at].key] = nil
      verdicts[at] = false
      found[#found + 1] = { kind = "never-closed", context = items[at].context }
    end
  end
  return verdicts, found
end

-- The document's own range marks, in document order, and the findings held
-- against them. The findings wait rather than being reported where they are
-- made: the mark-local ones so they print after the per-mark reports the
-- emitting pass draws, and the pairing ones because a book chapter is not the
-- set a range is paired in.
local range_items = {}
local range_found = {}
local range_pair_found = {}
-- Entry key -> that key's verdicts in document order, and how many of them the
-- emitting pass has read. A queue per key rather than one list in document
-- order: the collecting pass and the emitting pass each walk the document
-- once, in the same order, and taking the next verdict for THIS mark's key is
-- what keeps the two in step.
local range_plan = {}
local range_cursor = {}

-- Called by the collecting pass, once per range mark that indexes an entry.
local function plan_range(value, key, context, blocked, principal)
  local ending, found = range_end(value, context, blocked)
  if ending == nil then
    range_found[#range_found + 1] = found
    -- Still an item for this key, so the emitting pass reading verdicts in
    -- order does not hand this mark's refusal to the next mark of the key.
    range_items[#range_items + 1] = { key = key, ending = false }
    return
  end
  range_items[#range_items + 1] =
    { key = key, ending = ending, principal = principal, context = context }
end

-- Called once the whole document has been read.
local function finish_ranges()
  local paired = {}
  for _, item in ipairs(range_items) do
    if item.ending then
      paired[#paired + 1] = item
    end
  end
  local verdicts
  verdicts, range_pair_found = pair_ranges(paired)
  local at = 0
  for _, item in ipairs(range_items) do
    local verdict = false
    if item.ending then
      at = at + 1
      verdict = verdicts[at]
    end
    local queue = range_plan[item.key]
    if queue == nil then
      queue = {}
      range_plan[item.key] = queue
    end
    queue[#queue + 1] = verdict
  end
end

-- The next verdict for this key, read by the emitting pass. Nil for a mark
-- whose end was refused, and nil for a mark whose key has no verdicts at all.
local function next_range(key)
  local n = (range_cursor[key] or 0) + 1
  range_cursor[key] = n
  local queue = range_plan[key]
  local verdict = queue and queue[n]
  if verdict then
    return verdict
  end
  return nil
end

-- Draw the held findings. `pairing` says whether the pairing ones are this
-- document's to draw: false in a book chapter, where the whole store is what
-- a range is paired in.
local function report_ranges(pairing)
  for _, found in ipairs(range_found) do
    report_range(found, "document")
  end
  if pairing then
    for _, found in ipairs(range_pair_found) do
      report_range(found, "document")
    end
  end
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
M["report_range"] = report_range
M["range_end"] = range_end
M["pair_ranges"] = pair_ranges
M["plan_range"] = plan_range
M["finish_ranges"] = finish_ranges
M["next_range"] = next_range
M["report_ranges"] = report_ranges
M["mention_role"] = mention_role
M["derive_levels"] = derive_levels

return M
