-- quarto-index: format-neutral index marks -> per-format back-ends.
--
-- Mark syntax (all values are structured, format-neutral data; never raw
-- back-end code):
--   [term]{.index}                  index the visible term
--   [term]{.index entry="..."}      index a custom entry, term stays visible
--   []{.index entry="..."}          invisible entry
--   [term]{.index see="..."}        cross-reference: "see <target>"
--   [term]{.index see-also="..."}   cross-reference: "see also <target>"
--
-- In `entry=`, a single `!` separates sub-entry levels and `!!` is a literal
-- `!`, scanned left-to-right longest-match. Each level is literal text: the
-- LaTeX back-end makes every character literal itself, by whichever mechanism
-- that character needs (see LATEX_LITERAL). A visible term is always a single
-- literal level, so an `!` inside it is literal too.
--
-- A cross-reference target uses those same level semantics. Its source entry
-- is `entry=` when present, else the visible term, and the cross-reference
-- takes the place of the locator, as printed indexes do.

local INDEX_CLASS = "index"

-- The two cross-reference attributes, in the order their targets are emitted
-- when a mark carries both.
-- `command` is the LaTeX back-end's encap command; `label` is the words a
-- reader sees, which the LaTeX back-end gets from `\seename`/`\alsoname`
-- instead so a document loading babel keeps its translations.
local XREF_KINDS = {
  { attr = "see", command = "see", label = "see" },
  { attr = "see-also", command = "seealso", label = "see also" },
}

-- A mark carrying both attributes cannot emit two `\index` commands: they
-- share a key and a page, so makeindex reports "Conflicting entries: multiple
-- encaps for the same page under same key" and Quarto turns that warning into
-- a failed render — a marked term breaking the document, which IP2 forbids.
-- One command carrying both targets is emitted instead, through a command the
-- back-end defines itself. Its third argument is the page number makeindex
-- hands every encap, discarded here exactly as `\see` discards it. The labels
-- go through `\seename`/`\alsoname` rather than literal words, so a document
-- loading babel keeps babel's translations, as it does for a lone `\see`.
local XREF_BOTH_COMMAND = "quartoindexseeboth"
local XREF_BOTH_DEFINITION =
  "\\providecommand*\\" .. XREF_BOTH_COMMAND ..
  "[3]{\\emph{\\seename} #1; \\emph{\\alsoname} #2}"

-- Characters that are literal text on the way in and need help on the way
-- out. Most LaTeX specials are escaped with a backslash. Three groups cannot
-- be: `!` and `@` are makeindex operators, made literal with its quote
-- character; `|` and `"` are mangled by hyperref and by LaTeX's own quote
-- rendering; and `{`/`}` survive `\@sanitize` as group characters. Those last
-- four are emitted as LaTeX commands instead — see the notes below.
local LATEX_LITERAL = {
  ["%"] = "\\%",
  ["&"] = "\\&",
  ["#"] = "\\#",
  ["_"] = "\\_",
  -- NOT `\{`/`\}`: LaTeX reads an \index argument under `\@sanitize`, which
  -- gives `\` catcode 12, so a backslash there escapes nothing and the brace
  -- stays a group character — an unbalanced one aborts the render outright.
  ["{"] = "\\textbraceleft{}",
  ["}"] = "\\textbraceright{}",
  ["$"] = "\\$",
  ["<"] = "\\textless{}",
  [">"] = "\\textgreater{}",
  ["\\"] = "\\textbackslash{}",
  ["~"] = "\\textasciitilde{}",
  ["^"] = "\\textasciicircum{}",
  -- `!` and `@` are only special to makeindex, so its quote character is
  -- enough. `|` and `"` are NOT: hyperref rewrites an index argument at the
  -- first `|` before makeindex ever runs, and knows nothing about makeindex
  -- quoting, so `"|` corrupts the entry; and a makeindex-quoted `""` reaches
  -- LaTeX as a bare `"`, which typesets as a curly closing quote. Both are
  -- emitted as LaTeX commands instead, which contain no character either
  -- tool treats as active.
  ["!"] = '"!',
  ["@"] = '"@',
  ["|"] = "\\textbar{}",
  ['"'] = "\\textquotedbl{}",
}

local function warn(msg)
  if quarto and quarto.log and quarto.log.warning then
    quarto.log.warning(msg)
  else
    io.stderr:write("[quarto-index] WARNING: " .. msg .. "\n")
  end
end

