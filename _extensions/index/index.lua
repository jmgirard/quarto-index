-- quarto-index: format-neutral index marks -> per-format back-ends.
--
-- Mark syntax (all values are structured, format-neutral data; never raw
-- back-end code):
--   [term]{.index}                  index the visible term
--   [term]{.index entry="..."}      index a custom entry, term stays visible
--   []{.index entry="..."}          invisible entry
--
-- In `entry=`, a single `!` separates sub-entry levels and `!!` is a literal
-- `!`, scanned left-to-right longest-match. Each level is literal text: the
-- LaTeX back-end escapes LaTeX specials and quotes makeindex-active
-- characters itself. A visible term is always a single literal level, so an
-- `!` inside it is literal too.

local INDEX_CLASS = "index"

-- Characters that are literal text on the way in and need help on the way
-- out. LaTeX specials are escaped. Of the makeindex-active characters,
-- `!` and `@` are made literal with makeindex's quote character, while
-- `|` and `"` need LaTeX commands instead — see the note on those two
-- entries below.
local LATEX_LITERAL = {
  ["%"] = "\\%",
  ["&"] = "\\&",
  ["#"] = "\\#",
  ["_"] = "\\_",
  ["{"] = "\\{",
  ["}"] = "\\}",
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
    tail[#tail + 1] = levels[i]
  end
  warn(("index entry in %s is %d levels deep; the back-end stores %d, so "
        .. "levels %d and deeper were folded into the last one")
       :format(context, #levels, MAX_LEVELS, MAX_LEVELS))
  local clamped = {}
  for i = 1, MAX_LEVELS - 1 do
    clamped[i] = levels[i]
  end
  clamped[MAX_LEVELS] = table.concat(tail, OVERFLOW_JOIN)
  return clamped
end

-- Build the `\index{...}` argument from literal levels, joining with the
-- unquoted `!` that makeindex reads as a level separator.
local function index_argument(levels, context)
  local parts = {}
  for _, level in ipairs(clamp_levels(levels, context)) do
    if level == "" then
      warn(("empty index level in %s; emitted as written"):format(context))
    end
    parts[#parts + 1] = escape_level(level)
  end
  return table.concat(parts, "!")
end

local function span_text(span)
  return pandoc.utils.stringify(span.content)
end

-- Set by the Span pass, read by the Pandoc pass: the preamble and
-- `\printindex` are injected only when the document actually has marks.
local marks_emitted = 0

local function Span(span)
  if not span.classes:includes(INDEX_CLASS) then
    return nil
  end

  local entry = span.attributes["entry"]
  local visible = span_text(span)

  local levels
  if entry ~= nil and entry ~= "" then
    levels = parse_levels(entry)
  elseif visible ~= "" then
    -- A visible term is one literal level; `!` in it is not a separator.
    levels = { visible }
  else
    warn("index mark with no visible term and no entry=; nothing to index")
    -- Nothing to index and nothing to show: drop the mark rather than leave
    -- an empty group behind in the output.
    return {}
  end

  if not is_latex_derived() then
    -- Formats with no index back-end pass the visible text through
    -- untouched, with no artifacts.
    return nil
  end

  local context = entry and ('entry="' .. entry .. '"')
    or ('term "' .. visible .. '"')
  local raw = pandoc.RawInline("latex", "\\index{" .. index_argument(levels, context) .. "}")
  marks_emitted = marks_emitted + 1

  local result = pandoc.List(span.content)
  result:insert(raw)
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
  if not (quarto and quarto.doc and quarto.doc.use_latex_package) then
    -- Running under plain pandoc rather than Quarto: emit the marks, but do
    -- not pretend we can inject a preamble.
    warn("preamble injection needs Quarto; \\index commands emitted without "
         .. "imakeidx setup")
    return nil
  end

  quarto.doc.use_latex_package("imakeidx")
  quarto.doc.include_text("in-header", "\\makeindex[intoc]")

  doc.blocks:insert(pandoc.RawBlock("latex", "\\printindex"))
  return doc
end

return {
  { Span = Span },
  { Pandoc = Pandoc },
}
