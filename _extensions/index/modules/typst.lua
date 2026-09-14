-- The Typst back-end: the label written at each mark, and the index built
-- from the entry tree.
--
-- A printed page number is known only once Typst has laid out the pages, and
-- this filter runs before that. So each mark carries a label, and each locator
-- is raw Typst that asks for the page of its label while the document is
-- typeset (D-060). No Typst package is imported (GP3).

local qi_core = require("./core")
local qi_entries = require("./entries")
local qi_indexes = require("./indexes")
local qi_marks = require("./marks")

local M = {}

-- The Typst functions every index block defines before its entries, so the
-- index needs nothing from the document's template or from a package.
--
-- `qi-index-page` prints a location's page number as the page's footer shows
-- it, and the physical page where the page has no numbering. Typst's footer
-- fills a pattern that names two or more counting symbols with the page
-- counter's value and its final value, and any other pattern with the value
-- alone (M099). `qi-index-counters` counts those symbols: a character `c` is
-- one when the pattern `c1` filled with 2 does not print `c2`.
-- A numbering function gets the value alone.
--
-- `qi-index-entry` prints one entry line. `items` holds one
-- `(opening label, closing label or none, principal)` triple per locator the
-- tree recorded. Each label is looked up while the document is typeset, and
-- a label no element carries adds no locator rather than failing the render
-- (IP2). The locators are ordered by physical page. A range whose two ends
-- print the same text prints that text alone. Locators that print the same
-- text are one locator, at the place of the first, bold where any is
-- principal, and linked to the first (M099). A page that a range of the same
-- entry spans, its two end pages included, prints no locator of its own, bold
-- or not, as makeindex drops such a page in the PDF back-end (M098 review).
-- The pages a range spans are physical pages. makeindex also folds a page just after a range into
-- the range, which this does not. Three
-- marks on consecutive pages print three locators: only an author's range
-- prints as a range (the M098 question gate). The separators are the ones
-- the LaTeX back-end's makeindex prints, a comma before each locator and
-- before the first cross-reference, and a semicolon between two
-- cross-references.
local TYPST_HELPERS = [[
#let qi-index-counters(pattern) = pattern.clusters().filter(c => numbering(c + "1", 2) != c + "2").len()
#let qi-index-page(loc) = {
  let pattern = loc.page-numbering()
  if pattern == none {
    str(loc.page())
  } else if type(pattern) == str and qi-index-counters(pattern) >= 2 {
    numbering(pattern, ..counter(page).at(loc), ..counter(page).final())
  } else {
    numbering(pattern, ..counter(page).at(loc))
  }
}
#let qi-index-entry(depth, term, items, xrefs) = context {
  let found = ()
  for item in items {
    let opened = query(item.at(0))
    if opened.len() > 0 {
      let start = opened.first().location()
      let stop = start
      if item.at(1) != none {
        let closed = query(item.at(1))
        if closed.len() > 0 { stop = closed.first().location() }
      }
      let first = qi-index-page(start)
      let last = qi-index-page(stop)
      let shown = if first == last { first } else { first + "–" + last }
      found.push((start: start, stop: stop, shown: shown, bold: item.at(2), spans: start.page() != stop.page()))
    }
  }
  found = found.sorted(key: f => f.start.page() * 1000000 + f.stop.page())
  let merged = ()
  for f in found {
    let at = merged.position(m => m.shown == f.shown)
    if at == none {
      merged.push(f)
    } else {
      let kept = merged.at(at)
      kept.bold = kept.bold or f.bold
      kept.spans = kept.spans or f.spans
      merged.at(at) = kept
    }
  }
  let ranges = found.filter(f => f.spans)
  merged = merged.filter(f => f.spans or ranges.all(r => f.start.page() < r.start.page() or f.start.page() > r.stop.page()))
  let line = [#term]
  for f in merged {
    line = line + [, ] + link(f.start, if f.bold { strong(f.shown) } else { f.shown })
  }
  for (i, xref) in xrefs.enumerate() {
    line = line + (if i == 0 { [, ] } else { [; ] }) + xref
  }
  block(above: 0.45em, below: 0.45em, inset: (left: depth * 1.2em), par(hanging-indent: 2.4em, justify: false, line))
}
]]

-- A Typst string literal holding `text` exactly. Every term, word and heading
-- the index prints is written this way rather than as markup, so no character
-- an author writes is read as Typst syntax (IP2). Inside a string only the
-- backslash, the double quote and control characters need an escape.
local function typst_string(text)
  local escaped = text:gsub('[%c\\"]', function(char)
    if char == "\\" then
      return "\\\\"
    elseif char == '"' then
      return '\\"'
    end
    return ("\\u{%x}"):format(char:byte())
  end)
  return '"' .. escaped .. '"'
end