-- `latex` (which also covers `pdf` output) is the only back-end that ships.
-- beamer is deliberately excluded: it has no `theindex` environment, so a
-- `\printindex` there aborts the render — and IP2 says a marked term must
-- never break a document. beamer therefore passes through like any format
-- with no index back-end, until a beamer back-end is actually written.
local function is_latex_derived()
  return FORMAT:match("latex") ~= nil
end

-- HTML is the second back-end. The match is on `html` alone, so revealjs,
-- epub and every other format keep passing through: none of them carries
-- `html` in FORMAT, and each would need an index shape of its own anyway.
local function is_html()
  return FORMAT:match("html") ~= nil
end

-- The HTML back-end's pinned identifiers. They are the only names a reader's
-- URL or an author's CSS can hold on to, so they are namespaced to the
-- extension rather than named after the word "index", which an author's own
-- heading would collide with.
local HTML_SECTION_ID = "qi-index"
local HTML_ANCHOR_PREFIX = "qi-mark-"
local HTML_ENTRY_PREFIX = "qi-entry-"

-- A mark that needs an anchor cannot be given one while it is being visited:
-- the id must not collide with an id anywhere else in the document, and the
-- document has not been seen yet. The Span pass tags such a mark with this
-- attribute, and the Pandoc pass — which has the whole document — assigns the
-- id and removes the tag. It never survives into output.
local HTML_PENDING_ATTR = "data-qi-pending"

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

-- Render one literal level as a LaTeX `\index{}` argument fragment.
local function escape_level(level)
  return (level:gsub(".", function(c)
    return LATEX_LITERAL[c] or c
  end))
end

-- makeindex stores at most three levels: it rejects a deeper entry outright
-- ("Extra `!'"), drops it from the index, and still exits 0 — the build looks
-- clean and the entry is simply gone. Rather than lose it (IP2 forbids silent
-- corruption), fold everything past the third level into the third.
local MAX_LEVELS = 3
local OVERFLOW_JOIN = ", "

