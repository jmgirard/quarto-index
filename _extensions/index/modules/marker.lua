-- Recognizing the placement marker, reporting its misuse, and putting the
-- index where it stood.

local qi_core = require("./core")
local qi_indexes = require("./indexes")

local M = {}

-- ---------------------------------------------------------------------------
-- The placement marker.
--
-- Everything below is format-neutral and runs before any back-end branch: a
-- misused marker is diagnosed wherever the document is rendered, and a marker
-- leaves no residue in any format — the ones with no index back-end included
-- (IP2).
-- ---------------------------------------------------------------------------

local function is_marker(block)
  return block.t == "Div" and block.classes:includes(qi_core.MARKER_CLASS)
end

-- The sequence a reported block position is counted over, written once here
-- and spliced into both reports below (D-014). Quarto expands includes and
-- executable cells before any filter runs, so the block list this filter is
-- handed can hold blocks the author never wrote, and a position counted over
-- it is not the position the author would count in their own source file --
-- `examples/marker-position.qmd` is the fixture where the two differ. The
-- author's own position is not recoverable here: by the time this code runs
-- the expansion has already happened and nothing records where a block came
-- from, so the report names what its number counts rather than offering a
-- second number it cannot compute.
local POSITION_BASIS = "counted over the document as this filter received "
      .. "it, after Quarto expanded any includes and executable cells, so "
      .. "they can differ from the positions in your source file"

-- Where a reported block position was counted, when that is a book chapter
-- rather than the whole document. Attached to the position itself rather than
-- offered as a sentence of its own, because scoping the number is the whole
-- point: in a book each chapter is its own Pandoc process, so block 5 means
-- the fifth block of THAT chapter and of nothing larger. `chapter` is nil
-- wherever no chapter is known -- every non-book render, and every format
-- but HTML -- and the reports then read exactly as they did before.
local function in_chapter(chapter)
  if chapter == nil then
    return ""
  end
  return " of " .. chapter
end

-- The marker class means something on exactly one shape: an empty top-level
-- div. Written anywhere else it is inert, and until now it was inert in
-- silence — a heading or a span carrying it placed nothing and said nothing,
-- which reads to an author exactly like a marker that failed. Every other
-- shape is therefore reported. Format-neutral, like every other report about
-- what the author wrote, so it fires wherever the document is rendered.
--
-- Nothing is edited: the element belongs to the author, and this extension
-- removes markers, not the elements people mistake for them. The class
-- accordingly survives into output, which is cosmetic and said out loud in
-- the README rather than fixed by editing someone else's span.
local MARKER_SITE_NAMES = {
  Header = "heading",
  Span = "inline span",
  CodeBlock = "code block",
  Code = "inline code",
  Table = "table",
  Figure = "figure",
  Link = "link",
  Image = "image",
}

local function report_marker_sites(doc)
  local function note(element)
    -- A Div is the one shape that CAN place an index; whether this particular
    -- one does is resolve_markers' business, not this walk's.
    if element.t == "Div" then
      return nil
    end
    local attr = element.attr
    if attr == nil or not attr.classes:includes(qi_core.MARKER_CLASS) then
      return nil
    end
    local name = MARKER_SITE_NAMES[element.t] or element.t
    -- Every name this table can produce is an ordinary English noun phrase, so
    -- the article follows from its first letter; a fallback name is a Pandoc
    -- type name, where the same test still reads correctly ("an Emph").
    local article = name:match("^[aeiouAEIOU]") and "an" or "a"
    qi_core.warn(("the index placement marker class is written on %s %s; only an empty "
          .. "top-level div places an index, so nothing is placed here and the "
          .. "%s is left as written"):format(article, name, name))
    return nil
  end
  -- `doc.blocks`, never `doc`: walking a Pandoc value traverses `meta` too, and
  -- a marker class written in the title is not a misplaced placement site — it
  -- is text the marker machinery never reaches at all.
  doc.blocks:walk({ Block = note, Inline = note })
end

