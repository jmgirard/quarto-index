-- The HTML back-end: the entry tree, its ordering and grouping, the anchors
-- that link an entry back to its mark, and the index section built out of
-- them.

local qi_core = require("./core")
local qi_levels = require("./levels")
local qi_marks = require("./marks")

local M = {}

-- ---------------------------------------------------------------------------
-- The HTML back-end.
--
-- Nothing below writes HTML: the section is built out of Pandoc AST nodes and
-- handed to Pandoc's own writer, which owns escaping (IP2). There is no level
-- ceiling here — the three-level clamp is a makeindex property, not an index
-- property — and no CSS is injected; the class names are hooks an author can
-- style, not a stylesheet this extension imposes (GP4).
-- ---------------------------------------------------------------------------

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

local SYMBOLS_LABEL = "Symbols"

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
-- back-end prints, so the two back-ends cannot drift apart on target text.
local function target_text(levels)
  return table.concat(levels, qi_levels.TARGET_JOIN)
end

-- Literal text as inlines. Words and spaces are separate nodes because that is
-- what Pandoc's own reader produces; every character stays literal, and the
-- writer escapes whatever HTML needs escaped.
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

-- Where a locator link points. In a single document that is the mark's anchor
-- on this same page; in a book it is the mark's anchor on the page of the
-- chapter that carries it, written relative to the page holding the index.
-- One function for both, so a locator cannot mean two different things.
local function mark_target(mark)
  return (mark.href or "") .. "#" .. mark.anchor
end

