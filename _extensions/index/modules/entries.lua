-- The entry tree the HTML, EPUB and Typst back-ends print: the marks split by
-- index, walked into one node per level, ordered and grouped by letter.
--
-- Nothing here knows how a locator is written. A mark names its place in its
-- own back-end's terms (an HTML anchor, a Typst label), and each back-end hands
-- `build_entry_tree` the function that turns a mark into a locator on its
-- node. What every back-end shares is the order and the grouping, so an index
-- cannot file one term in two places in two formats.

local qi_core = require("./core")
local qi_indexes = require("./indexes")
local qi_levels = require("./levels")

local M = {}

-- The normative collation rule, in two parts (M07).
--
-- Top-level entries are RANKED INTO GROUPS first: everything that does not
-- file under an ASCII letter comes first as one Symbols group, then one group
-- per letter in A-Z order. Within a group — and at every level below the top,
-- which is not grouped at all — the rule is: fold ASCII uppercase to
-- lowercase, order by codepoint, break a fold tie by codepoint. Lua compares
-- strings byte by byte and UTF-8 byte order IS codepoint order, so `<` is
-- that part of the rule as stated. Only ASCII case folds: ordering beyond
-- that is best-effort, and a sort key is how an author overrides it (DESIGN,
-- Conventions).
local function fold_case(s)
  return (s:gsub("[A-Z]", string.lower))
end

local function collate(a, b)
  local fa, fb = fold_case(a), fold_case(b)
  if fa ~= fb then
    return fa < fb
  end
  return a < b
end

-- The group every entry that files under no ASCII letter belongs to, and the
-- English word its heading prints.
--
-- These are two different jobs, and the constant is BOTH only as long as
-- nobody overrides the word. The string is the group's IDENTITY -- what
-- `group_label` returns, what `group_rank` ranks first, and what tells a run
-- of non-letter entries from the letter groups -- and an author's own word is
-- substituted where the heading is printed and nowhere else (`grouped_blocks`).
-- Letting the author's word be the identity would make a word that is a single
-- ASCII letter merge with that letter's group, and a word sorting after `A`
-- re-rank the group out of the lead.
local SYMBOLS_LABEL = "Symbols"
local SYMBOLS_KEY = "symbols"

-- The group a top-level entry belongs to, named by the label its heading
-- shows. The argument is the string the entry FILES under — its sort key
-- where it has one, its printed text where it does not — so an author moves
-- an entry between groups exactly the way they move it within one. Only an
-- ASCII letter makes a letter group: the first byte of a UTF-8 sequence is
-- never one, so a term starting in any other script files under Symbols,
-- which is honest about a collation that is ASCII-only anyway.
local function group_label(filing)
  local first = filing:sub(1, 1)
  -- `[A-Za-z]` rather than `%a`, whose meaning follows the C locale and so
  -- could differ between one machine and another.
  if first:match("^[A-Za-z]$") then
    return first:upper()
  end
  return SYMBOLS_LABEL
end

-- Where a group sorts among the groups. Symbols ranks as the empty string,
-- which is below every letter, so it leads — one group, ahead of A, as print
-- convention and makeindex both set an index.
local function group_rank(filing)
  local label = group_label(filing)
  if label == SYMBOLS_LABEL then
    return ""
  end
  return fold_case(label)
end

-- A cross-reference target as a reader sees it: the same `: ` join the LaTeX
-- back-end prints, so the back-ends cannot drift apart on target text.
local function target_text(levels)
  return table.concat(levels, qi_levels.TARGET_JOIN)
end

-- Literal text as inlines. Words and spaces are separate nodes because that is
-- what Pandoc's own reader produces; every character stays literal, and the
-- writer escapes whatever its format needs escaped.
local function literal_inlines(text)
  local inlines = pandoc.List()
  local pos = 1
  while true do
    local space = text:find(" ", pos, true)
    if not space then
      inlines:insert(pandoc.Str(text:sub(pos)))
      return inlines
    end
    inlines:insert(pandoc.Str(text:sub(pos, space - 1)))
    inlines:insert(pandoc.Space())
    pos = space + 1
  end
end

