-- Level semantics: what an `entry=`, `see=` or `sort=` value means as a list
-- of index levels, before any back-end sees it.
--
-- Format-neutral by construction — the three-level ceiling clamped here is
-- the LaTeX back-end's, but the clamp itself has to run where the levels are
-- parsed, since depth is counted after empty levels are dropped (D-002).

local qi_core = require("./core")

local M = {}

-- Split an `entry=` value into sub-entry levels: `!` separates, `!!` is a
-- literal `!`, longest-match left to right.
local function parse_levels(value)
  local levels, current, i = {}, {}, 1
  while i <= #value do
    local c = value:sub(i, i)
    if c == "!" then
      if value:sub(i + 1, i + 1) == "!" then
        current[#current + 1] = "!"
        i = i + 2
      else
        levels[#levels + 1] = table.concat(current)
        current = {}
        i = i + 1
      end
    else
      current[#current + 1] = c
      i = i + 1
    end
  end
  levels[#levels + 1] = table.concat(current)
  return levels
end

-- The inverse of parse_levels: one string that identifies a level list, and
-- identifies it injectively, because a level's own `!` is doubled exactly as
-- an author would have written it. A plain `table.concat(levels, "!")` would
-- make {"a!b"} and {"a","b"} the same string, which would merge two distinct
-- entries in the conflict report below. Format-neutral: no back-end escaping.
local function levels_key(levels)
  local parts = {}
  for i, level in ipairs(levels) do
    parts[i] = level:gsub("!", "!!")
  end
  return table.concat(parts, "!")
end

-- Render one literal level as a LaTeX `\index{}` argument fragment.
local function escape_level(level)
  return (level:gsub(".", function(c)
    return qi_core.LATEX_LITERAL[c] or c
  end))
end

-- makeindex stores at most three levels: it rejects a deeper entry outright
-- ("Extra `!'"), drops it from the index, and still exits 0 — the build looks
-- clean and the entry is simply gone. Rather than lose it (IP2 forbids silent
-- corruption), fold everything past the third level into the third.
local MAX_LEVELS = 3
local OVERFLOW_JOIN = ", "

-- How a report names a depth (D-006). `count` is the levels there are now, and
-- `written` the number the author typed, before the empty-level drop; the
-- written one is named too wherever the two differ, so the number a report
-- gives can be found in the value as it was typed. Where they agree, or where
-- the caller has no written count to offer, one number is stated and nothing is
-- implied about a drop that took nothing away. Shared with the LaTeX back-end,
-- whose folded-target report names a depth in the same words for the same
-- reason.
local function depth_phrase(count, written)
  if written == nil or written == count then
    return ("%d levels deep"):format(count)
  end
  return ("%d levels deep, of the %d written"):format(count, written)
end

-- `report` follows the convention derive_levels and drop_empty_levels already
-- use: a mark's levels are derived by more than one pass, and only the pass
-- that emits says so, or one stray `!` is reported once per pass that looked.
local function clamp_levels(levels, context, report, written)
  if #levels <= MAX_LEVELS then
    return levels
  end
  -- Every level here prints something: an empty one was dropped when the entry
  -- was derived (drop_empty_levels), so the join can never leave a dangling
  -- separator in the printed index.
  local tail = {}
  for i = MAX_LEVELS, #levels do
    tail[#tail + 1] = levels[i]
  end
  if report then
    qi_core.warn(("index entry in %s is %s; the back-end stores %d, so "
          .. "levels %d and deeper were folded into the third")
         :format(context, depth_phrase(#levels, written), MAX_LEVELS,
                 MAX_LEVELS))
  end
  local clamped = {}
  for i = 1, MAX_LEVELS - 1 do
    clamped[i] = levels[i]
  end
  clamped[MAX_LEVELS] = table.concat(tail, OVERFLOW_JOIN)
  return clamped
end

-- Cross-reference targets are typeset prose, not an index key, so their levels
-- are joined for a reader rather than with makeindex's `!`. The `!` is not
-- available anyway: makeindex rejects an unquoted one inside the encap
-- argument ("Extra `!'") and Quarto turns that rejection into a failed render,
-- while a quoted `"!` survives but prints this extension's own level syntax in
-- the middle of a sentence. `, ` was rejected as the join because it is
-- ambiguous when a level itself contains a comma: "see Smith, John, early
-- work" against "see Smith, John: early work".
local TARGET_JOIN = ": "

-- Render cross-reference target levels as an encap argument. The `.ind` file
-- makeindex writes is read back as ordinary LaTeX, so the same per-character
-- mechanisms a source level needs are the ones that work here; the spike put
-- every printable ASCII character through this path and makeindex rejected
-- none of them.
local function target_argument(levels)
  local parts = {}
  for _, level in ipairs(levels) do
    parts[#parts + 1] = escape_level(level)
  end
  return table.concat(parts, TARGET_JOIN)
end

-- An empty level prints nothing, so it is not a level: the entry indexes at
-- whatever is left. Dropping it is a property of what the author wrote rather
-- than of any one back-end, so it happens once here and every format sees the
-- same levels — and it is what keeps a null field away from the LaTeX index
-- tool, which rejects an entry outright for a leading or middle one, drops it,
-- reports no warning and exits 0.
--
-- Returns the surviving levels, the ORIGINAL index of each (so a sort level
-- can be dropped together with the entry level it was written for), and the
-- depth the author actually wrote.
local function drop_empty_levels(parsed, context, report)
  local levels, kept = {}, {}
  for i, level in ipairs(parsed) do
    if level ~= "" then
      levels[#levels + 1] = level
      kept[#kept + 1] = i
    end
  end
  -- Silent when NOTHING survived: the caller has a single message for that
  -- mark, about the value as a whole, and a count of levels none of which
  -- printed anything would only bury it.
  --
  -- One report per MARK, not one per dropped level. Two byte-identical
  -- warnings for `entry="!Sub!"` told the author a level went twice and which
  -- end neither time (M11 review F8). The positions are counted in the value
  -- as the author wrote it, which is the only numbering they can find their
  -- own `!` by — levels, note, not `!` characters, since `!!` is a literal `!`
  -- and not two separators. How many levels remain is stated of that same
  -- written value, never of what the entry indexes at, which this layer cannot
  -- state format-neutrally: the three-level fold runs later, in the back-end
  -- that imposes it.
  if report and #levels > 0 and #levels < #parsed then
    local empty = {}
    for i, level in ipairs(parsed) do
      if level == "" then
        empty[#empty + 1] = tostring(i)
      end
    end
    local where
    if #empty == 1 then
      where = ("position %s of %d"):format(empty[1], #parsed)
    else
      where = ("positions %s and %s of %d")
              :format(table.concat(empty, ", ", 1, #empty - 1),
                      empty[#empty], #parsed)
    end
    local remain = #levels == 1
                   and ("1 of the %d written levels remains"):format(#parsed)
                   or ("%d of the %d written levels remain")
                      :format(#levels, #parsed)
    -- One literal, not concatenated. The distinctness scan joins every literal
    -- in a call's message expression now, so a split would not hide this
    -- message from it — but the suite asserts the single-literal form here,
    -- because a message assembled from fragments is one an editor can change a
    -- fragment of without seeing what the whole says.
    qi_core.warn(("empty index level in %s at %s; an empty level prints nothing, so it is dropped and %s"):format(context, where, remain))
  end
  return levels, kept, #parsed
end

-- Parse a `sort=` value and line it up with the entry's levels. The result
-- says only what the AUTHOR declared: element i is the sort key written for
-- level i, or `false` where the author wrote nothing there. The printed-text
-- fallback is applied later, by `sort_for`, because only the registry knows
-- whether some other mark of the same level declared a key — substituting the
-- fallback here is what made a silent mark overwrite a declaring one.
--
-- An empty sort level means "leave this level alone", which is why it is not
-- warned about the way an empty ENTRY level is: there it is a hole in what the
-- author is indexing, here it is the ordinary way to skip a level.
--
-- Returns nil when the value declares no sort key at all, which keeps a
-- document that never writes `sort=` byte-identical in the LaTeX back-end.
local function sort_levels(value, levels, context, report, kept, depth)
  if value == nil then
    return nil
  end
  local written = parse_levels(value)
  -- Lined up with the entry levels that SURVIVED the empty-level drop. A sort
  -- level belongs to the level it was written for, so one written for a level
  -- that printed nothing goes with it rather than sliding onto the next: with
  -- `entry="!Cats" sort="mmm!cats"`, `Cats` files under `cats`, never `mmm`.
  local parsed = written
  if kept ~= nil then
    parsed = {}
    for i, original in ipairs(kept) do
      parsed[i] = written[original]
    end
  end
  -- The depth the AUTHOR wrote, which is what the ignored-levels count below
  -- is measured against — an entry whose empty level was dropped has not
  -- ignored the sort level that went with it, and saying so would draw a
  -- second warning for one mistake.
  depth = depth or #levels
  -- The last position the author actually wrote a key for. Everything before
  -- it that merely restates the level's own printed text is positional filler
  -- — the way this syntax reaches a deeper level, since two separators in a
  -- row are a literal `!` — while a self-equal key AT that last position is a
  -- real declaration, the author saying where this level files.
  --
  -- Found in `written` and compared below against each level's ORIGINAL
  -- position, because it is a fact about what the author typed. Reading it off
  -- the realigned list instead makes the last surviving level a declaration
  -- whenever the sort key ran deeper than the entry — turning filler into a
  -- declaration on entries with no empty level at all, which loses another
  -- mark's genuine key and invents a rival-key report (M11 review F1).
  local last = 0
  for i = 1, #written do
    if written[i] ~= "" then
      last = i
    end
  end
  if report then
    -- Counted over the levels the author DECLARED past the entry's depth: an
    -- empty sort level is the documented "leave this level alone", so a
    -- trailing empty one ignores nothing and must not say it did.
    local ignored = 0
    for i = depth + 1, #written do
      if written[i] ~= "" then
        ignored = ignored + 1
      end
    end
    if ignored > 0 then
      -- Both numbers are counts taken BEFORE the empty-level drop: `#written`
      -- is what the author wrote in `sort=`, and `depth` what the mark had to
      -- sort at the time this comparison is made. What the second number is
      -- measured over is now SAID rather than left to a clause about a drop
      -- (D-006): the old wording named the drop on every mark, including the
      -- ones no drop touched, and on the ones it did touch the number is not
      -- what the mark ends up sorting either. It was already a third number
      -- from the depth the entry indexes at — `entry="Moles!"` is written
      -- with 2, sorted with 3, and indexes at 1 — which is why it is named
      -- against the entry rather than against the index. What the `%s` costs
      -- is that its two clauses sit outside the call expression
      -- tests/scans/warn-distinct.py reads, so they are outside that scan's
      -- pinned literal count and its single-literal needle; the rendered-log
      -- pins in the M13 and M19 suite sections are what hold them.
      --
      -- Branching on `kept`, not on `depth`, which has been defaulted to
      -- `#levels` above. `kept` is nil exactly when the author wrote no
      -- `entry=` at all and the mark took qi_marks.derive_levels' plain
      -- visible-text branch; it is an EMPTY table, not nil, when they wrote an
      -- `entry=` whose every level was empty, and that mark IS told the depth
      -- it wrote, which it can find in its own source. So the nil branch is
      -- exactly the marks with no entry value to name, and naming one at them
      -- would be false (M13).
      --
      -- The noun agrees rather than assuming one level: the nil branch has
      -- exactly one today, since a visible term is one literal level, but
      -- `sort_levels` is exported and a caller passing a deeper fallback would
      -- otherwise print "the 3 level".
      local against = kept ~= nil
                      and ("the %d the entry is written with"):format(depth)
                      or ("the %d level%s its visible text makes")
                         :format(depth, depth == 1 and "" or "s")
      qi_core.warn(("sort= on %s writes %d levels against %s; the extra sort levels were ignored"):format(context, #written, against))
    end
    -- A key written for a level that prints nothing goes with that level. That
    -- is the rule, but it costs the author something they typed, so it is said
    -- rather than done quietly (M11 review F2). Counted only within the depth
    -- the author wrote: anything past it is the ignored-levels case above, and
    -- an EMPTY sort level lost with an empty entry level costs nothing.
    if kept ~= nil then
      local surviving = {}
      for _, original in ipairs(kept) do
        surviving[original] = true
      end
      local lost = 0
      for i = 1, math.min(depth, #written) do
        if not surviving[i] and written[i] ~= "" then
          lost = lost + 1
        end
      end
      if lost > 0 then
        local how_many = lost == 1 and "one index level that prints nothing"
                         or ("%d index levels that print nothing"):format(lost)
        qi_core.warn(("sort= on %s writes a key for %s; a key is dropped with the "
              .. "level it was written for, and the levels that remain keep "
              .. "their own"):format(context, how_many))
      end
    end
  end
  local declared, any = {}, false
  for i = 1, #levels do
    local key = parsed[i]
    -- Where this level sat in the value the author wrote, which is what `last`
    -- is measured in.
    local position = kept ~= nil and kept[i] or i
    if key ~= nil and key ~= ""
       and not (key == levels[i] and position < last) then
      declared[i] = key
      any = true
    else
      -- `false`, not nil: the list is written to the book store and read back
      -- through JSON, where a hole in the middle of an array is not a shape
      -- either side can rely on. Filler lands here too, so it never reaches
      -- the registry and never rivals a key some other mark declared.
      declared[i] = false
    end
  end
  if not any then
    return nil
  end
  return declared
end

-- The printed level path down to level `n`, as one injective string. A sort
-- key belongs to a LEVEL under its own parents, not to a whole entry: both
-- back-ends order level by level — makeindex reads `sortkey@printed` inside
-- each `!`-separated level, and the HTML tree keys each node on its printed
-- level text — so "Aaa" must file the same way whether it was written alone
-- or as the parent of a sub-entry. Keying the registry on the full entry path
-- instead is what split one printed entry across two keys.
local function level_path(levels, n)
  local prefix = {}
  for i = 1, n do
    prefix[i] = levels[i]
  end
  return levels_key(prefix)
end

-- Exported through the bracket form, never `M.NAME = NAME`: the source
-- scans take the FIRST match for `NAME =` over the whole source set, and
-- the M16-AC3 probe relocates a definition into another file — a plain
-- `NAME =` line left behind here would then mask it (M16 review F3).
M["parse_levels"] = parse_levels
M["levels_key"] = levels_key
M["escape_level"] = escape_level
M["MAX_LEVELS"] = MAX_LEVELS
M["OVERFLOW_JOIN"] = OVERFLOW_JOIN
M["clamp_levels"] = clamp_levels
M["depth_phrase"] = depth_phrase
M["TARGET_JOIN"] = TARGET_JOIN
M["target_argument"] = target_argument
M["drop_empty_levels"] = drop_empty_levels
M["sort_levels"] = sort_levels
M["level_path"] = level_path

return M
