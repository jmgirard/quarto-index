-- Recognizing the placement marker, reporting its misuse, and putting the
-- index where it stood.

local qi_core = require("./core")

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
-- nested one, and each top-level one after the first — and report whether a
-- site remains. A reported position is counted over the blocks this filter is
-- handed, after Quarto's own processing, before anything is removed here. It
-- is not the author's own source position: Quarto expands includes and
-- executable cells first, so the two diverge whenever the document holds any
-- (`examples/marker-position.qmd`). The reports say so themselves through
-- POSITION_BASIS above. In a book each chapter is a Pandoc process of its own,
-- so the position is over that chapter alone; `chapter` names it where the
-- caller knows which one it is, and the reports scope their number to it.
local function resolve_markers(doc, chapter)
  local out = pandoc.Blocks({})
  local seen = 0
  for position, block in ipairs(doc.blocks) do
    block = strip_nested_markers(block, position, chapter)
    if is_marker(block) then
      seen = seen + 1
      if seen == 1 then
        out:insert(block)
      else
        -- Two numbers, so each is named where it is printed (D-014): the first
        -- counts markers down the document and says so, the second counts
        -- top-level blocks and takes the shared clause. That clause is about
        -- the block position alone — it ends in what a POSITION can differ
        -- from, and a marker ordinal is no position, which is what saying
        -- "both numbers" got wrong (KI80).
        qi_core.warn(("index placement marker %d in document order (top-level block %d)%s "
              .. "is ignored; the index is placed at the first marker. Block "
              .. "positions are %s"):format(seen, position, in_chapter(chapter), POSITION_BASIS))
        out:extend(marker_content(block))
      end
    else
      out:insert(block)
    end
  end
  doc.blocks = out
  return seen > 0
end

-- Put the index where the author asked for it, or at the end of the document
-- when no marker survived resolution. Both back-ends call this, so the two
-- cannot drift apart on where an index goes. `blocks` is nil when the back-end
-- has nothing to emit, which still removes the marker.
local function place_index(doc, blocks)
  local out = pandoc.Blocks({})
  local placed = false
  for _, block in ipairs(doc.blocks) do
    if is_marker(block) then
      -- Every marker is stripped here, not only the first: a marker that
      -- survived into output would be exactly the residue IP2 forbids, and a
      -- fail-open branch would emit one verbatim the day resolve_markers
      -- stops guaranteeing there is at most one.
      out:extend(marker_content(block))
      if not placed then
        placed = true
        if blocks then
          out:extend(blocks)
        end
      end
    else
      out:insert(block)
    end
  end
  if blocks and not placed then
    out:extend(blocks)
  end
  doc.blocks = out
  return doc
end

-- Exported through the bracket form, never `M.NAME = NAME`: the source
-- scans take the FIRST match for `NAME =` over the whole source set, and
-- the M16-AC3 probe relocates a definition into another file — a plain
-- `NAME =` line left behind here would then mask it (M16 review F3).
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