-- A marker's own content is never dropped. The marker is documented as empty,
-- but deleting what an author wrote inside one would be IP2 corruption, so the
-- content is spliced in where the marker stood and the author is told.
local function marker_content(block)
  if #block.content > 0 then
    qi_core.warn("index placement marker is not empty; the marker should be an empty "
         .. "div, and its content is kept where the marker was written")
  end
  -- The marker is a position, not an element: it is removed, so anything
  -- written ON it goes with it. An id would be the worse loss — a link to it
  -- would silently resolve nowhere — so neither is dropped in silence.
  local extra = {}
  for _, class in ipairs(block.classes) do
    if class ~= qi_core.MARKER_CLASS then
      extra[#extra + 1] = class
    end
  end
  if block.identifier ~= "" or #extra > 0 then
    qi_core.warn(("index placement marker carries an id or extra class (%s); a marker "
          .. "is a position rather than an element, so it is removed and these "
          .. "are not carried onto the index"):format(
         block.identifier ~= "" and ("#" .. block.identifier)
           or ("." .. table.concat(extra, " ."))))
  end
  return block.content
end

-- Removing a nested marker takes nothing the author wrote with it — but where
-- the marker was the only thing in the block list it stood in, what is left is
-- a place the author put something into and will find nothing in. That is
-- reported, and deliberately without naming what held it. Every name available
-- here is invented or false: Quarto wraps a callout, a tabset and a captioned
-- figure in scaffold divs no author wrote, and a callout holding only a marker
-- still renders its title bar, so calling it empty is untrue however the div
-- is named. The marker's own top-level position is the part an author can act
-- on, so that is what the report carries.
--
-- Does this block list leave NOTHING once every marker in it is stripped? The
-- question is recursive because the answer is: a marker contributes whatever
-- its own content contributes, since marker_content splices that content in
-- where the marker stood. So a list empties when every element is a marker
-- whose content is empty or itself empties — a marker wrapping only empty
-- markers contributes nothing however deep it goes, and one paragraph anywhere
-- inside means the container keeps something.
local function empties(blocks)
  if blocks == nil or #blocks == 0 then
    return false
  end
  for _, inner in ipairs(blocks) do
    if not is_marker(inner) then
      return false
    end
    if #inner.content > 0 and not empties(inner.content) then
      return false
    end
  end
  return true
end

-- How many places one top-level block loses. Counted rather than located: a
-- walk hands over a block list without saying which element owns it, and the
-- owner is the whole question, because a list a MARKER owns is not a place
-- anything was emptied out of — the marker is removed whole at every depth and
-- reaches no output, so there is nothing an author could find left empty
-- inside one. Every emptying list, minus every emptying list a marker owns, is
-- therefore exactly the places the author wrote into and will find empty. A
-- count is enough because every report under one top-level block carries that
-- block's position and nothing else.
--
-- Counting this way is what keeps the rule free of per-container code, and so
-- free of the gap that came with it: a table cell, a footnote body and a
-- definition are block lists like any other here, where a check written kind
-- by kind reached none of them.
local function emptied_places(block)
  local lists, owned = 0, 0
  block:walk({
    Blocks = function(blocks)
      if empties(blocks) then
        lists = lists + 1
      end
      return nil
    end,
  })
  local function count_owner(element)
    if is_marker(element) and empties(element.content) then
      owned = owned + 1
    end
  end
  -- `walk` visits an element's contents and never the element itself, so the
  -- top-level block is counted here rather than by the walk below.
  --
  -- No Note handler, deliberately. A footnote is an Inline whose content is a
  -- block list, and M08 needed one to reach inside; on Pandoc 3.10.2 the Block
  -- filter reaches a footnote's blocks on its own, so adding one counts every
  -- marker in a footnote twice — which subtracts one report too many from a
  -- marker nested inside a marker inside a footnote. Probed, not assumed.
  count_owner(block)
  block:walk({
    Block = function(element)
      count_owner(element)
      return nil
    end,
  })
  return lists - owned
end

-- Strip every marker below the top level of one top-level block. A
-- `\printindex` inside a group or environment is an IP2-class render risk, so
-- a nested marker places nothing; the index keeps its automatic position.
--
-- The emptied places are reported BEFORE anything is stripped, from the shape
-- as the author wrote it: the strip runs bottom-up, so by the time an outer
-- list is visited its markers have already lost their content and every list
-- would look empty. `chapter` is the book chapter this document is, or nil.
local function strip_nested_markers(block, position, chapter)
  for _ = 1, emptied_places(block) do
    -- One literal for the report's own sentence, not concatenated. Written
    -- this way when the distinctness scan read only a call's FIRST literal
    -- (M10); the scan joins them all now, so the form is a readability choice
    -- here rather than a requirement. The trailing clause is the shared
    -- POSITION_BASIS above, so both reports say the same thing about what
    -- their numbers count.
    qi_core.warn(("index placement marker in top-level block %d%s was the only thing written where it stood; the marker is removed, so nothing you wrote remains there. Block positions are %s"):format(position, in_chapter(chapter), POSITION_BASIS))
  end
  return block:walk({
    Blocks = function(blocks)
      local out = pandoc.Blocks({})
      for _, inner in ipairs(blocks) do
        if is_marker(inner) then
          qi_core.warn("index placement marker below the top level of the document "
               .. "places nothing; write it as a top-level block")
          out:extend(marker_content(inner))
        else
          out:insert(inner)
        end
      end
      return out
    end,
  })
end

-- Warn about and remove every marker that cannot be a placement site — each
-- nested one, and each top-level one after the FIRST OF ITS INDEX — and report
-- which indexes a site remains for. A reported position is counted over the
-- blocks this filter is handed, after Quarto's own processing, before anything
-- is removed here. It is not the author's own source position: Quarto expands
-- includes and executable cells first, so the two diverge whenever the document
-- holds any (`examples/marker-position.qmd`). The reports say so themselves
-- through POSITION_BASIS above. In a book each chapter is a Pandoc process of
-- its own, so the position is over that chapter alone; `chapter` names it where
-- the caller knows which one it is, and the reports scope their number to it.
--
-- The first-marker rule is per index (M38): two indexes are two sections, so
-- each has its own site and the second marker of ONE index is the one that is
-- ignored. A marker naming an index the running back-end folds away has already
-- been told so by `marker_index`, and becomes a marker for the index that
-- back-end does build — so it is not also reported as a duplicate, which would
-- name a second marker of an index its author never wrote one for.
--
-- Returns whether any placement site survived, exactly as it always has: WHICH
-- index each surviving marker places is read back off the marker itself by
-- `place_index`, so there is no second thing for this to hand over.
-- The index each top-level marker names, in document order, as its AUTHOR wrote
-- it -- before any fold. Read in a pass of its own because the question the
-- fold slot below asks is about the whole document: which marker places the one
-- index cannot be answered while walking one marker at a time. Silent: every
-- report about these values is drawn in the walk that follows, once per marker.
--
-- Reading `doc.blocks` before the walk strips anything is safe because the walk
-- changes no top-level block's kind: `strip_nested_markers` removes markers
-- INSIDE a block, so a marker stays a marker and a non-marker never becomes
-- one, and the two passes see the same top-level markers in the same order.
local function marker_names(doc)
  local names = {}
  for _, block in ipairs(doc.blocks) do
    if is_marker(block) then
      names[#names + 1] =
        qi_indexes.authored_index(block.attributes[qi_indexes.INDEX_ATTR])
    end
  end
  return names
end

-- Which marker places the one index a folded back-end builds, as an ordinal
-- over `marker_names` above. The author's own marker for the index that IS
-- built is where they asked for it, so it holds the slot wherever it stands in
-- the document; only where no marker names that index does the first marker of
-- any name hold it, since the alternative is an index appended at the end of a
-- document whose author did write a place for one.
--
-- Without this, a marker naming a second index took the slot merely by standing
-- first, and the author's own marker for the built index was then reported as
-- that marker's duplicate -- a second marker for an index they had written
-- exactly one marker for (M38 R2).
local function fold_slot(names)
  for i, name in ipairs(names) do
    if name == qi_indexes.default() then
      return i
    end
  end
  if #names > 0 then
    return 1
  end
  return nil
end

local function resolve_markers(doc, chapter)
  local names = marker_names(doc)
  local folds = qi_indexes.folds()
  local slot = folds and fold_slot(names) or nil
  local out = pandoc.Blocks({})
  -- Keyed by the index the AUTHOR named, not by the index the back-end builds:
  -- under fold every marker would otherwise key to the one built index, and a
  -- second marker naming a second index would read as a duplicate of the first
  -- while two markers naming the SAME second index would read as neither.
  local placed = {}
  local seen = 0
  local any = false
  for position, block in ipairs(doc.blocks) do
    block = strip_nested_markers(block, position, chapter)
    if is_marker(block) then
      seen = seen + 1
      local name = names[seen]
      -- Under fold there is one index and one slot for it, settled above over
      -- the whole document; otherwise each index has its own site and the
      -- first marker naming one holds it.
      local takes
      if folds then
        takes = (seen == slot)
      else
        takes = (placed[name] == nil)
      end
      -- The reports for the value this marker carries: one for a value naming
      -- no declared index, and one for a value the running back-end folds
      -- away. Drawn for every top-level marker, not only the surviving one: a
      -- marker naming an index this document never declared is the author's
      -- mistake wherever it sits. The fold report is held back for a marker
      -- whose duplicate report is drawn below, which says everything it would
      -- and also says which marker took the place.
      local fold_shape = qi_indexes.FOLD_ELSEWHERE
      if takes then
        fold_shape = qi_indexes.FOLD_PLACES
      elseif placed[name] ~= nil then
        fold_shape = qi_indexes.FOLD_QUIET
      end
      qi_indexes.marker_index(block.attributes[qi_indexes.INDEX_ATTR], true,
                              fold_shape)
      if takes then
        placed[name] = true
        any = true
        out:insert(block)
      elseif placed[name] == nil then
        -- Folded, and the slot went to the marker naming the index this
        -- back-end builds. This marker is the first naming ITS index, so it is
        -- no duplicate; its own fold report, one line above, already said it
        -- places nothing. Recorded all the same, so a later marker naming this
        -- same index is reported as the second one it is.
        placed[name] = true
        out:extend(marker_content(block))
      elseif qi_indexes.is_declared() then
        -- Two numbers, so each is named where it is printed (D-014), and the
        -- index the second marker repeats, which is the whole question in a
        -- document with more than one.
        qi_core.warn(('index placement marker %d in document order (top-level block %d%s) is a second marker for the index named "%s"; that index is placed at the first marker naming it, so this one is ignored. Block positions are %s'):format(seen, position, in_chapter(chapter), name, POSITION_BASIS))
        out:extend(marker_content(block))
      else
        -- Two numbers, so each is named where it is printed (D-014): the first
        -- counts markers down the document and says so, the second counts
        -- top-level blocks and takes the shared clause, with the chapter
        -- inside the parenthesis holding that number, as the emptied-place
        -- report attaches it to its own. That clause is about
        -- the block position alone — it ends in what a POSITION can differ
        -- from, and a marker ordinal is no position, which is what saying
        -- "both numbers" got wrong (KI80).
        qi_core.warn(("index placement marker %d in document order (top-level block %d%s) "
              .. "is ignored; the index is placed at the first marker. Block "
              .. "positions are %s"):format(seen, position, in_chapter(chapter), POSITION_BASIS))
        out:extend(marker_content(block))
      end
    else
      out:insert(block)
    end
  end
  doc.blocks = out
  return any
end

-- Put each index where the author asked for it, and any index no marker names
-- at the end of the document, in declared order. Both back-ends call this, so
-- the two cannot drift apart on where an index goes. `by_index` maps an index
-- name to the blocks that index emits; it is nil when the back-end has nothing
-- to emit at all, which still removes every marker.
--
-- The per-index guard is what keeps one index from being emitted twice; every
-- marker is stripped whether or not it places anything, since a marker that
-- survived into output would be exactly the residue IP2 forbids.
local function place_index(doc, by_index)
  local out = pandoc.Blocks({})
  local placed = {}
  for _, block in ipairs(doc.blocks) do
    if is_marker(block) then
      out:extend(marker_content(block))
      -- Silently: `resolve_markers` has already reported this marker's value,
      -- and it left at most one marker per index behind.
      local name =
        qi_indexes.marker_index(block.attributes[qi_indexes.INDEX_ATTR], false)
      if not placed[name] then
        placed[name] = true
        local blocks = by_index ~= nil and by_index[name] or nil
        if blocks then
          out:extend(blocks)
        end
      end
    else
      out:insert(block)
    end
  end
  if by_index ~= nil then
    for _, name in ipairs(qi_indexes.names()) do
      if not placed[name] and by_index[name] then
        out:extend(by_index[name])
      end
    end
  end
  doc.blocks = out
  return doc
end

-- Exported through the bracket form, never `M.NAME = NAME`: the source
-- scans take the FIRST match for `NAME =` over the whole source set, and
-- the M16-AC3 probe relocates a definition into another file — a plain
-- `NAME =` line left behind here would then mask it (M16 review F3).
M["POSITION_BASIS"] = POSITION_BASIS
M["is_marker"] = is_marker
M["MARKER_SITE_NAMES"] = MARKER_SITE_NAMES
M["report_marker_sites"] = report_marker_sites
M["marker_content"] = marker_content
M["empties"] = empties
M["emptied_places"] = emptied_places
M["strip_nested_markers"] = strip_nested_markers
M["resolve_markers"] = resolve_markers
M["place_index"] = place_index

return M
