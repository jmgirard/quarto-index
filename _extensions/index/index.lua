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
local XREF_KINDS = {
  { attr = "see", command = "see" },
  { attr = "see-also", command = "seealso" },
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

-- Build the `\index{...}` argument from literal levels, joining with the
-- unquoted `!` that makeindex reads as a level separator.
local function index_argument(levels, context)
  -- Warn on the levels as the author wrote them, before any folding: folding
  -- absorbs a trailing empty level into the level above it, which would
  -- otherwise swallow the warning that Scope promises for it.
  for _, level in ipairs(levels) do
    if level == "" then
      warn(("empty index level in %s; emitted as written unless it falls "
             .. "inside a folded tail, where it is dropped"):format(context))
    end
  end
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

  if not is_latex_derived() then
    -- Formats with no index back-end pass the visible text through
    -- untouched, with no artifacts.
    return nil
  end

  -- Derived once: index_argument warns about the levels it is given, and the
  -- both-attributes case would otherwise warn twice about the same entry.
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

-- `intoc` lists the index in the table of contents, as printed books normally
-- do. imakeidx only runs makeindex itself under `-shell-escape`, which Quarto
-- does not enable; what actually builds the index is Quarto's own PDF loop
-- reacting to the emitted `.idx` file (GP2: we emit correct output and stop).
local function Pandoc(doc)
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

return {
  { Span = Span },
  { Pandoc = Pandoc },
}