-- The locator a mark adds to its entry in Typst, handed to
-- `qi_entries.build_entry_tree`. The field that names the mark's place here is
-- `label`. A range's closing adds no locator of its own: it gives its label to
-- the opening, which the range pass paired with it in this same document
-- (D-009), so the one locator spans from the opening's page to the closing's.
-- Marks reach this in document order, so the opening a closing belongs to is
-- the one this node still holds open.
local function typst_locator(node, mark)
  if mark.label == nil then
    return
  end
  if mark.paired == "close" then
    if node.open_range ~= nil then
      node.open_range.close = mark.label
      node.open_range = nil
    end
    return
  end
  local locator = { label = mark.label, role = mark.role }
  node.locators[#node.locators + 1] = locator
  if mark.paired == "open" then
    node.open_range = locator
  end
end

-- One entry's call to `qi-index-entry`, then its sub-entries', depth first.
local function entry_lines(node, depth, name, out)
  local items = {}
  for _, locator in ipairs(node.locators) do
    local close = locator.close and ("<" .. locator.close .. ">") or "none"
    items[#items + 1] = ("(<%s>, %s, %s),"):format(locator.label, close,
      tostring(locator.role == "principal"))
  end
  local xrefs = {}
  for _, xref in ipairs(node.xrefs) do
    xrefs[#xrefs + 1] = ("[#emph(%s) #(%s)],"):format(
      typst_string(qi_indexes.label(name, xref.kind.label_key, xref.kind.label)),
      typst_string(qi_entries.target_text(xref.levels)))
  end
  out[#out + 1] = ("#qi-index-entry(%d, %s, (%s), (%s))"):format(depth,
    typst_string(node.key), table.concat(items, " "), table.concat(xrefs, " "))
  for _, key in ipairs(node.sorted) do
    entry_lines(node.children[key], depth + 1, name, out)
  end
end

-- One index's blocks: a page break, the heading, then one raw Typst block
-- holding the letter groups in two columns and a page break after them. The
-- heading is Typst's own level-one `heading`, unnumbered, so Typst lists it in
-- the outline as the PDF back-end's `intoc` does. It is raw Typst rather than
-- a Pandoc header: in a document whose headings start at `##`, Quarto moves
-- every Pandoc header up a level for Typst, and a level-one header then prints
-- as a plain paragraph the outline does not list (observed on Quarto 1.10.18
-- with examples/typst-index.qmd, M098 claim audit). The page breaks are weak, so
-- they add no blank page, and they give each index a page of its own as
-- LaTeX's two-column index does.
local function index_blocks(root, name)
  local out = { "#[", TYPST_HELPERS, "#columns(2, gutter: 2em)[" }
  for _, group in ipairs(qi_entries.letter_groups(root, name)) do
    out[#out + 1] = ("#block(above: 1.1em, below: 0.6em)[#strong(%s)]"):format(
      typst_string(group.heading))
    for _, key in ipairs(group.keys) do
      entry_lines(root.children[key], 0, name, out)
    end
  end
  out[#out + 1] = "]"
  out[#out + 1] = "]"
  out[#out + 1] = "#pagebreak(weak: true)"
  return pandoc.Blocks({
    pandoc.RawBlock("typst", "#pagebreak(weak: true)"),
    pandoc.RawBlock("typst", ("#heading(level: 1, numbering: none)[#(%s)]")
      :format(typst_string(qi_indexes.title(name)))),
    pandoc.RawBlock("typst", table.concat(out, "\n")),
  })
end

-- A map from index name to that index's blocks, holding an entry only for an
-- index some mark files in, as `qi_html.html_index_blocks` does. WHERE each
-- goes is `qi_marker.place_index`'s decision.
local function typst_index_blocks(marks)
  local grouped = qi_entries.marks_by_index(marks)
  local by_index = {}
  for _, name in ipairs(qi_indexes.names()) do
    local list = grouped[name]
    if list ~= nil and #list > 0 then
      local root = qi_entries.build_entry_tree(list, typst_locator)
      -- The entry ids `number_entries` mints are links for HTML alone; the
      -- Typst index prints no link on a cross-reference, so they are minted
      -- against a set of their own.
      qi_entries.number_entries(root, 0, {})
      by_index[name] = index_blocks(root, name)
    end
  end
  return by_index
end

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
-- A minted label skips every id in `taken`. The label element follows the
-- span rather than sitting inside it: Pandoc writes the author's id label
-- straight after the span's content, and a label element there would carry
-- both labels, which Typst warns about.
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
      return { span, label_inline(label) }
    end,
    -- Pandoc's Typst writer prints an image's alt text as a string and drops
    -- any raw Typst in it, so a label written there names no element and its
    -- locator would be lost. Each such label moves to just after the image,
    -- which is on the same page. The walk is bottom-up, so the Span function
    -- above has already written them.
    Image = function(image)
      local moved = {}
      image.caption = image.caption:walk({
        RawInline = function(raw)
          if raw.format == "typst"
              and raw.text:find("<" .. qi_core.TYPST_LABEL_PREFIX, 1, true) then
            moved[#moved + 1] = raw
            return {}
          end
        end,
      })
      if #moved == 0 then
        return nil
      end
      table.insert(moved, 1, image)
      return moved
    end,
  })
end

-- Exported through the bracket form, never `M.NAME = NAME`: the source
-- scans take the FIRST match for `NAME =` over the whole source set, and
-- the M16-AC3 probe relocates a definition into another file — a plain
-- `NAME =` line left behind here would then mask it (M16 review F3).
M["TYPST_HELPERS"] = TYPST_HELPERS
M["typst_string"] = typst_string
M["label_inline"] = label_inline
M["assign_labels"] = assign_labels
M["typst_locator"] = typst_locator
M["entry_lines"] = entry_lines
M["index_blocks"] = index_blocks
M["typst_index_blocks"] = typst_index_blocks

return M
