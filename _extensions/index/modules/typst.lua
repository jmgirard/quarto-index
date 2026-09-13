-- The Typst back-end: the label written at each mark, and the index built
-- from the entry tree.
--
-- A printed page number is known only once Typst has laid out the pages, and
-- this filter runs before that. So each mark carries a label, and each locator
-- is raw Typst that asks for the page of its label while the document is
-- typeset (D-060). No Typst package is imported (GP3).

local qi_core = require("./core")
local qi_marks = require("./marks")

local M = {}

-- The raw Typst written at a mark: an invisible element carrying the label.
-- Pandoc's own label for a span id attaches to the text element before it,
-- which for a mark with no visible text can sit on an earlier page. A
-- `metadata` element sits where the mark is, and it prints nothing. The
-- content block around it keeps the label attached to that element whatever
-- text follows the mark.
local function label_inline(label)
  return pandoc.RawInline("typst", "#[#metadata(none)<" .. label .. ">]")
end

-- Give every still-pending mark its label. The Span pass tagged each mark with
-- qi_core.HTML_PENDING_ATTR, and `relocate_heading_anchors` has already moved a
-- heading mark's tag after its heading, where Typst's outline does not copy
-- it: a label copied into the outline names two elements, and its first one
-- sits on the outline's page. A label is minted for every mark and never taken
-- from the author's id, because Pandoc writes that id as a label of its own.
-- A minted label skips every id in `taken`.
local function assign_labels(doc, taken)
  local number = 0
  return doc:walk({
    Span = function(span)
      local pending = span.attributes[qi_core.HTML_PENDING_ATTR]
      if pending == nil then
        return nil
      end
      span.attributes[qi_core.HTML_PENDING_ATTR] = nil
      local record = qi_marks.html_marks[tonumber(pending)]
      -- A cross-reference mark is tagged only for the HTML id contest, and it
      -- contributes no locator, so it gets no label.
      if record == nil or record.anchorless then
        return span
      end
      repeat
        number = number + 1
      until not taken[qi_core.TYPST_LABEL_PREFIX .. number]
      local label = qi_core.TYPST_LABEL_PREFIX .. number
      taken[label] = (taken[label] or 0) + 1
      record.label = label
      span.content:insert(label_inline(label))
      return span
    end,
  })
end

-- Exported through the bracket form, never `M.NAME = NAME`: the source
-- scans take the FIRST match for `NAME =` over the whole source set, and
-- the M16-AC3 probe relocates a definition into another file — a plain
-- `NAME =` line left behind here would then mask it (M16 review F3).
M["label_inline"] = label_inline
M["assign_labels"] = assign_labels

return M
