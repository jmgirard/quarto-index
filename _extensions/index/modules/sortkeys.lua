-- The sort-key registry: which printed level path files under which sort key,
-- and the report drawn when two marks disagree about that.
--
-- It keys on `qi_levels.level_path`, so it lives beside the level semantics
-- rather than in either back-end: both read the same registry.

local qi_core = require("./core")
local qi_levels = require("./levels")

local M = {}

-- Printed level path -> the first sort key declared for it, and the context
-- that declared it. Two marks that file ONE printed level under two different
-- sort keys are an authoring mistake with a visible cost in both back-ends:
-- the HTML tree is keyed on the printed levels, so one of the two keys simply
-- loses, and makeindex treats the two as different keys and prints the entry
-- twice, in two places, identically. Neither is recoverable from the output,
-- so the mistake is reported instead. The accumulator is format-neutral —
-- filled before any back-end branch — because it is a property of what the
-- author wrote, like every other warning about the mark itself.
-- One namespace per index (M38): two indexes of one document are two indexes,
-- so a sort key written in one says nothing about where the same printed text
-- files in the other. A back-end that keeps one index resolves every mark to
-- that one before it gets here, so its registry has a single namespace and
-- behaves exactly as it did.
local sort_keys = {}

-- This index's share of the registry, created on first use.
local function for_index(index)
  return qi_core.namespace(sort_keys, index)
end

-- Register a mark's declared sort keys, one per level, and report a second,
-- different key for a level already spoken for. First mark in document order
-- wins, so the index does not depend on which mark the author edits last.
-- Only a level the author actually wrote a key for registers or conflicts: a
-- term is usually marked in several places and a sort key written on one of
-- them is meant for the entry, not for that one mark (GP4), so the marks that
-- stay silent inherit it rather than contradict it.
local function register_sort(index, levels, declared, context)
  if declared == nil then
    return
  end
  local registry = for_index(index)
  for i = 1, #levels do
    local key = declared[i]
    -- Positional filler was already dropped by qi_levels.sort_levels, so everything
    -- arriving here is a declaration — including one whose text equals the
    -- level's own, which is an author saying where the level files and so
    -- wins ties and reports rivals like any other.
    if key then
      local path = qi_levels.level_path(levels, i)
      local seen = registry[path]
      if seen == nil then
        registry[path] = { sort = key, context = context }
      elseif seen.sort ~= key then
        -- Once per RIVAL KEY at this path, not once per mark carrying it: a
        -- term is usually marked in several places, and repeating one rival
        -- key gives the author nothing further to fix. A second, different
        -- rival is a second thing to fix, though — the message names the key
        -- it is about, so suppressing it would leave that key unmentioned
        -- until the first was resolved and the document rendered again.
        -- The two marks are usually described identically — the same term,
        -- twice — so the message names the two KEYS, which are what actually
        -- differ and what the author has to choose between.
        seen.reported = seen.reported or {}
        if not seen.reported[key] then
          seen.reported[key] = true
          qi_core.warn(('index entry in %s is already sorted as "%s"; the sort key '
                .. '"%s" written here cannot apply as well, so the first one '
                .. 'wins'):format(context, seen.sort, key))
        end
      end
    end
  end
end

-- What the emitting pass applies: for each level, the key registered for that
-- level's path — whichever mark of it declared one — and the level's own
-- printed text where no mark declared anything. Returns nil when no level on
-- this path has a key, so a mark with no sort key anywhere above or at it
-- emits exactly what it always did.
local function sort_for(index, levels)
  local registry = for_index(index)
  local resolved, any = {}, false
  for i = 1, #levels do
    local seen = registry[qi_levels.level_path(levels, i)]
    if seen then
      resolved[i] = seen.sort
      any = true
    else
      resolved[i] = levels[i]
    end
  end
  if not any then
    return nil
  end
  return resolved
end

-- Clamp sort levels alongside the entry levels qi_levels.clamp_levels performs. The
-- folded third level is one printed string built from several, so it files
-- under the sort key of the first level that went into it — joining sort keys
-- the way the printed text is joined would file the entry under text no author
-- wrote. A key written for a level past the third goes where that level went:
-- the level itself is folded away, so there is nothing left for its key to
-- place, and the fold warning already names the entry.
local function clamp_sort(sort)
  if sort == nil or #sort <= qi_levels.MAX_LEVELS then
    return sort
  end
  local clamped = {}
  for i = 1, qi_levels.MAX_LEVELS do
    clamped[i] = sort[i]
  end
  return clamped
end

-- The one cell this module owns, back to the value its declaration gives, for
-- the reason marks.lua's own `reset` states. Emptied in place: the registry is
-- exported by reference and qi_book reads it through that export.
local function reset()
  qi_core.empty(sort_keys)
end

-- Exported through the bracket form, never `M.NAME = NAME`: the source
-- scans take the FIRST match for `NAME =` over the whole source set, and
-- the M16-AC3 probe relocates a definition into another file — a plain
-- `NAME =` line left behind here would then mask it (M16 review F3).
M["reset"] = reset
M["sort_keys"] = sort_keys
M["for_index"] = for_index
M["register_sort"] = register_sort
M["sort_for"] = sort_for
M["clamp_sort"] = clamp_sort

return M