local function clamp_levels(levels, context)
  if #levels <= MAX_LEVELS then
    return levels
  end
  local tail = {}
  for i = MAX_LEVELS, #levels do
    -- An empty level here would leave a dangling separator in the printed
    -- index; it is warned about above and dropped from the join.
    if levels[i] ~= "" then
      tail[#tail + 1] = levels[i]
    end
  end
  warn(("index entry in %s is %d levels deep; the back-end stores %d, so "
        .. "levels %d and deeper were folded into the third")
       :format(context, #levels, MAX_LEVELS, MAX_LEVELS))
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

-- An empty level is a property of what the author wrote, not of any one
-- back-end, so this warns wherever the document is rendered — and before any
-- back-end folds levels together, since folding absorbs a trailing empty level
-- into the level above it and would otherwise swallow the warning.
local function warn_empty_levels(levels, context)
  for _, level in ipairs(levels) do
    if level == "" then
      warn(("empty index level in %s; the level is kept as written, and a "
             .. "back-end that cannot store it may drop it"):format(context))
    end
  end
end

-- Build the `\index{...}` argument from literal levels, joining with the
-- unquoted `!` that makeindex reads as a level separator.
local function index_argument(levels, context)
  local parts = {}
  for _, level in ipairs(clamp_levels(levels, context)) do
    parts[#parts + 1] = escape_level(level)
  end
  return table.concat(parts, "!")
end

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
local function target_levels(value, attr, context)
  local kept = {}
  -- An entirely empty value has no levels to complain about individually; it
  -- falls straight through to the one warning that names the real problem.
  for _, level in ipairs(value == "" and {} or parse_levels(value)) do
    if level == "" then
      warn(("empty level in %s= on %s; dropped from the cross-reference target")
           :format(attr, context))
    else
      kept[#kept + 1] = level
    end
  end
  if #kept == 0 then
    -- Says only what is true in every branch and every format: the mark may
    -- go on to be indexed plainly, or not to be indexed at all if it has no
    -- source entry either, or to reach a format with no index back-end.
    warn(("%s= on %s has no usable target text; no cross-reference will be "
          .. "emitted for this mark"):format(attr, context))
    return nil
  end
  return kept
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

-- Set by the Span pass, read by the Pandoc pass: the preamble and
-- `\printindex` are injected only when the document actually has marks.
local marks_emitted = 0
-- The HTML back-end's equivalent: one record per mark, in document order,
-- each carrying the mark's parsed levels, its cross-reference targets, and
-- (for a locator-contributing mark) the id of the anchor that links back to
-- it. The Pandoc pass builds the whole index section out of these.
local html_marks = {}
-- Likewise: the both-targets command is defined only in a document that uses
-- it, so a document without one gets nothing extra in its preamble.
local xref_both_emitted = false

-- Index key -> the set of distinct encap strings the document emitted for it
-- (the empty string for a plain locator mark). Two marks on one key whose
-- encaps DIFFER are the same makeindex conflict the both-attributes case hits,
-- except spread across the document: if the two land on one printed page the
-- index tool rejects the pair and Quarto fails the render. That is true of a
-- plain mark against a cross-reference AND of a `see=` against a `see-also=`,
-- so the set is keyed on the encap itself rather than on a kind — two marks
-- with the SAME encap are what makeindex quietly folds together, and must not
-- be reported. Page numbers do not exist yet here, so this cannot be prevented
-- at this layer — only reported, which beats an index-tool error naming
-- neither the term nor this extension.
local key_marks = {}

local function record_key(key, encap)
  local seen = key_marks[key]
  if not seen then
    seen = {}
    key_marks[key] = seen
  end
  seen[encap] = true
end

local function Span(span)
  if not span.classes:includes(INDEX_CLASS) then
    return nil
  end

  local entry = span.attributes["entry"]
  local visible = span_text(span)
  local context = describe(entry, visible)

  -- Cross-references are parsed and validated before the format branch below,
  -- so their misuse warnings fire in every format.
  local xrefs, declared = {}, 0
  for _, kind in ipairs(XREF_KINDS) do
    local value = span.attributes[kind.attr]
    if value ~= nil then
      declared = declared + 1
      local levels = target_levels(value, kind.attr, context)
      if levels then
        xrefs[#xrefs + 1] = { kind = kind, levels = levels }
      end
    end
  end
  if declared > 1 then
    -- Probably an author error, but IP2 forbids dropping either one, so every
    -- usable target is kept and the author is told. The message deliberately
    -- does not claim both were emitted: one of the two may have had no usable
    -- target, which its own warning above already reported.
    warn("index mark carries both see= and see-also=; this is probably a "
         .. "mistake, and every usable target is kept")
  end

  local levels
  if entry ~= nil and entry ~= "" then
    levels = parse_levels(entry)
  elseif visible ~= "" then
    -- A visible term is one literal level; `!` in it is not a separator.
    levels = { visible }
  elseif declared > 0 then
    -- A cross-reference needs something to hang off. This is its own warning
    -- rather than either of the two below, because the fix is different: give
    -- the mark an entry= or some visible text.
    warn("cross-reference mark has no source entry (no entry= and no visible "
         .. "text); nothing to index")
    -- Same content policy as the two cases below: an empty mark is dropped,
    -- a mark with content keeps every bit of it.
    if #span.content == 0 then
      return {}
    end
    return nil
  elseif #span.content == 0 then
    warn("index mark with no visible term and no entry=; nothing to index")
    -- Genuinely empty and nothing to index: drop the mark rather than leave
    -- an empty group behind in the output.
    return {}
  else
    -- The span HAS content, it just yields no text to derive an entry from
    -- (an image with empty alt text, say). Index nothing, but never remove
    -- the content — deleting what the author wrote would be IP2 corruption.
    warn("index mark whose content has no text and no entry=; nothing to "
         .. "index, content left untouched")
    return nil
  end

  -- Derived once, and before the back-end branch: the levels are the author's
  -- text whatever format this is, and the both-attributes case would otherwise
  -- warn twice about the same entry.
  warn_empty_levels(levels, context)

  if is_html() then
    local record = { levels = levels, xrefs = xrefs }
    html_marks[#html_marks + 1] = record
    if #xrefs == 0 then
      -- Only a locator-contributing mark needs somewhere to link back to; a
      -- cross-reference mark takes the place of the locator and so has no
      -- anchor of its own.
      if span.identifier ~= nil and span.identifier ~= "" then
        -- An id the author wrote is left alone and used as the link target:
        -- taking it over would break whatever already points at it.
        record.anchor = span.identifier
      else
        span.attributes[HTML_PENDING_ATTR] = tostring(#html_marks)
      end
    end
    return span
  end

  if not is_latex_derived() then
    -- Formats with no index back-end pass the visible text through
    -- untouched, with no artifacts.
    return nil
  end

  local source = index_argument(levels, context)

  local result = pandoc.List(span.content)

  if #xrefs == 0 then
    record_key(source, "")
    result:insert(pandoc.RawInline("latex", "\\index{" .. source .. "}"))
    marks_emitted = marks_emitted + 1
  elseif #xrefs == 1 then
    -- `|` opens makeindex's encap channel, and `\see`/`\seealso` discard the
    -- page number handed to them, which is what makes a cross-reference
    -- replace the locator. hyperref rewrites the encap into
    -- `|hyperxindexformat{\see{...}}` before makeindex runs; that is
    -- transparent here. imakeidx, which this back-end already loads, defines
    -- `\see`, `\seealso`, `\seename` and `\alsoname` with `\providecommand`,
    -- so nothing needs injecting for the single-target forms.
    local encap = xrefs[1].kind.command
      .. "{" .. target_argument(xrefs[1].levels) .. "}"
    record_key(source, encap)
    result:insert(pandoc.RawInline("latex",
      "\\index{" .. source .. "|" .. encap .. "}"))
    marks_emitted = marks_emitted + 1
  else
    -- Both targets in one command; see XREF_BOTH_COMMAND. Each target is
    -- rendered by the same target_argument as a single-target mark, so the
    -- two forms cannot drift apart in how they escape a character.
    local args = {}
    for _, xref in ipairs(xrefs) do
      args[#args + 1] = "{" .. target_argument(xref.levels) .. "}"
    end
    local encap = XREF_BOTH_COMMAND .. table.concat(args)
    record_key(source, encap)
    result:insert(pandoc.RawInline("latex",
      "\\index{" .. source .. "|" .. encap .. "}"))
    marks_emitted = marks_emitted + 1
    xref_both_emitted = true
  end
  return result
end

-- Quarto copies a heading's inlines into the table of contents, an anchor span
-- among them, so an id minted inside a heading appears TWICE in the page and a
-- link to it resolves to the sidebar copy rather than to the text. A heading
-- already carries an id of its own, which is both unique and the better
-- destination — a locator into a section lands at the section. This runs after
-- the Span pass has visited the heading's own inlines, so the marks inside it
-- are already tagged.
local function Header(header)
  if not is_html() or header.identifier == "" then
    -- With no id to borrow, the mark keeps its pending tag and is given a
    -- minted id like any other; the duplicate above is then possible again,
    -- but Quarto gives every heading an id, so this is the unreachable case.
    return nil
  end
  header.content = header.content:walk({
    Span = function(span)
      local pending = span.attributes[HTML_PENDING_ATTR]
      if pending == nil then
        return nil
      end
      local record = html_marks[tonumber(pending)]
      if record then
        record.anchor = header.identifier
      end
      span.attributes[HTML_PENDING_ATTR] = nil
      return span
    end,
  })
  return header
end

-- ---------------------------------------------------------------------------
-- The HTML back-end.
--
-- Nothing below writes HTML: the section is built out of Pandoc AST nodes and
-- handed to Pandoc's own writer, which owns escaping (IP2). There is no level
-- ceiling here — the three-level clamp is a makeindex property, not an index
-- property — and no CSS is injected; the class names are hooks an author can
-- style, not a stylesheet this extension imposes (GP4).
-- ---------------------------------------------------------------------------

-- The normative collation rule: fold ASCII uppercase to lowercase, order by
-- codepoint, break a fold tie by codepoint. Lua compares strings byte by
-- byte and UTF-8 byte order IS codepoint order, so `<` is the rule as
-- stated. Only ASCII case folds: ordering beyond that is best-effort until
-- sort keys land (DESIGN, Conventions).
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

-- A cross-reference target as a reader sees it: the same `: ` join the LaTeX
-- back-end prints, so the two back-ends cannot drift apart on target text.
local function target_text(levels)
  return table.concat(levels, TARGET_JOIN)
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

local function new_entry(key)
  return { key = key, children = {}, sorted = {}, locators = {}, xrefs = {} }
end

-- Walk the recorded marks into a tree of entries, one level per node.
local function build_entry_tree(marks)
  local root = new_entry(nil)
  for _, mark in ipairs(marks) do
    local node = root
    for _, level in ipairs(mark.levels) do
      local child = node.children[level]
      if not child then
        child = new_entry(level)
        node.children[level] = child
      end
      node = child
    end
    if mark.anchor then
      node.locators[#node.locators + 1] = mark.anchor
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
  table.sort(keys, collate)
  node.sorted = keys
  for _, key in ipairs(keys) do
    local child = node.children[key]
    repeat
      counter = counter + 1
    until not taken[HTML_ENTRY_PREFIX .. counter]
    child.id = HTML_ENTRY_PREFIX .. counter
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
    for i, anchor in ipairs(node.locators) do
      if i > 1 then
        locators:insert(pandoc.Str(","))
        locators:insert(pandoc.Space())
      end
      locators:insert(pandoc.Link({ pandoc.Str(tostring(i)) }, "#" .. anchor))
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

local function entry_list(root, node)
  local items = pandoc.List()
  for _, key in ipairs(node.sorted) do
    local child = node.children[key]
    local blocks = pandoc.List({ pandoc.Plain(entry_inlines(root, child)) })
    if #child.sorted > 0 then
      blocks:insert(entry_list(root, child))
    end
    items:insert(blocks)
  end
  return pandoc.BulletList(items)
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
  doc:walk({ Block = note, Inline = note })
  return taken
end

-- Give every still-pending mark an id that nothing else in the document uses,
-- numbered in the order the marks are written. Skipping a taken number leaves
-- a gap in the sequence, which is the right trade: the numbers are link
-- targets, not a count of anything.
local function assign_anchors(doc, taken)
  local number = 0
  return doc:walk({
    Span = function(span)
      local pending = span.attributes[HTML_PENDING_ATTR]
      if pending == nil then
        return nil
      end
      repeat
        number = number + 1
      until not taken[HTML_ANCHOR_PREFIX .. number]
      local id = HTML_ANCHOR_PREFIX .. number
      taken[id] = true
      span.identifier = id
      span.attributes[HTML_PENDING_ATTR] = nil
      local record = html_marks[tonumber(pending)]
      if record then
        record.anchor = id
      end
      return span
    end,
  })
end

-- The section is appended with no configuration (GP4) and marked unnumbered,
-- which is how a printed index is set and which still lists it in the table
-- of contents.
local function append_html_index(doc, taken)
  local root = build_entry_tree(html_marks)
  number_entries(root, 0, taken)
  doc.blocks:insert(pandoc.Header(1, literal_inlines("Index"),
                                  pandoc.Attr(HTML_SECTION_ID,
                                              { "unnumbered" })))
  doc.blocks:insert(entry_list(root, root))
  return doc
end

-- `intoc` lists the index in the table of contents, as printed books normally
-- do. imakeidx only runs makeindex itself under `-shell-escape`, which Quarto
-- does not enable; what actually builds the index is Quarto's own PDF loop
-- reacting to the emitted `.idx` file (GP2: we emit correct output and stop).
local function Pandoc(doc)
  if is_html() then
    -- A document with no marks gets no section, exactly as one with no marks
    -- gets no LaTeX preamble.
    if #html_marks == 0 then
      return nil
    end
    local taken = taken_identifiers(doc)
    return append_html_index(assign_anchors(doc, taken), taken)
  end

  if marks_emitted == 0 or not is_latex_derived() then
    return nil
  end

  -- Reported here rather than at the mark, because it takes the whole document
  -- to know that a term has been marked both ways. Keys are walked in sorted
  -- order so the report does not depend on Lua's table iteration order.
  local conflicting = {}
  for key, encaps in pairs(key_marks) do
    local distinct = 0
    for _ in pairs(encaps) do
      distinct = distinct + 1
    end
    if distinct > 1 then
      conflicting[#conflicting + 1] = key
    end
  end
  table.sort(conflicting)
  for _, key in ipairs(conflicting) do
    warn(("index key %s is marked in more than one way (a plain locator and a "
          .. "cross-reference, or two different cross-references); if two such "
          .. "marks land on one page the index tool rejects the pair and the "
          .. "render fails"):format(key))
  end
  if not (quarto and quarto.doc and quarto.doc.use_latex_package
          and quarto.doc.include_text) then
    -- Running under plain pandoc rather than Quarto: emit the marks, but do
    -- not pretend we can inject a preamble.
    warn("preamble injection needs Quarto; \\index commands emitted without "
         .. "imakeidx setup")
    return nil
  end

  quarto.doc.use_latex_package("imakeidx")
  quarto.doc.include_text("in-header", "\\makeindex[intoc]")
  if xref_both_emitted then
    -- `\providecommand` so a document defining its own version keeps it.
    -- `\seename`/`\alsoname` are resolved where the command is used, in the
    -- generated index, not where it is defined — so nothing here depends on
    -- this landing after imakeidx.
    quarto.doc.include_text("in-header", XREF_BOTH_DEFINITION)
  end

  doc.blocks:insert(pandoc.RawBlock("latex", "\\printindex"))
  return doc
end

-- Span and Header share one pass so that a heading's marks are visited before
-- the heading itself, which is what lets Header see them already tagged.
return {
  { Span = Span, Header = Header },
  { Pandoc = Pandoc },
}
