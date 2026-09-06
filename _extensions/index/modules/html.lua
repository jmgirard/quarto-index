-- The HTML back-end: the entry tree, its ordering and grouping, the anchors
-- that link an entry back to its mark, and the index section built out of
-- them.

local qi_core = require("./core")
local qi_indexes = require("./indexes")
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
-- A mark recovered from another chapter's source carries an anchor only where
-- its author wrote an id on it: that id is on the rendered page, because
-- `assign_anchors` moves a mark off its author's id only where another element
-- of that page carries the same name — and that element still carries it, so
-- the name is on the page either way. Which element the recovered locator then
-- lands on is what the record route settles and this one cannot see (D-055's
-- unfenced case). Nothing is MINTED for such a mark — a
-- minted id is settled against the ids of the whole rendered page, which the
-- source cannot see, and a fragment guessed here would link to nowhere in
-- silence — so a recovered mark whose author wrote no id gets the chapter's
-- page and nothing after it. A front-matter mark in an HTML book chapter gets
-- the page alone on both routes, whatever id it carries (D-048).
local function mark_target(mark)
  if mark.anchor == nil then
    return mark.href or ""
  end
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
    -- `page_locator` is the book's flag for a mark recovered from a chapter's
    -- source, and for a front-matter mark of an HTML book chapter: it
    -- contributes a locator naming the chapter's page whether or not it
    -- carries an anchor, where a cross-reference mark has no anchor and must
    -- not contribute one at all.
    if (mark.anchor or mark.page_locator) and mark.paired ~= "close" then
      -- Two marks that land on the same destination in the same role are one
      -- locator, not two: a reader following either arrives at the same place,
      -- and printing it twice reports how the author spread the marks rather
      -- than anything a reader wants — the rule the cross-references below
      -- already keep. With a MINTED anchor this can never fire, since each
      -- mark mints an id of its own; it fires on a chapter recovered from its
      -- source, whose marks carry that chapter's page and, where their author
      -- wrote no id, nothing after it — and where a term marked twice that way
      -- would otherwise print the same link twice over. Two recovered marks of
      -- one term whose authors gave them different ids are two destinations
      -- and stay two locators, exactly as they are on the record route.
      local target = mark_target(mark)
      local already = false
      for _, existing in ipairs(node.locators) do
        if existing.target == target and existing.role == mark.role then
          already = true
        end
      end
      if not already then
        -- A table rather than the bare target string: a locator now has a role
        -- as well as a destination, and the two travel together so a reordering
        -- cannot separate them (M20).
        node.locators[#node.locators + 1] = { target = target, role = mark.role }
      end
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
    taken[child.id] = (taken[child.id] or 0) + 1
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

-- The punctuation an entry prints between its own parts, and the ASCII mark
-- each falls back to. Two keys and not one per printed position: no
-- convention found distinguishes the mark before a term's locators from the
-- one between two locators, and a key per position would cost three more rows
-- in every documentation table for a distinction nobody writes (M58).
--
-- Only the GLYPH is the author's. The `pandoc.Space()` after it stays this
-- module's, so a value written without one cannot silently glue a locator to
-- the term in front of it in a render that stays green.
local SEPARATOR_KEY = "separator"
local SEPARATOR = ","
local XREF_SEPARATOR_KEY = "xref-separator"
local XREF_SEPARATOR = ";"

-- One entry's line: the term, then its numbered locator links, then its
-- cross-references. The separators follow print convention — locators and the
-- first cross-reference are set off from the term with a comma, and two
-- cross-references are separated with a semicolon, exactly as the LaTeX
-- back-end's dual-target command prints them. Both marks are what an author
-- overrides under `separator:` and `xref-separator:`, resolved on the same
-- per-index-then-document ladder the printed words use; the LaTeX back-end
-- reads neither, because makeindex owns its own delimiter (M58).
local function entry_inlines(root, node, name)
  local inlines = pandoc.List()
  inlines:insert(pandoc.Span(literal_inlines(node.key),
                             pandoc.Attr(node.id, { "qi-term" })))

  -- Resolved once for the whole entry rather than per position: the ladder
  -- answers a question about this index, not about where in a line the mark
  -- sits, and re-asking it per locator would re-answer it for every entry.
  local separator = qi_indexes.label(name, SEPARATOR_KEY, SEPARATOR)
  local xref_separator =
    qi_indexes.label(name, XREF_SEPARATOR_KEY, XREF_SEPARATOR)

  local tail = pandoc.List()
  if #node.locators > 0 then
    local locators = pandoc.List()
    for i, locator in ipairs(node.locators) do
      if i > 1 then
        locators:insert(pandoc.Str(separator))
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
    body:insert(pandoc.Emph(literal_inlines(
      qi_indexes.label(name, xref.kind.label_key, xref.kind.label))))
    body:insert(pandoc.Space())
    body:insert(target_span(root, xref))
    tail:insert({ xref = true,
                  span = pandoc.Span(body, pandoc.Attr("",
                    { "qi-xref", "qi-" .. xref.kind.attr })) })
  end

  local previous_was_xref = false
  for _, item in ipairs(tail) do
    inlines:insert(pandoc.Str(previous_was_xref and xref_separator
                                                 or separator))
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

local function entry_items(root, node, keys, name)
  local items = pandoc.List()
  for _, key in ipairs(keys) do
    local child = node.children[key]
    local blocks = pandoc.List({ pandoc.Plain(entry_inlines(root, child, name)) })
    if #child.sorted > 0 then
      blocks:insert(entry_list(root, child, name))
    end
    items:insert(blocks)
  end
  return items
end

function entry_list(root, node, name)
  return pandoc.BulletList(entry_items(root, node, node.sorted, name))
end

-- The top level: one heading, then one list, per group.
--
-- Each heading is a Div and never a Header. Quarto copies a heading's inlines
-- into the table of contents, so real headings would put the alphabet in the
-- sidebar — the defect class the mark anchors already had to be moved out of
-- headings to avoid — and a minted heading id would enter the same namespace
-- an author's own ids live in. A Div carries the class an author styles with
-- and nothing else (GP4: a hook, not a stylesheet).
local function grouped_blocks(root, name)
  local blocks = pandoc.Blocks({})
  local pending = {}
  local label = nil
  -- What this index's groups actually head, for the report at the foot of this
  -- function. Collected as each heading is written rather than derived from the
  -- entries a second time: the question is whether two groups a READER sees
  -- carry one heading, so the thing compared is the text that was printed.
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
      blocks:insert(pandoc.Div(pandoc.Plain(literal_inlines(heading)),
                               pandoc.Attr("", { qi_core.HTML_LETTER_CLASS })))
      blocks:insert(pandoc.BulletList(entry_items(root, root, pending, name)))
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
  -- on a PDF render that has nothing to see.
  --
  -- Compared character for character rather than case-insensitively: a letter
  -- group always heads a capital, so a lowercase word prints a heading a reader
  -- can tell from it.
  if symbols_heading ~= nil and letters[symbols_heading] then
    qi_core.warn(('%s: the word "%s" heads the entries filing under no letter in %s and is also the heading of one of its letter groups, so a reader sees two groups under one heading; a word that is not a letter this index files a term under heads one group'):format(qi_indexes.LABELS_KEY, symbols_heading, qi_indexes.scope_phrase(name, "this document")))
  end
  return blocks
end

-- Every id already in the document, and HOW MANY elements carry each.
-- Collected before any id is minted, so a minted one can be checked against
-- the author's rather than assumed unique. Quarto adds further ids of its own
-- after the filter runs, but it derives them from these, so what an author
-- actually wrote is what matters here.
--
-- Counted rather than merely noted because a name on two elements is what
-- `assign_anchors` has to see: a mark's own id is in this census like any
-- other, so "someone else carries this too" is a count above one and cannot
-- be read off the presence of the name. Every reader that only asks whether a
-- name is free still reads it as one, a count never being zero.
local function taken_identifiers(doc)
  local taken = {}
  local function claim(id)
    taken[id] = (taken[id] or 0) + 1
  end
  local function note(element)
    local attr = element.attr
    if attr ~= nil and attr.identifier ~= nil and attr.identifier ~= "" then
      claim(attr.identifier)
    end
    return nil
  end
  -- An id can also be written in raw HTML, where it is no Attr at all. Read
  -- the three spellings an id attribute has in HTML; over-collecting from text
  -- that merely looks like one costs a skipped number, and now also a mark
  -- refused an id nothing really contests — both of which leave the author's
  -- own id on the author's own element, which is the side to err on.
  local function note_raw(raw)
    if raw.format:match("^html") then
      -- HTML attribute names are case-insensitive, so `ID=` claims a name
      -- exactly as `id=` does.
      for _, pattern in ipairs({ '%s[iI][dD]%s*=%s*"([^"]*)"',
                                 "%s[iI][dD]%s*=%s*'([^']*)'",
                                 "%s[iI][dD]%s*=%s*([^%s\"'<>=`]+)" }) do
        for id in raw.text:gmatch(pattern) do
          claim(id)
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

-- Which marks may keep the id their author wrote. One id names one element:
-- a name on two of them is invalid HTML and sends a link to whichever the
-- browser picks, so where a mark's id is also carried elsewhere on the page
-- something has to give. It is the mark. The other carrier is an element the
-- author wrote and this extension does not own, and only a mark has a minted
-- id to fall back on; between two MARKS there is no such asymmetry, so the
-- first in document order keeps the name and the rest yield.
--
-- Only a locator-contributing mark is here at all, `pending` being the tag the
-- Span pass writes on those alone. A cross-reference mark's id is the author's
-- and nothing generated links to it, so refusing it would break the author's
-- own link and repair no locator.
local function keepable_author_ids(doc, taken)
  local marks, first = {}, {}
  doc:walk({
    Span = function(span)
      local pending = span.attributes[qi_core.HTML_PENDING_ATTR]
      if pending == nil or span.identifier == "" then
        return nil
      end
      marks[span.identifier] = (marks[span.identifier] or 0) + 1
      if first[span.identifier] == nil then
        first[span.identifier] = pending
      end
      return nil
    end,
  })
  local keeper = {}
  for id, count in pairs(marks) do
    -- Every carrier of this name is one of these marks, so the first of them
    -- keeps it and the page is left with the name on exactly one element.
    if (taken[id] or 0) == count then
      keeper[id] = first[id]
    end
  end
  return keeper
end

-- Resolve every still-pending mark. A mark carrying an id of the author's own
-- keeps it as the link target — taking it over would break whatever already
-- points at it — unless another element of the page carries that name too, in
-- which case the mark yields it (see above) and is reported. Every other mark
-- is given an id that nothing else in the document uses, numbered in the order
-- the marks are written. Skipping a taken number leaves a gap in the sequence,
-- which is the right trade: the numbers are link targets, not a count of
-- anything.
local function assign_anchors(doc, taken)
  local number = 0
  local keeper = keepable_author_ids(doc, taken)
  return doc:walk({
    Span = function(span)
      local pending = span.attributes[qi_core.HTML_PENDING_ATTR]
      if pending == nil then
        return nil
      end
      span.attributes[qi_core.HTML_PENDING_ATTR] = nil
      local record = qi_marks.html_marks[tonumber(pending)]
      local refused = nil
      if span.identifier ~= "" and keeper[span.identifier] ~= pending then
        refused = span.identifier
        span.identifier = ""
      end
      if span.identifier == "" then
        repeat
          number = number + 1
        until not taken[qi_core.HTML_ANCHOR_PREFIX .. number]
        span.identifier = qi_core.HTML_ANCHOR_PREFIX .. number
        taken[span.identifier] = (taken[span.identifier] or 0) + 1
      end
      -- Reported here rather than where the census is taken: only this site
      -- knows what the mark was anchored on instead, and a refusal an author
      -- cannot see is the id silently moving out from under their own link.
      -- The refused name is NOT dropped from the census — the element that
      -- kept it still carries it, so a later minted id still steps over it.
      if refused ~= nil then
        qi_core.warn(('index mark %s carries the id "%s", which another element of this page carries too; one id names one element, so the mark is anchored on "%s" instead and its index locator links there — write an id nothing else on the page uses to have the locator land on the mark'):format(
          record and record.context or "with no source entry",
          refused, span.identifier))
      end
      if record then
        record.anchor = span.identifier
      end
      return span
    end,
  })
end

-- One section per index that has marks, in declared order. A section needs no
-- configuration (GP4) and is marked unnumbered, which is how a printed index
-- is set and which still lists it in the table of contents. WHERE each goes is
-- not decided here — place_index owns that, for both back-ends at once, and it
-- is handed the map this returns. `marks` is this document's own marks in a
-- single document, and every chapter's marks in a book: one builder either
-- way, so the two cannot drift apart on what an index looks like.
--
-- A section id is minted like every other generated id, rather than fixed: a
-- document that already uses the name — on an element of its own, or inside
-- raw HTML — otherwise ended up with it on two elements, which is invalid HTML
-- and sends a link to whichever the browser picks. Anchors and entry ids have
-- always stepped over a taken name; this closes the one exception. The bare
-- name is preferred, so the id a document without a collision gets is the one
-- it has always had.
local function mint_section_id(taken, wanted)
  wanted = wanted or qi_core.HTML_SECTION_ID
  if not taken[wanted] then
    taken[wanted] = (taken[wanted] or 0) + 1
    return wanted
  end
  local n = 0
  local candidate
  repeat
    n = n + 1
    candidate = wanted .. "-" .. n
  until not taken[candidate]
  taken[candidate] = (taken[candidate] or 0) + 1
  return candidate
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

-- Returns a map from index name to that index's blocks, holding an entry only
-- for an index some mark files in: an index with a marker and no marks has no
-- section, rather than a heading over an empty list.
--
-- The entry-id counter runs across every index rather than restarting per
-- section, and every id is checked against the one `taken` set, so two sections
-- of one page cannot mint the same entry id — which would send a
-- cross-reference link to whichever element the browser picked.
local function html_index_blocks(marks, taken)
  local grouped = marks_by_index(marks)
  local by_index = {}
  local counter = 0
  for _, name in ipairs(qi_indexes.names()) do
    local list = grouped[name]
    if list ~= nil and #list > 0 then
      local root = build_entry_tree(list)
      local section_id = mint_section_id(taken, qi_indexes.section_id(name))
      counter = number_entries(root, counter, taken)
      local blocks = pandoc.Blocks({
        pandoc.Header(1, literal_inlines(qi_indexes.title(name)),
                      pandoc.Attr(section_id, { "unnumbered" })),
      })
      blocks:extend(grouped_blocks(root, name))
      by_index[name] = blocks
    end
  end
  return by_index
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
M["marks_by_index"] = marks_by_index
M["mint_section_id"] = mint_section_id
M["html_index_blocks"] = html_index_blocks

return M