-- Walk the recorded marks into a tree of entries, one level per node.
local function build_entry_tree(marks)
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
    -- A range's CLOSING contributes no locator: the pair is one locator, at
    -- the opening's anchor, which is where a reader starts reading. It keeps
    -- its anchor all the same — nothing links to it, but the mark is still a
    -- place in the text and removing its anchor would make the two ends of one
    -- range differently shaped for no reason a reader could see. `paired` is
    -- the mark's own chapter's verdict — the one scope a range pairs in
    -- (D-009), whether this index is a document's or the book's.
    if mark.anchor and mark.paired ~= "close" then
      -- A table rather than the bare target string: a locator now has a role
      -- as well as a destination, and the two travel together so a reordering
      -- cannot separate them (M20).
      node.locators[#node.locators + 1] =
        { target = mark_target(mark), role = mark.role }
    end
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
    taken[child.id] = true
    counter = number_entries(child, counter, taken)
  end
  return counter
end

-- Find the entry a cross-reference target names, matching on the parsed level
-- list rather than on the rendered string: a single level that happens to
-- contain the level join reads identically to a two-level target and must not
-- resolve to it.
local function lookup_entry(root, levels)
  local node = root
  for _, level in ipairs(levels) do
    node = node.children[level]
    if not node then
      return nil
    end
  end
  return node
end

local function target_span(root, xref)
  local inlines = literal_inlines(target_text(xref.levels))
  local entry = lookup_entry(root, xref.levels)
  if entry then
    inlines = pandoc.List({ pandoc.Link(inlines, "#" .. entry.id) })
  end
  return pandoc.Span(inlines, pandoc.Attr("", { "qi-target" }))
end

-- One entry's line: the term, then its numbered locator links, then its
-- cross-references. The separators follow print convention — locators and the
-- first cross-reference are set off from the term with a comma, and two
-- cross-references are separated with a semicolon, exactly as the LaTeX
-- back-end's dual-target command prints them.
local function entry_inlines(root, node)
  local inlines = pandoc.List()
  inlines:insert(pandoc.Span(literal_inlines(node.key),
                             pandoc.Attr(node.id, { "qi-term" })))

  local tail = pandoc.List()
  if #node.locators > 0 then
    local locators = pandoc.List()
    for i, locator in ipairs(node.locators) do
      if i > 1 then
        locators:insert(pandoc.Str(","))
        locators:insert(pandoc.Space())
      end
      -- The principal locator is emphasized with a Pandoc node and marked
      -- with a class. The class alone would need a stylesheet, and this
      -- extension ships none (GP3); the Strong is what makes the principal
      -- reference read as one in a page with no CSS at all, exactly as bold
      -- does in the printed index the LaTeX back-end produces.
      local principal = locator.role == "principal"
      local label = pandoc.Str(tostring(i))
      locators:insert(pandoc.Link(
        { principal and pandoc.Strong({ label }) or label },
        locator.target, "",
        pandoc.Attr("", principal and { qi_core.HTML_PRINCIPAL_CLASS } or {})))
    end
    tail:insert({ xref = false,
                  span = pandoc.Span(locators,
                                     pandoc.Attr("", { "qi-locators" })) })
  end
  for _, xref in ipairs(node.xrefs) do
    local body = pandoc.List()
    body:insert(pandoc.Emph(literal_inlines(xref.kind.label)))
    body:insert(pandoc.Space())
    body:insert(target_span(root, xref))
    tail:insert({ xref = true,
                  span = pandoc.Span(body, pandoc.Attr("",
                    { "qi-xref", "qi-" .. xref.kind.attr })) })
  end

  local previous_was_xref = false
  for _, item in ipairs(tail) do
    inlines:insert(pandoc.Str(previous_was_xref and ";" or ","))
    inlines:insert(pandoc.Space())
    inlines:insert(item.span)
    previous_was_xref = item.xref
  end
  return inlines
end

-- One list item per key, in the order given. Named separately from the list
-- itself because the top level is built one GROUP at a time — a slice of the
-- sorted keys — while every level below it is built whole.
local entry_list

local function entry_items(root, node, keys)
  local items = pandoc.List()
  for _, key in ipairs(keys) do
    local child = node.children[key]
    local blocks = pandoc.List({ pandoc.Plain(entry_inlines(root, child)) })
    if #child.sorted > 0 then
      blocks:insert(entry_list(root, child))
    end
    items:insert(blocks)
  end
  return items
end

function entry_list(root, node)
  return pandoc.BulletList(entry_items(root, node, node.sorted))
end

-- The top level: one heading, then one list, per group.
--
-- Each heading is a Div and never a Header. Quarto copies a heading's inlines
-- into the table of contents, so real headings would put the alphabet in the
-- sidebar — the defect class the mark anchors already had to be moved out of
-- headings to avoid — and a minted heading id would enter the same namespace
-- an author's own ids live in. A Div carries the class an author styles with
-- and nothing else (GP4: a hook, not a stylesheet).
local function grouped_blocks(root)
  local blocks = pandoc.Blocks({})
  local pending = {}
  local label = nil

  local function flush()
    if #pending > 0 then
      blocks:insert(pandoc.Div(pandoc.Plain(literal_inlines(label)),
                               pandoc.Attr("", { qi_core.HTML_LETTER_CLASS })))
      blocks:insert(pandoc.BulletList(entry_items(root, root, pending)))
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
  return blocks
end

-- Every id already in the document. Collected before any id is minted, so a
-- minted one can be checked against the author's rather than assumed unique.
-- Quarto adds further ids of its own after the filter runs, but it derives
-- them from these, so what an author actually wrote is what matters here.
local function taken_identifiers(doc)
  local taken = {}
  local function note(element)
    local attr = element.attr
    if attr ~= nil and attr.identifier ~= nil and attr.identifier ~= "" then
      taken[attr.identifier] = true
    end
    return nil
  end
  -- An id can also be written in raw HTML, where it is no Attr at all. Read
  -- the three spellings an id attribute has in HTML; over-collecting from
  -- text that merely looks like one costs a skipped number, nothing more.
  local function note_raw(raw)
    if raw.format:match("^html") then
      -- HTML attribute names are case-insensitive, so `ID=` claims a name
      -- exactly as `id=` does.
      for _, pattern in ipairs({ '%s[iI][dD]%s*=%s*"([^"]*)"',
                                 "%s[iI][dD]%s*=%s*'([^']*)'",
                                 "%s[iI][dD]%s*=%s*([^%s\"'<>=`]+)" }) do
        for id in raw.text:gmatch(pattern) do
          taken[id] = true
        end
      end
    end
    return nil
  end
  doc:walk({ Block = note, Inline = note,
             RawBlock = note_raw, RawInline = note_raw })
  return taken
end

-- Quarto copies a heading's inlines into the table of contents, so an anchor
-- id that stayed inside a heading would appear TWICE in the page, and a link
-- to it would resolve to the sidebar copy rather than to the text. So no
-- anchor stays inside: every heading mark's anchor duty — the author's own
-- id if the mark carried one, its pending tag if not — moves onto an empty
-- span emitted immediately after the heading, which sits in the same section
-- and renders as nothing. One relocation for every mark, rather than
-- borrowing the heading's own id: borrowing made a mark with an author id,
-- two marks in one heading, and a heading without an id each a special case,
-- and the first two failed.
local function relocate_heading_anchors(doc)
  return doc:walk({
    Blocks = function(blocks)
      local out = pandoc.Blocks({})
      for _, block in ipairs(blocks) do
        local anchors = pandoc.Inlines({})
        if block.t == "Header" then
          block = block:walk({
            traverse = "topdown",
            Note = function(note)
              -- A footnote's text renders in the footnotes section, not in
              -- the heading, so a mark inside one anchors where its text is
              -- and must not be relocated. Stop the descent.
              return note, false
            end,
            Span = function(span)
              -- A cross-reference mark contributes no locator, but an id it
              -- carries duplicates into the table of contents exactly as a
              -- locator anchor would, so its id moves out too.
              local pending = span.attributes[qi_core.HTML_PENDING_ATTR]
              local marked_id = span.classes:includes(qi_core.INDEX_CLASS)
                and span.identifier ~= ""
              if pending == nil and not marked_id then
                return nil
              end
              local anchor = pandoc.Span({})
              anchor.identifier = span.identifier
              if pending ~= nil then
                anchor.attributes[qi_core.HTML_PENDING_ATTR] = pending
              end
              anchors:insert(anchor)
              span.identifier = ""
              span.attributes[qi_core.HTML_PENDING_ATTR] = nil
              return span
            end,
          })
        end
        out:insert(block)
        if #anchors > 0 then
          out:insert(pandoc.Plain(anchors))
        end
      end
      return out
    end,
  })
end

-- Resolve every still-pending mark. A mark carrying an id of the author's
-- own keeps it as the link target — taking it over would break whatever
-- already points at it — and every other mark is given an id that nothing
-- else in the document uses, numbered in the order the marks are written.
-- Skipping a taken number leaves a gap in the sequence, which is the right
-- trade: the numbers are link targets, not a count of anything.
local function assign_anchors(doc, taken)
  local number = 0
  return doc:walk({
    Span = function(span)
      local pending = span.attributes[qi_core.HTML_PENDING_ATTR]
      if pending == nil then
        return nil
      end
      span.attributes[qi_core.HTML_PENDING_ATTR] = nil
      if span.identifier == "" then
        repeat
          number = number + 1
        until not taken[qi_core.HTML_ANCHOR_PREFIX .. number]
        span.identifier = qi_core.HTML_ANCHOR_PREFIX .. number
        taken[span.identifier] = true
      end
      local record = qi_marks.html_marks[tonumber(pending)]
      if record then
        record.anchor = span.identifier
      end
      return span
    end,
  })
end

-- The section needs no configuration (GP4) and is marked unnumbered, which is
-- how a printed index is set and which still lists it in the table of
-- contents. WHERE it goes is not decided here — place_index owns that, for
-- both back-ends at once. `marks` is this document's own marks in a single
-- document, and every chapter's marks in a book: one builder either way, so
-- the two cannot drift apart on what an index looks like.
-- The section id is minted like every other generated id, rather than fixed:
-- a document that already uses `qi-index` — on an element of its own, or
-- inside raw HTML — otherwise ended up with the name on two elements, which
-- is invalid HTML and sends a link to whichever the browser picks. Anchors and
-- entry ids have always stepped over a taken name; this closes the one
-- exception. The bare name is preferred, so the id a document without a
-- collision gets is the one it has always had.
local function mint_section_id(taken)
  if not taken[qi_core.HTML_SECTION_ID] then
    taken[qi_core.HTML_SECTION_ID] = true
    return qi_core.HTML_SECTION_ID
  end
  local n = 0
  local candidate
  repeat
    n = n + 1
    candidate = qi_core.HTML_SECTION_ID .. "-" .. n
  until not taken[candidate]
  taken[candidate] = true
  return candidate
end

local function html_index_blocks(marks, taken)
  local root = build_entry_tree(marks)
  local section_id = mint_section_id(taken)
  number_entries(root, 0, taken)
  local blocks = pandoc.Blocks({
    pandoc.Header(1, literal_inlines("Index"),
                  pandoc.Attr(section_id, { "unnumbered" })),
  })
  blocks:extend(grouped_blocks(root))
  return blocks
end

-- Exported through the bracket form, never `M.NAME = NAME`: the source
-- scans take the FIRST match for `NAME =` over the whole source set, and
-- the M16-AC3 probe relocates a definition into another file — a plain
-- `NAME =` line left behind here would then mask it (M16 review F3).
M["fold_case"] = fold_case
M["collate"] = collate
M["SYMBOLS_LABEL"] = SYMBOLS_LABEL
M["group_label"] = group_label
M["group_rank"] = group_rank
M["target_text"] = target_text
M["literal_inlines"] = literal_inlines
M["same_levels"] = same_levels
M["new_entry"] = new_entry
M["mark_target"] = mark_target
M["build_entry_tree"] = build_entry_tree
M["number_entries"] = number_entries
M["lookup_entry"] = lookup_entry
M["target_span"] = target_span
M["entry_inlines"] = entry_inlines
M["entry_list"] = entry_list
M["entry_items"] = entry_items
M["grouped_blocks"] = grouped_blocks
M["taken_identifiers"] = taken_identifiers
M["relocate_heading_anchors"] = relocate_heading_anchors
M["assign_anchors"] = assign_anchors
M["mint_section_id"] = mint_section_id
M["html_index_blocks"] = html_index_blocks

return M