-- Two targets are the same target when their LEVEL LISTS are equal — never
-- when their rendered text is. A single level containing the level join reads
-- exactly like a two-level target, so comparing the joined string folds two
-- genuinely different cross-references into one and silently loses the
-- author's second one (IP2).
local function same_levels(a, b)
  if #a ~= #b then
    return false
  end
  for i = 1, #a do
    if a[i] ~= b[i] then
      return false
    end
  end
  return true
end

-- `key` is the level's printed text, and it is what `children` is keyed by:
-- node identity stays the printed text so that two terms sharing one sort key
-- remain two entries. `sort` is only where the node FILES, filled in from the
-- mark's aligned sort levels and falling back to `key` when there is none.
local function new_entry(key)
  return { key = key, sort = nil, children = {}, sorted = {},
           locators = {}, xrefs = {} }
end

-- Walk the recorded marks into a tree of entries, one level per node.
-- `add_locator(node, mark)` is the back-end's: it reads the fields that name
-- the mark's place in that back-end and adds whatever locator the mark
-- contributes to `node.locators`, or nothing. Marks reach it in document
-- order, one index's marks at a time.
local function build_entry_tree(marks, add_locator)
  local root = new_entry(nil)
  for _, mark in ipairs(marks) do
    local node = root
    for i, level in ipairs(mark.levels) do
      local child = node.children[level]
      if not child then
        child = new_entry(level)
        node.children[level] = child
      end
      -- One entry has one sort key: the collect pass settled which, and every
      -- mark of the entry arrives carrying it. Assigned only once all the
      -- same, so that a book aggregating chapters cannot have a later
      -- chapter's record quietly overwrite the key the index was ordered by.
      if child.sort == nil and mark.sort ~= nil then
        child.sort = mark.sort[i]
      end
      node = child
    end
    add_locator(node, mark)
    for _, xref in ipairs(mark.xrefs) do
      -- Two marks carrying the same target on the same key are one
      -- cross-reference, not two — printing it twice would report how the
      -- author spread the marks rather than anything a reader wants. This is
      -- also what the LaTeX index tool does with a repeated cross-reference.
      local already = false
      for _, existing in ipairs(node.xrefs) do
        if existing.kind.attr == xref.kind.attr
           and same_levels(existing.levels, xref.levels) then
          already = true
        end
      end
      if not already then
        node.xrefs[#node.xrefs + 1] = xref
      end
    end
  end
  return root
end

-- Sort every node's children and give each entry its id, depth-first in the
-- order it will be rendered. Ids are assigned before anything is rendered
-- because a cross-reference may point at an entry that sorts after it, and
-- they skip every id `taken` already holds — an id this extension mints and
-- an id the author wrote must never be the same string, or one of the two
-- links silently goes to the wrong place.
local function number_entries(node, counter, taken)
  local keys = {}
  for key in pairs(node.children) do
    keys[#keys + 1] = key
  end
  -- Entries file under their sort key where they have one and under their own
  -- printed text where they do not, and two entries sharing one sort key fall
  -- back to collating their printed text — which keeps the order total, so
  -- table.sort cannot see an inconsistent comparator.
  --
  -- The top level, and only the top level, ranks by group before it collates:
  -- the root is the one node with no key of its own, and a sub-entry files
  -- under its parent rather than under a letter. Group rank is a function of
  -- the same filing string the collation reads, so two entries that collate
  -- equal can never rank into different groups.
  local top_level = node.key == nil
  table.sort(keys, function(a, b)
    local ka = node.children[a].sort or a
    local kb = node.children[b].sort or b
    if top_level then
      local ga, gb = group_rank(ka), group_rank(kb)
      if ga ~= gb then
        return ga < gb
      end
    end
    if ka ~= kb then
      return collate(ka, kb)
    end
    return collate(a, b)
  end)
  node.sorted = keys
  for _, key in ipairs(keys) do
    local child = node.children[key]
    repeat
      counter = counter + 1
    until not taken[qi_core.HTML_ENTRY_PREFIX .. counter]
    child.id = qi_core.HTML_ENTRY_PREFIX .. counter
    taken[child.id] = (taken[child.id] or 0) + 1
    counter = number_entries(child, counter, taken)
  end
  return counter
end

-- The top level of a numbered tree, one group per heading, in printed order:
-- each group is `{ heading = <the text its heading prints>, keys = {...} }`.
-- `root.sorted` must already be set by `number_entries`.
local function letter_groups(root, name)
  local groups = {}
  local pending = {}
  local label = nil
  -- What this index's groups actually head, for the report at the foot of this
  -- function. Collected as each heading is settled rather than derived from the
  -- entries a second time: the question is whether two groups a READER sees
  -- carry one heading, so the thing compared is the text that is printed.
  local letters = {}
  local symbols_heading = nil

  local function flush()
    if #pending > 0 then
      -- The only place the Symbols group's own word is read: every letter
      -- group prints the letter it is, and the non-letter group prints
      -- whatever this index calls it.
      local heading = label
      if heading == SYMBOLS_LABEL then
        heading = qi_indexes.label(name, SYMBOLS_KEY, SYMBOLS_LABEL)
        symbols_heading = heading
      else
        letters[heading] = true
      end
      groups[#groups + 1] = { heading = heading, keys = pending }
      pending = {}
    end
  end

  for _, key in ipairs(root.sorted) do
    local child = root.children[key]
    local this = group_label(child.sort or key)
    if this ~= label then
      -- The keys are already ranked by group, so a change of label is the end
      -- of a group rather than the start of a second run of one.
      flush()
      label = this
    end
    pending[#pending + 1] = key
  end
  flush()
  -- Two groups of one index under one heading. The sentinel above keeps the
  -- non-letter group's identity and its rank whatever the author calls it, so
  -- the two groups neither merge nor re-rank and what prints is unchanged --
  -- but a reader of `symbols: "A"` sees an `A` heading over the non-letter
  -- entries and a second `A` heading over the real A group, and reads one
  -- group split in two (M56 review F13).
  --
  -- Reported HERE and not where the word is read, because only this site knows
  -- whether a clashing letter group exists: the same word is no clash in an
  -- index whose terms all file under no letter, and the LaTeX back-end prints
  -- no letter groups at all, so a report drawn at the reading site would fire
  -- on a PDF render that has nothing to see. The back-ends that print letter
  -- groups all reach this function.
  --
  -- Compared character for character rather than case-insensitively: a letter
  -- group always heads a capital, so a lowercase word prints a heading a reader
  -- can tell from it.
  if symbols_heading ~= nil and letters[symbols_heading] then
    qi_core.warn(('%s: the word "%s" heads the entries filing under no letter in %s and is also the heading of one of its letter groups, so a reader sees two groups under one heading; a word that is not a letter this index files a term under heads one group'):format(qi_indexes.LABELS_KEY, symbols_heading, qi_indexes.scope_phrase(name, "this document")))
  end
  return groups
end

-- This document's marks, split into the index each files in, each list still
-- in document order.
--
-- A key that is no declared name files in the first index this document does
-- declare, rather than in a group the loop below never reaches and so never
-- prints. Both callers settle their own names before they get here — a single
-- document's marks through `mark_index` as each is read, a book's records
-- through `fold_undeclared` as they are read back — and each is reported where
-- it resolved, which is why nothing is reported again here. This is the floor
-- under both: a mark that reached the builder is a mark that prints, and a
-- group silently dropped would be an author's term missing from the index
-- with nothing said about it (IP2).
local function marks_by_index(marks)
  local grouped = {}
  for _, mark in ipairs(marks) do
    local list = qi_core.namespace(grouped,
      qi_indexes.authored_index(mark.index or qi_indexes.default()))
    list[#list + 1] = mark
  end
  return grouped
end

-- Exported through the bracket form, never `M.NAME = NAME`: the source
-- scans take the FIRST match for `NAME =` over the whole source set, and
-- the M16-AC3 probe relocates a definition into another file — a plain
-- `NAME =` line left behind here would then mask it (M16 review F3).
M["fold_case"] = fold_case
M["collate"] = collate
M["SYMBOLS_LABEL"] = SYMBOLS_LABEL
M["SYMBOLS_KEY"] = SYMBOLS_KEY
M["group_label"] = group_label
M["group_rank"] = group_rank
M["target_text"] = target_text
M["literal_inlines"] = literal_inlines
M["same_levels"] = same_levels
M["new_entry"] = new_entry
M["build_entry_tree"] = build_entry_tree
M["number_entries"] = number_entries
M["letter_groups"] = letter_groups
M["marks_by_index"] = marks_by_index

return M
