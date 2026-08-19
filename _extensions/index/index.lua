-- quarto-index: format-neutral index marks -> per-format back-ends.
--
-- Mark syntax (all values are structured, format-neutral data; never raw
-- back-end code):
--   [term]{.index}                  index the visible term
--   [term]{.index entry="..."}      index a custom entry, term stays visible
--   []{.index entry="..."}          invisible entry
--   [term]{.index see="..."}        cross-reference: "see <target>"
--   [term]{.index see-also="..."}   cross-reference: "see also <target>"
--   [term]{.index sort="..."}       file the entry under different text
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
--
-- `sort=` uses those same level semantics again, and lines up position by
-- position with the entry's levels: the Nth sort level says where the Nth
-- entry level files, and a level with no sort level of its own files under
-- its own printed text. The value is ordinary author text like every other
-- mark value (IP1) — the back-end alone writes whatever syntax its index
-- tool needs. `sort=` is not accepted on a cross-reference target: a target
-- is prose naming another entry, and that entry carries its own sort key.

local INDEX_CLASS = "index"

-- The placement marker: an empty div the author writes where the index should
-- appear. It is deliberately NOT the generated section's id `qi-index` — one
-- string carrying two meanings is a collision waiting to be reported as a bug.
-- Recognized at the top level of the document only: a `\printindex` inside a
-- group or environment is an IP2-class render risk, so a marker written below
-- the top level places nothing.
local MARKER_CLASS = "qi-index-here"

-- The two cross-reference attributes, in the order their targets are emitted
-- when a mark carries both.
-- `command` is the LaTeX back-end's encap command; `label` is the words a
-- reader sees, which the LaTeX back-end gets from `\seename`/`\alsoname`
-- instead so a document loading babel keeps its translations.
local XREF_KINDS = {
  { attr = "see", command = "see", label = "see" },
  { attr = "see-also", command = "seealso", label = "see also" },
}

-- The same kinds by attribute name. A book's store holds an attribute name
-- rather than the kind table itself, and reads it back through this.
local XREF_KIND_BY_ATTR = {}
for _, kind in ipairs(XREF_KINDS) do
  XREF_KIND_BY_ATTR[kind.attr] = kind
end

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
local HTML_LETTER_CLASS = "qi-letter"

-- A mark's anchor cannot be settled while the mark is being visited: whether
-- the mark's own id serves, where the anchor may sit, and what a minted id
-- must not collide with all depend on parts of the document not yet seen.
-- The Span pass tags every locator-contributing mark with this attribute,
-- and the Pandoc pass — which has the whole document — resolves the anchor
-- and removes the tag. It never survives into output.
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

-- The inverse of parse_levels: one string that identifies a level list, and
-- identifies it injectively, because a level's own `!` is doubled exactly as
-- an author would have written it. A plain `table.concat(levels, "!")` would
-- make {"a!b"} and {"a","b"} the same string, which would merge two distinct
-- entries in the conflict report below. Format-neutral: no back-end escaping.
local function levels_key(levels)
  local parts = {}
  for i, level in ipairs(levels) do
    parts[i] = level:gsub("!", "!!")
  end
  return table.concat(parts, "!")
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
  -- Every level here prints something: an empty one was dropped when the entry
  -- was derived (drop_empty_levels), so the join can never leave a dangling
  -- separator in the printed index.
  local tail = {}
  for i = MAX_LEVELS, #levels do
    tail[#tail + 1] = levels[i]
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

-- An empty level prints nothing, so it is not a level: the entry indexes at
-- whatever is left. Dropping it is a property of what the author wrote rather
-- than of any one back-end, so it happens once here and every format sees the
-- same levels — and it is what keeps a null field away from the LaTeX index
-- tool, which rejects an entry outright for a leading or middle one, drops it,
-- reports no warning and exits 0.
--
-- Returns the surviving levels, the ORIGINAL index of each (so a sort level
-- can be dropped together with the entry level it was written for), and the
-- depth the author actually wrote.
local function drop_empty_levels(parsed, context, report)
  local levels, kept = {}, {}
  for i, level in ipairs(parsed) do
    if level ~= "" then
      levels[#levels + 1] = level
      kept[#kept + 1] = i
    end
  end
  -- Silent when NOTHING survived: the caller has a single message for that
  -- mark, about the value as a whole, and a count of levels none of which
  -- printed anything would only bury it.
  if report and #levels > 0 then
    for _ = 1, #parsed - #levels do
      warn(("empty index level in %s; an empty level prints nothing, so it is "
            .. "dropped and the entry indexes at the levels that remain")
           :format(context))
    end
  end
  return levels, kept, #parsed
end

-- Parse a `sort=` value and line it up with the entry's levels. The result
-- says only what the AUTHOR declared: element i is the sort key written for
-- level i, or `false` where the author wrote nothing there. The printed-text
-- fallback is applied later, by `sort_for`, because only the registry knows
-- whether some other mark of the same level declared a key — substituting the
-- fallback here is what made a silent mark overwrite a declaring one.
--
-- An empty sort level means "leave this level alone", which is why it is not
-- warned about the way an empty ENTRY level is: there it is a hole in what the
-- author is indexing, here it is the ordinary way to skip a level.
--
-- Returns nil when the value declares no sort key at all, which keeps a
-- document that never writes `sort=` byte-identical in the LaTeX back-end.
local function sort_levels(value, levels, context, report, kept, depth)
  if value == nil then
    return nil
  end
  local written = parse_levels(value)
  -- Lined up with the entry levels that SURVIVED the empty-level drop. A sort
  -- level belongs to the level it was written for, so one written for a level
  -- that printed nothing goes with it rather than sliding onto the next: with
  -- `entry="!Cats" sort="mmm!cats"`, `Cats` files under `cats`, never `mmm`.
  local parsed = written
  if kept ~= nil then
    parsed = {}
    for i, original in ipairs(kept) do
      parsed[i] = written[original]
    end
  end
  -- The depth the AUTHOR wrote, which is what the ignored-levels count below
  -- is measured against — an entry whose empty level was dropped has not
  -- ignored the sort level that went with it, and saying so would draw a
  -- second warning for one mistake.
  depth = depth or #levels
  -- The last position the author actually wrote a key for. Everything before
  -- it that merely restates the level's own printed text is positional filler
  -- — the way this syntax reaches a deeper level, since two separators in a
  -- row are a literal `!` — while a self-equal key AT that last position is a
  -- real declaration, the author saying where this level files.
  local last = 0
  for i = 1, #parsed do
    if parsed[i] ~= "" then
      last = i
    end
  end
  if report then
    -- Counted over the levels the author DECLARED past the entry's depth: an
    -- empty sort level is the documented "leave this level alone", so a
    -- trailing empty one ignores nothing and must not say it did.
    local ignored = 0
    for i = depth + 1, #written do
      if written[i] ~= "" then
        ignored = ignored + 1
      end
    end
    if ignored > 0 then
      warn(("sort= on %s has %d levels but the entry has %d; the extra sort "
            .. "levels were ignored"):format(context, #written, depth))
    end
  end
  local declared, any = {}, false
  for i = 1, #levels do
    local key = parsed[i]
    if key ~= nil and key ~= "" and not (key == levels[i] and i < last) then
      declared[i] = key
      any = true
    else
      -- `false`, not nil: the list is written to the book store and read back
      -- through JSON, where a hole in the middle of an array is not a shape
      -- either side can rely on. Filler lands here too, so it never reaches
      -- the registry and never rivals a key some other mark declared.
      declared[i] = false
    end
  end
  if not any then
    return nil
  end
  return declared
end

-- The printed level path down to level `n`, as one injective string. A sort
-- key belongs to a LEVEL under its own parents, not to a whole entry: both
-- back-ends order level by level — makeindex reads `sortkey@printed` inside
-- each `!`-separated level, and the HTML tree keys each node on its printed
-- level text — so "Aaa" must file the same way whether it was written alone
-- or as the parent of a sub-entry. Keying the registry on the full entry path
-- instead is what split one printed entry across two keys.
local function level_path(levels, n)
  local prefix = {}
  for i = 1, n do
    prefix[i] = levels[i]
  end
  return levels_key(prefix)
end

-- Printed level path -> the first sort key declared for it, and the context
-- that declared it. Two marks that file ONE printed level under two different
-- sort keys are an authoring mistake with a visible cost in both back-ends:
-- the HTML tree is keyed on the printed levels, so one of the two keys simply
-- loses, and makeindex treats the two as different keys and prints the entry
-- twice, in two places, identically. Neither is recoverable from the output,
-- so the mistake is reported instead. The accumulator is format-neutral —
-- filled before any back-end branch — because it is a property of what the
-- author wrote, like every other warning about the mark itself.
local sort_keys = {}

-- Register a mark's declared sort keys, one per level, and report a second,
-- different key for a level already spoken for. First mark in document order
-- wins, so the index does not depend on which mark the author edits last.
-- Only a level the author actually wrote a key for registers or conflicts: a
-- term is usually marked in several places and a sort key written on one of
-- them is meant for the entry, not for that one mark (GP4), so the marks that
-- stay silent inherit it rather than contradict it.
local function register_sort(levels, declared, context)
  if declared == nil then
    return
  end
  for i = 1, #levels do
    local key = declared[i]
    -- Positional filler was already dropped by sort_levels, so everything
    -- arriving here is a declaration — including one whose text equals the
    -- level's own, which is an author saying where the level files and so
    -- wins ties and reports rivals like any other.
    if key then
      local path = level_path(levels, i)
      local seen = sort_keys[path]
      if seen == nil then
        sort_keys[path] = { sort = key, context = context }
      elseif seen.sort ~= key then
        -- Once per RIVAL KEY at this path, not once per mark carrying it: a
        -- term is usually marked in several places, and repeating one rival
        -- key gives the author nothing further to fix. A second, different
        -- rival is a second thing to fix, though — the message names the key
        -- it is about, so suppressing it would leave that key unmentioned
        -- until the first was resolved and the document rendered again.
        -- The two marks are usually described identically — the same term,
        -- twice — so the message names the two KEYS, which are what actually
        -- differ and what the author has to choose between.
        seen.reported = seen.reported or {}
        if not seen.reported[key] then
          seen.reported[key] = true
          warn(('index entry in %s is already sorted as "%s"; the sort key '
                .. '"%s" written here cannot apply as well, so the first one '
                .. 'wins'):format(context, seen.sort, key))
        end
      end
    end
  end
end

-- What the emitting pass applies: for each level, the key registered for that
-- level's path — whichever mark of it declared one — and the level's own
-- printed text where no mark declared anything. Returns nil when no level on
-- this path has a key, so a mark with no sort key anywhere above or at it
-- emits exactly what it always did.
local function sort_for(levels)
  local resolved, any = {}, false
  for i = 1, #levels do
    local seen = sort_keys[level_path(levels, i)]
    if seen then
      resolved[i] = seen.sort
      any = true
    else
      resolved[i] = levels[i]
    end
  end
  if not any then
    return nil
  end
  return resolved
end

-- Clamp sort levels alongside the entry levels clamp_levels performs. The
-- folded third level is one printed string built from several, so it files
-- under the sort key of the first level that went into it — joining sort keys
-- the way the printed text is joined would file the entry under text no author
-- wrote. A key written for a level past the third goes where that level went:
-- the level itself is folded away, so there is nothing left for its key to
-- place, and the fold warning already names the entry.
local function clamp_sort(sort)
  if sort == nil or #sort <= MAX_LEVELS then
    return sort
  end
  local clamped = {}
  for i = 1, MAX_LEVELS do
    clamped[i] = sort[i]
  end
  return clamped
end

-- Build the `\index{...}` argument from literal levels, joining with the
-- unquoted `!` that makeindex reads as a level separator. With a sort key,
-- each level becomes makeindex's own `sortkey@printed` form: the `@` here is
-- written by this back-end and so is the ONE `@` that stays unquoted, while
-- every `@` the author wrote is still quoted by escape_level (LATEX_LITERAL).
--
-- Returns three strings: the argument, the PRINTED level path after the fold,
-- and the FILING path — for each level, the sort key this argument actually
-- files it under. The last two are what the collision report below compares,
-- and they are built here rather than by a second derivation elsewhere,
-- because only the emitted argument settles which of a level's two candidate
-- strings the index tool will read as its key. Both are literal text, not
-- escaped: they are read by an author, not by the index tool.
--
-- The clamped levels are returned as well, for the self-target comparison the
-- caller runs against them. They are returned rather than recomputed because
-- clamp_levels warns about the fold, and a second call would report it twice.
local function index_argument(levels, sort, context)
  local clamped = clamp_levels(levels, context)
  local keys = clamp_sort(sort)
  local parts, filing = {}, {}
  for i, level in ipairs(clamped) do
    local printed = escape_level(level)
    -- Compared against the level the key was ALIGNED with, not against the
    -- clamped text: where levels were folded, the third clamped level is a
    -- join of several and never equals the key resolved for the third level,
    -- so comparing against it emits a sort field on every folded entry —
    -- filing it under the third level's own printed text, which is what the
    -- absence of a sort field already means.
    if keys ~= nil and keys[i] ~= nil and keys[i] ~= levels[i] then
      parts[#parts + 1] = escape_level(keys[i]) .. "@" .. printed
      filing[i] = keys[i]
    else
      parts[#parts + 1] = printed
      -- No sort field emitted, so the index tool files this level under the
      -- text it prints — the CLAMPED text, which is not always the level the
      -- key was compared against.
      filing[i] = level
    end
  end
  return table.concat(parts, "!"), levels_key(clamped),
         levels_key(filing), clamped
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

-- Set by the Span pass, read by the Pandoc pass: the preamble and the index
-- itself are emitted only when the document actually has marks. Counted before
-- the back-end branch, so "this document has marks" means the same thing in
-- every format — the marker's no-marks warning is format-neutral and cannot be
-- asked of a per-back-end accumulator.
local marks_seen = 0
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

-- Printed level path (AFTER the three-level fold) -> the set of filing paths
-- the document emitted for it. Sort keys are declared against the level paths
-- the author wrote, and the fold does not change those, so two entries whose
-- paths differ before the fold and agree after it keep a key each: the index
-- tool receives two keys, stores the one printed entry twice, and prints it
-- twice, in two places, identically, with nothing in the log to say so.
-- Neither key is this filter's to drop (IP2) and which of the two the author
-- meant is not recoverable from the document, so the pair is reported.
--
-- LaTeX-only, unlike the sort-key reports about a mark: the fold is the index
-- tool's ceiling rather than a property of what the author wrote, and the HTML
-- back-end applies none, so there the two entries are genuinely two.
local clamped_paths = {}

local function record_clamped(path, filing)
  local seen = clamped_paths[path]
  if not seen then
    seen = {}
    clamped_paths[path] = seen
  end
  seen[filing] = true
end

-- The one place a mark's index levels are derived from what the author wrote.
-- Both Span passes call it, so they cannot drift on what an entry's levels
-- are; only the emitting pass passes `report`, so a mark's warnings fire once
-- however many passes read it.
--
-- Returns `levels, nil` when there is something to index, and
-- `nil, "drop"|"keep"` when there is not — "drop" removing a genuinely empty
-- mark, "keep" leaving content the author wrote untouched (IP2).
local function derive_levels(entry, visible, declared, content_count, context,
                             sort_value, report)
  -- Set once the author has already been told WHY nothing is indexable, so
  -- the generic messages below never claim they wrote no entry= when the
  -- value they wrote is right there in the warning above.
  local explained = false
  if entry ~= nil and entry ~= "" then
    local levels, kept, depth = drop_empty_levels(parse_levels(entry), context,
                                                  report)
    if #levels > 0 then
      return levels, nil, kept, depth
    end
    -- Every level empty. The per-level warning above did not fire for this
    -- mark: one message about the value as a whole says more than a count of
    -- levels none of which printed anything.
    if visible ~= "" then
      if report then
        warn(("%s is only empty levels, which print nothing; the mark indexes "
              .. "under its visible text instead"):format(context))
      end
      return { visible }, nil
    end
    if report then
      warn(("%s is only empty levels, which print nothing; nothing to index")
           :format(context))
    end
    explained = true
  elseif visible ~= "" then
    -- A visible term is one literal level; `!` in it is not a separator.
    return { visible }, nil
  end

  -- Nothing to index. A sort key says where an entry files, so one on a mark
  -- that indexes no entry is asking for something that cannot happen — the
  -- one warning every branch below shares.
  if report and sort_value ~= nil then
    warn(("sort= on %s has nothing to sort; the mark indexes no entry")
         :format(context))
  end

  if declared > 0 then
    -- A cross-reference needs something to hang off. This is its own warning
    -- rather than either of the two below, because the fix is different: give
    -- the mark an entry= or some visible text.
    if report and not explained then
      warn("cross-reference mark has no source entry (no entry= and no "
           .. "visible text); nothing to index")
    end
    -- Same content policy as the two cases below: an empty mark is dropped,
    -- a mark with content keeps every bit of it.
    return nil, content_count == 0 and "drop" or "keep"
  end
  if content_count == 0 then
    if report and not explained then
      warn("index mark with no visible term and no entry=; nothing to index")
    end
    -- Genuinely empty and nothing to index: drop the mark rather than leave
    -- an empty group behind in the output.
    return nil, "drop"
  end
  -- The span HAS content, it just yields no text to derive an entry from
  -- (an image with empty alt text, say). Index nothing, but never remove
  -- the content — deleting what the author wrote would be IP2 corruption.
  if report and not explained then
    warn("index mark whose content has no text and no entry=; nothing to "
         .. "index, content left untouched")
  end
  return nil, "keep"
end

-- The collect pass: a full traversal that only reads. It runs before the
-- emitting pass so that a sort key written on ANY mark of an entry is known
-- before the first mark of that entry is emitted — a mark emitted under a key
-- a later mark then contradicts would print the entry twice.
local function CollectSort(span)
  if not span.classes:includes(INDEX_CLASS) then
    return nil
  end
  local sort_value = span.attributes["sort"]
  if sort_value == nil then
    -- Only a declaring mark registers anything, so a document that never
    -- writes `sort=` leaves this pass with no state at all.
    return nil
  end
  local entry = span.attributes["entry"]
  local visible = span_text(span)
  local context = describe(entry, visible)
  local declared = 0
  for _, kind in ipairs(XREF_KINDS) do
    if span.attributes[kind.attr] ~= nil then
      declared = declared + 1
    end
  end
  local levels, _, kept, depth = derive_levels(entry, visible, declared,
                                              #span.content, context,
                                              sort_value, false)
  if levels == nil then
    return nil
  end
  -- Reported here rather than in the emitting pass: this is the pass that can
  -- see a conflict before anything has been emitted under either key.
  register_sort(levels,
                sort_levels(sort_value, levels, context, true, kept, depth),
                context)
  return nil
end

local function Span(span)
  local forged = span.attributes[HTML_PENDING_ATTR] ~= nil
  if forged then
    -- The pending tag is this filter's own plumbing (see HTML_PENDING_ATTR).
    -- One written by the author — on any span, a cross-reference mark
    -- included — would hijack a real mark's anchor in assign_anchors, so it
    -- is discarded wherever it is found.
    span.attributes[HTML_PENDING_ATTR] = nil
  end
  if not span.classes:includes(INDEX_CLASS) then
    if forged then
      return span
    end
    return nil
  end

  local entry = span.attributes["entry"]
  local visible = span_text(span)
  local context = describe(entry, visible)
  local sort_value = span.attributes["sort"]

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
         .. "mistake, and neither is dropped for being one of two")
  end

  -- Derived once, and before the back-end branch: the levels are the author's
  -- text whatever format this is, and the empty-level warnings the derivation
  -- emits would otherwise fire twice for one mark.
  local levels, disposition, kept, depth =
    derive_levels(entry, visible, declared, #span.content, context,
                  sort_value, true)
  if levels == nil then
    return disposition == "drop" and {} or nil
  end

  -- A cross-reference target naming the entry it is written on says nothing:
  -- "Cats, see Cats" in print, and in HTML a link from an entry to itself. The
  -- target is dropped and the mark then indexes as usual — dropping the whole
  -- mark would lose the term, which is the corruption IP2 forbids, and keeping
  -- the target would leave the useless output in place.
  --
  -- Compared on the PRINTED levels rather than on the filing key: a sort key
  -- never appears in the index a reader reads, so a target matching the printed
  -- text is a self-reference whatever the mark files under. Before the back-end
  -- branch, like every other judgement about what the author wrote.
  --
  -- Neither side can carry an empty level any more: a target drops its own
  -- when it is parsed (target_levels) and an entry drops its own when it is
  -- derived (drop_empty_levels), so `entry="Cats!"` and a target of `Cats` are
  -- one printed path and compare equal without the comparison knowing anything
  -- about emptiness. M10 reconciled the two spellings here instead, because
  -- the entry side kept what it was written with.
  local own_key = levels_key(levels)
  local surviving = {}
  for _, xref in ipairs(xrefs) do
    if levels_key(xref.levels) == own_key then
      warn(("%s= on %s names the entry it is written on; a cross-reference to "
            .. "itself says nothing, so it is dropped and the term is indexed "
            .. "as usual"):format(xref.kind.attr, context))
    else
      surviving[#surviving + 1] = xref
    end
  end
  xrefs = surviving
  -- Resolved by the collect pass, which has already seen every mark of this
  -- entry: whichever mark declared the sort key, every mark of the entry files
  -- under it.
  local sort = sort_for(levels)
  -- Every path from here indexes the mark in whichever back-end is running:
  -- one `\index` command in LaTeX, one record in HTML, nothing at all where
  -- there is no back-end. The count is what the marker's no-marks warning and
  -- both back-ends read.
  marks_seen = marks_seen + 1

  if is_html() then
    local record = { levels = levels, sort = sort, xrefs = xrefs }
    html_marks[#html_marks + 1] = record
    if #xrefs == 0 then
      -- Only a locator-contributing mark needs somewhere to link back to; a
      -- cross-reference mark takes the place of the locator and so has no
      -- anchor of its own. WHICH id anchors it — the author's own, or a
      -- minted one — is settled in the Pandoc pass, which can see every id
      -- in the document and every heading a mark sits in.
      span.attributes[HTML_PENDING_ATTR] = tostring(#html_marks)
    end
    return span
  end

  if not is_latex_derived() then
    -- Formats with no index back-end pass the visible text through
    -- untouched, with no artifacts.
    return nil
  end

  local source, printed_path, filing_path, clamped =
    index_argument(levels, sort, context)
  -- Recorded for every mark whatever it emits: a cross-reference mark files
  -- under the same key a plain one does, so it contests a printed path just
  -- as a locator mark would.
  record_clamped(printed_path, filing_path)

  -- The self-target comparison again, now against what THIS back-end prints.
  -- The format-neutral pass above ran on the levels the author wrote; here the
  -- fold has already rewritten them, so an entry can print a path the author
  -- never spelled and a target spelling that path is a self-reference the
  -- first pass could not see. It lives here, and not beside the first pass,
  -- because the three-level ceiling is a property of this back-end alone:
  -- HTML has none, so the same document keeps the target there, and a format
  -- with no index back-end never reaches this line. Neither side carries an
  -- empty level, for the same reason neither does above.
  local printed_key = levels_key(clamped)
  local kept_after_fold = {}
  for _, xref in ipairs(xrefs) do
    if levels_key(xref.levels) == printed_key then
      -- The folded path is quoted because the author never wrote it: it is
      -- what their entry prints once the back-end has folded it, and a report
      -- naming only what they typed would describe a match they cannot see.
      warn(("%s= on %s names the folded path this entry prints (%s); the "
            .. "back-end stores %d levels, and the fold made the target a "
            .. "cross-reference to itself, so it is dropped and the term is "
            .. "indexed as usual")
           :format(xref.kind.attr, context, printed_path, MAX_LEVELS))
    else
      kept_after_fold[#kept_after_fold + 1] = xref
    end
  end
  xrefs = kept_after_fold

  local result = pandoc.List(span.content)

  if #xrefs == 0 then
    record_key(source, "")
    result:insert(pandoc.RawInline("latex", "\\index{" .. source .. "}"))
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
    xref_both_emitted = true
  end
  return result
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
    if mark.anchor then
      node.locators[#node.locators + 1] = mark_target(mark)
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
    for i, target in ipairs(node.locators) do
      if i > 1 then
        locators:insert(pandoc.Str(","))
        locators:insert(pandoc.Space())
      end
      locators:insert(pandoc.Link({ pandoc.Str(tostring(i)) }, target))
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
                               pandoc.Attr("", { HTML_LETTER_CLASS })))
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
              local pending = span.attributes[HTML_PENDING_ATTR]
              local marked_id = span.classes:includes(INDEX_CLASS)
                and span.identifier ~= ""
              if pending == nil and not marked_id then
                return nil
              end
              local anchor = pandoc.Span({})
              anchor.identifier = span.identifier
              if pending ~= nil then
                anchor.attributes[HTML_PENDING_ATTR] = pending
              end
              anchors:insert(anchor)
              span.identifier = ""
              span.attributes[HTML_PENDING_ATTR] = nil
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
      local pending = span.attributes[HTML_PENDING_ATTR]
      if pending == nil then
        return nil
      end
      span.attributes[HTML_PENDING_ATTR] = nil
      if span.identifier == "" then
        repeat
          number = number + 1
        until not taken[HTML_ANCHOR_PREFIX .. number]
        span.identifier = HTML_ANCHOR_PREFIX .. number
        taken[span.identifier] = true
      end
      local record = html_marks[tonumber(pending)]
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
  if not taken[HTML_SECTION_ID] then
    taken[HTML_SECTION_ID] = true
    return HTML_SECTION_ID
  end
  local n = 0
  local candidate
  repeat
    n = n + 1
    candidate = HTML_SECTION_ID .. "-" .. n
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

-- ---------------------------------------------------------------------------
-- The placement marker.
--
-- Everything below is format-neutral and runs before any back-end branch: a
-- misused marker is diagnosed wherever the document is rendered, and a marker
-- leaves no residue in any format — the ones with no index back-end included
-- (IP2).
-- ---------------------------------------------------------------------------

local function is_marker(block)
  return block.t == "Div" and block.classes:includes(MARKER_CLASS)
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
    if attr == nil or not attr.classes:includes(MARKER_CLASS) then
      return nil
    end
    local name = MARKER_SITE_NAMES[element.t] or element.t
    -- Every name this table can produce is an ordinary English noun phrase, so
    -- the article follows from its first letter; a fallback name is a Pandoc
    -- type name, where the same test still reads correctly ("an Emph").
    local article = name:match("^[aeiouAEIOU]") and "an" or "a"
    warn(("the index placement marker class is written on %s %s; only an empty "
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
    warn("index placement marker is not empty; the marker should be an empty "
         .. "div, and its content is kept where the marker was written")
  end
  -- The marker is a position, not an element: it is removed, so anything
  -- written ON it goes with it. An id would be the worse loss — a link to it
  -- would silently resolve nowhere — so neither is dropped in silence.
  local extra = {}
  for _, class in ipairs(block.classes) do
    if class ~= MARKER_CLASS then
      extra[#extra + 1] = class
    end
  end
  if block.identifier ~= "" or #extra > 0 then
    warn(("index placement marker carries an id or extra class (%s); a marker "
          .. "is a position rather than an element, so it is removed and these "
          .. "are not carried onto the index"):format(
         block.identifier ~= "" and ("#" .. block.identifier)
           or ("." .. table.concat(extra, " ."))))
  end
  return block.content
end

-- Strip every marker below the top level of one top-level block. A
-- `\printindex` inside a group or environment is an IP2-class render risk, so
-- a nested marker places nothing; the index keeps its automatic position.
local function strip_nested_markers(block)
  return block:walk({
    Blocks = function(blocks)
      local out = pandoc.Blocks({})
      for _, inner in ipairs(blocks) do
        if is_marker(inner) then
          warn("index placement marker below the top level of the document "
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
-- site remains. Positions are the author's: the index the marker has among the
-- document's top-level blocks, counted before anything is removed.
local function resolve_markers(doc)
  local out = pandoc.Blocks({})
  local seen = 0
  for position, block in ipairs(doc.blocks) do
    block = strip_nested_markers(block)
    if is_marker(block) then
      seen = seen + 1
      if seen == 1 then
        out:insert(block)
      else
        warn(("index placement marker %d (top-level block %d) is ignored; the "
              .. "index is placed at the first marker"):format(seen, position))
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

-- ---------------------------------------------------------------------------
-- Book projects (HTML only).
--
-- A book renders each chapter in its own Pandoc process, so no chapter can see
-- another's marks: left alone, every chapter appends an index of its own and
-- none of them is the book's index. Each chapter therefore writes what it
-- found to a sidecar store, and the chapter carrying the placement marker
-- reads the whole store back and builds one index for the book.
--
-- The LaTeX back-end needs none of this: a PDF book is rendered as one merged
-- document, so its marks are already all in one process, and nothing here runs
-- for it.
--
-- The store lives in Quarto's own per-project scratch directory, which is
-- already outside the output directory and already ignored by a Quarto
-- project's `.gitignore` — a book gains no new file an author has to know
-- about (GP4).
-- ---------------------------------------------------------------------------

local STORE_DIR = "quarto-index"
local STORE_SUFFIX = ".qi.json"
-- A record's shape is this filter's own business, and the store outlives the
-- version that wrote it: nothing prunes it, and a project keeps rendering
-- across extension upgrades. A record whose version is not this one is
-- ignored rather than read as if its fields still meant what they did.
local STORE_VERSION = 3

-- Paths from Quarto are the host's; hrefs are always `/`-separated.
local function as_href(path)
  return (path:gsub("\\", "/"))
end

local function strip_prefix(path, prefix)
  path, prefix = as_href(path), as_href(prefix)
  if path:sub(1, #prefix + 1) == prefix .. "/" then
    return path:sub(#prefix + 2)
  end
  return nil
end

-- What this chapter needs to know about the book it belongs to, or nil when
-- this is not a book chapter (or Quarto has not told us enough to be sure).
-- Everything is derived from Quarto's own metadata rather than guessed: the
-- chapter order from `book.render`, this chapter's source and output paths
-- from `quarto.doc`, and how deep this page sits from `quarto.project.offset`.
local function book_context(doc)
  if not (quarto and quarto.project and quarto.doc) then
    return nil
  end
  local root, out = quarto.project.directory, quarto.project.output_directory
  local input, output = quarto.doc.input_file, quarto.doc.output_file
  if not (root and out and input and output and doc.meta.book) then
    return nil
  end
  local render = doc.meta.book.render
  if render == nil then
    return nil
  end
  local chapters, positions = {}, {}
  for _, item in ipairs(render) do
    -- A part heading with no file of its own is not a chapter; every entry
    -- that names a file is, in the order the book renders them.
    if type(item) == "table" and item.file ~= nil then
      -- Normalized exactly as the input and output paths below are: this list
      -- is matched against the current chapter's own path, and a host that
      -- spells one of them with backslashes must not turn every subdirectory
      -- chapter into a chapter this book does not contain.
      local file = as_href(pandoc.utils.stringify(item.file))
      chapters[#chapters + 1] = file
      positions[file] = #chapters
    end
  end
  local file = strip_prefix(input, root)
  local href = strip_prefix(output, out)
  if #chapters == 0 or file == nil or href == nil or positions[file] == nil then
    return nil
  end
  return {
    chapters = chapters,
    positions = positions,
    file = file,
    href = href,
    position = positions[file],
    -- The path from this page back to the site root, which is what turns
    -- another chapter's site-relative href into a link this page can use.
    offset = as_href(quarto.project.offset or "."),
    dir = pandoc.path.join({ root, ".quarto", STORE_DIR }),
  }
end

-- Another chapter's page, as a link from the page holding the index.
local function relative_href(ctx, href)
  if ctx.offset == "" or ctx.offset == "." then
    return href
  end
  return ctx.offset .. "/" .. href
end

local function store_path(ctx, file)
  return pandoc.path.join({ ctx.dir, file .. STORE_SUFFIX })
end

-- One chapter's record: what it marked, where those marks are anchored on its
-- own page, and whether it carries the placement marker.
local function store_write(ctx, marker)
  local marks = {}
  for _, mark in ipairs(html_marks) do
    local xrefs = {}
    for _, xref in ipairs(mark.xrefs) do
      xrefs[#xrefs + 1] = { attr = xref.kind.attr, levels = xref.levels }
    end
    marks[#marks + 1] =
      { levels = mark.levels, xrefs = xrefs, anchor = mark.anchor }
  end
  -- The chapter's DECLARED sort keys, one per printed level path, rather than
  -- a resolved key per mark. A mark's resolved key already has this chapter's
  -- fallbacks filled in, and a fallback is indistinguishable from a declared
  -- key once written down — so the book would read one chapter's fallback as
  -- a rival to another chapter's real key, and, being first in book order,
  -- let the fallback win.
  local sorts = {}
  for path, seen in pairs(sort_keys) do
    sorts[path] = seen.sort
  end
  -- Every step here can fail on an ordinary machine — a stale file where the
  -- directory belongs, a read-only project tree, a full disk — and none of
  -- them may take the render down with it: a marked-up document always
  -- renders (IP2). The whole write is one guarded unit, reported once.
  local path = store_path(ctx, ctx.file)
  local ok, err = pcall(function()
    pandoc.system.make_directory(pandoc.path.directory(path), true)
    local fh, open_err = io.open(path, "w")
    if not fh then
      error(tostring(open_err), 0)
    end
    local written, write_err = fh:write(pandoc.json.encode(
      { version = STORE_VERSION, file = ctx.file, href = ctx.href,
        marker = marker, marks = marks, sorts = sorts }))
    fh:close()
    if not written then
      error(tostring(write_err), 0)
    end
  end)
  if not ok then
    warn(("could not record index marks for %s (%s); this chapter's marks "
          .. "will be missing from the book's index until it is rendered "
          .. "again"):format(ctx.file, tostring(err)))
  end
end

-- Every chapter record the store holds, in book order. Reading by the current
-- chapter list is what makes a stale record harmless: a chapter dropped from
-- the book is never read, however long its file lingers in the store.
-- Is this decoded record shaped the way the aggregation below will read it?
-- Checked here rather than trusted, because a record that parses as JSON and
-- is shaped wrong reaches the entry builder and takes the render down with
-- it, which IP2 forbids — and version skew across an extension upgrade is
-- exactly how a wrongly shaped record appears in a store nothing prunes.
local function valid_record(data, file)
  if type(data) ~= "table" or data.version ~= STORE_VERSION then
    return false
  end
  -- A record naming a different chapter than the file it was read from is not
  -- this chapter's record, whatever wrote it.
  if data.file ~= file or type(data.href) ~= "string"
     or type(data.marks) ~= "table" then
    return false
  end
  for _, mark in ipairs(data.marks) do
    if type(mark) ~= "table" or type(mark.levels) ~= "table"
       or #mark.levels == 0 then
      return false
    end
    for _, level in ipairs(mark.levels) do
      if type(level) ~= "string" then
        return false
      end
    end
    if mark.anchor ~= nil and type(mark.anchor) ~= "string" then
      return false
    end
    if mark.xrefs ~= nil and type(mark.xrefs) ~= "table" then
      return false
    end
  end
  -- The chapter's declared sort keys: a printed level path to the key filed
  -- under it, both strings. A record with none is ordinary — most chapters
  -- declare no sort key at all.
  if data.sorts ~= nil then
    if type(data.sorts) ~= "table" then
      return false
    end
    for path, key in pairs(data.sorts) do
      if type(path) ~= "string" or type(key) ~= "string" then
        return false
      end
    end
  end
  return true
end

local function store_read(ctx)
  local records = {}
  for _, file in ipairs(ctx.chapters) do
    local fh = io.open(store_path(ctx, file), "r")
    if fh then
      local text = fh:read("a")
      fh:close()
      local ok, data = pcall(pandoc.json.decode, text, false)
      if ok and valid_record(data, file) then
        records[#records + 1] = data
      else
        -- Never silent: the cost of a record this version cannot use is a
        -- chapter missing from the index, and the fix is the same either way
        -- — render that chapter again. WHY it could not be used is not: a
        -- record left by an older version of this extension is perfectly
        -- readable and simply stale, and calling that unreadable sends an
        -- author looking for a corrupt file that is not there.
        if ok and type(data) == "table" and data.version ~= STORE_VERSION then
          warn(("the recorded index marks for %s were written by a different "
                .. "version of this extension and were ignored; render that "
                .. "chapter again, or render the whole book, to put its "
                .. "terms back in the index"):format(file))
        else
          warn(("the recorded index marks for %s could not be read and were "
                .. "ignored; render that chapter again, or render the whole "
                .. "book, to put its terms back in the index"):format(file))
        end
      end
    end
  end
  return records
end

-- Every chapter's marks as the entry builder wants them: the kind tables
-- restored from their attribute names, and each locator pointed at the page
-- of the chapter that carries it.
-- One entry, one sort key — across a whole book, not only within a chapter.
-- Each chapter renders in its own process, so the in-document collect pass
-- cannot see a second chapter's key; this is where the book's records meet,
-- and so the only place the conflict can be found. First in BOOK order wins,
-- which is the same rule a single document uses and, unlike "last one seen",
-- does not depend on which chapter Quarto happened to render last.
local function book_sort_keys(records)
  local resolved = {}
  for _, record in ipairs(records) do
    -- One chapter's paths in a fixed order. `pairs` walks a Lua table in
    -- whatever order it likes, and two chapters each declaring two rival keys
    -- would otherwise report them in an order that changed between renders.
    local paths = {}
    for path in pairs(record.sorts or {}) do
      paths[#paths + 1] = path
    end
    table.sort(paths)
    for _, path in ipairs(paths) do
      local key = record.sorts[path]
      local seen = resolved[path]
      if seen == nil then
        resolved[path] = { sort = key, file = record.file, reported = {} }
      elseif seen.sort ~= key and not seen.reported[key] then
        -- Once per RIVAL KEY at this path, the same rule the in-document
        -- report follows: a term marked in three chapters under one rival key
        -- is one thing for the author to fix, while a second, different rival
        -- is a second thing and names a key the first report never mentions.
        seen.reported[key] = true
        warn(('index entry "%s" is sorted as "%s" in %s and as "%s" in %s; '
              .. 'one entry cannot file in two places, so the first in book '
              .. 'order wins')
             :format(path, seen.sort, seen.file, key, record.file))
      end
    end
  end
  return resolved
end

-- The book counterpart of `sort_for`: the same level-path lookup with the
-- same printed-text fallback, reading the book's merged registry rather than
-- this chapter's.
local function book_sort_for(keys, levels)
  local resolved, any = {}, false
  for i = 1, #levels do
    local seen = keys[level_path(levels, i)]
    if seen then
      resolved[i] = seen.sort
      any = true
    else
      resolved[i] = levels[i]
    end
  end
  if not any then
    return nil
  end
  return resolved
end

local function book_marks(ctx, records)
  local book_keys = book_sort_keys(records)
  local marks = {}
  for _, record in ipairs(records) do
    for _, mark in ipairs(record.marks or {}) do
      local xrefs = {}
      for _, xref in ipairs(mark.xrefs or {}) do
        local kind = XREF_KIND_BY_ATTR[xref.attr]
        if kind then
          xrefs[#xrefs + 1] = { kind = kind, levels = xref.levels }
        end
      end
      marks[#marks + 1] = {
        levels = mark.levels,
        -- The book's keys for this mark's levels, not this chapter's own: a
        -- term marked in three chapters with a sort key written in one of
        -- them files under that key everywhere, exactly as it does inside one
        -- document — and a level's key applies wherever that level appears,
        -- alone or as some sub-entry's parent.
        sort = book_sort_for(book_keys, mark.levels),
        xrefs = xrefs,
        anchor = mark.anchor,
        -- A mark in the chapter holding the index links within its own page,
        -- exactly as a single document's does.
        -- Written exactly as Quarto writes its own links to that page,
        -- raw rather than percent-escaped: Quarto normalizes a link target
        -- either way, so an escape here is undone before it reaches output
        -- (its own sidebar link to a space-named chapter is `./a b.html`).
        href = record.file ~= ctx.file and relative_href(ctx, record.href)
          or nil,
      }
    end
  end
  return marks
end

-- The first chapter in book order that carries a marker, by position, or nil.
local function marker_chapter(ctx, records)
  local first = nil
  for _, record in ipairs(records) do
    local position = ctx.positions[record.file]
    if record.marker and position and (first == nil or position < first) then
      first = position
    end
  end
  return first
end

local function any_marks(records)
  for _, record in ipairs(records) do
    if #(record.marks or {}) > 0 then
      return true
    end
  end
  return false
end

-- One chapter of a book. Anchors are assigned here whatever this chapter is,
-- because they are what the book's index links back to; the index itself is
-- built by one chapter only.
local function html_book(doc, ctx, marker, taken)
  store_write(ctx, marker)
  local records = store_read(ctx)
  -- Whether THIS chapter carries the marker is known here, and is never read
  -- back from the store: a chapter whose own record failed to write would
  -- otherwise conclude that some other chapter holds the marker, build no
  -- index, and report a chapter that does not exist.
  local placing = marker_chapter(ctx, records)
  if marker and (placing == nil or placing > ctx.position) then
    placing = ctx.position
  end

  if marker and placing == ctx.position then
    if not any_marks(records) then
      -- The book path's counterpart to the single-document no-marks warning,
      -- which cannot be asked of one chapter. Without it a marker in a book
      -- that marks nothing renders an empty index section.
      warn("index placement marker in a book whose chapters have no index "
           .. "marks; there is no index to place")
      return place_index(doc, nil)
    end
    local later = {}
    for position = ctx.position + 1, #ctx.chapters do
      later[#later + 1] = ctx.chapters[position]
    end
    if #later > 0 then
      -- Chapters render in book order, so a chapter after this one has not
      -- run yet in this render: what the index shows for it is whatever an
      -- earlier render recorded, which may name terms that chapter no longer
      -- marks and link to anchors its page no longer has.
      warn(("the index placement marker is in %s, and %d chapter(s) come "
            .. "after it (%s); the index is built where the marker is, so "
            .. "those chapters are represented by what an earlier render "
            .. "recorded — entries and links for them can be out of date or "
            .. "dead. Put the marker chapter last in the book")
           :format(ctx.file, #later, table.concat(later, ", ")))
    end
    return place_index(doc, html_index_blocks(book_marks(ctx, records), taken))
  end

  if marker then
    warn(("index placement marker in %s is ignored; %s comes first in book "
          .. "order and carries one too, and a book has a single index")
         :format(ctx.file, ctx.chapters[placing]))
  elseif ctx.position == #ctx.chapters and placing == nil
         and any_marks(records) then
    -- Reported by the last chapter in book order, which is the only chapter
    -- that can know no other one asked for the index: every earlier chapter
    -- has written its record by the time this one runs. One full render
    -- therefore reports this exactly once.
    warn("this book has index marks but no chapter carries an index "
         .. "placement marker, so no index was built; write an empty div "
         .. "with class qi-index-here in the chapter that should hold the "
         .. "index, usually the last one")
  end
  return place_index(doc, nil)
end

-- `intoc` lists the index in the table of contents, as printed books normally
-- do. imakeidx only runs makeindex itself under `-shell-escape`, which Quarto
-- does not enable; what actually builds the index is Quarto's own PDF loop
-- reacting to the emitted `.idx` file (GP2: we emit correct output and stop).
local function Pandoc(doc)
  -- Before any back-end branch: the marker is the author's syntax, so its
  -- misuse is diagnosed in every format and its residue removed in every
  -- format, whether or not that format has an index to place.
  report_marker_sites(doc)
  local marker = resolve_markers(doc)
  -- A book chapter is not the whole document: the marks the marker places are
  -- mostly in other chapters, so "no marks here" says nothing about whether
  -- there is an index to place, and the book path reports what it finds
  -- across the whole store instead.
  local book = is_html() and book_context(doc) or nil
  if is_html() and book == nil and doc.meta.book ~= nil then
    -- Falling back to a per-chapter index is not a safe default in a book: it
    -- is the shipped-before-M05 defect, one index per chapter and none of them
    -- the book's. Whatever Quarto did not tell us, the author hears about it
    -- rather than finding a stray index on a page later.
    warn("this looks like a book, but the chapter list and output paths this "
         .. "extension needs were not available, so this page was indexed on "
         .. "its own instead of contributing to the book's index")
  end
  if marker and marks_seen == 0 and not book then
    warn("index placement marker in a document with no index marks; there is "
         .. "no index to place")
  end

  if is_html() then
    -- Anchors are assigned before either path decides what to place: they are
    -- what a locator links back to, and in a book they are read by whichever
    -- chapter builds the index rather than by this one. A page with no marks
    -- that places no index needs none of it, and is not walked for ids.
    local taken = {}
    if marks_seen > 0 or book then
      taken = taken_identifiers(doc)
    end
    if marks_seen > 0 then
      doc = relocate_heading_anchors(doc)
      doc = assign_anchors(doc, taken)
    end
    if book then
      return html_book(doc, book, marker, taken)
    end
    -- A document with no marks gets no section, exactly as one with no marks
    -- gets no LaTeX preamble.
    if marks_seen == 0 then
      return place_index(doc, nil)
    end
    return place_index(doc, html_index_blocks(html_marks, taken))
  end

  if marks_seen == 0 or not is_latex_derived() then
    return place_index(doc, nil)
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

  -- The level-fold collision, reported the same way and for the same reason:
  -- it takes the whole document to know that a second entry prints where the
  -- first one does. Once per contested printed path rather than once per key
  -- or once per mark — the author's fix is a single choice between the keys,
  -- and the message has to show all of them to let them make it. Paths are
  -- walked in sorted order, and so are the keys within one, so the report does
  -- not depend on Lua's table iteration order.
  local contested = {}
  for path, filings in pairs(clamped_paths) do
    local keys = {}
    for filing in pairs(filings) do
      keys[#keys + 1] = filing
    end
    if #keys > 1 then
      table.sort(keys)
      contested[#contested + 1] = { path = path, keys = keys }
    end
  end
  table.sort(contested, function(a, b) return a.path < b.path end)
  for _, clash in ipairs(contested) do
    local named = {}
    for i, key in ipairs(clash.keys) do
      if key == clash.path then
        -- Not a key the author wrote: it is what an entry carrying no sort
        -- key files under. Quoting it back as one would name a string they
        -- never typed and cannot search for — and it is the printed path
        -- already quoted earlier in the same sentence.
        named[i] = "its printed text, which is what an entry with no sort "
          .. "key there files under"
      else
        named[i] = '"' .. key .. '"'
      end
    end
    local last = table.remove(named)
    warn(('index entries printed as "%s" file under more than one key (%s), '
          .. 'so the index tool stores one key each and prints that entry '
          .. 'once per key, in as many places; give them one sort key, or '
          .. 'write them as one entry')
         :format(clash.path, table.concat(named, ", ") .. " and " .. last))
  end
  if not (quarto and quarto.doc and quarto.doc.use_latex_package
          and quarto.doc.include_text) then
    -- Running under plain pandoc rather than Quarto: emit the marks, but do
    -- not pretend we can inject a preamble.
    warn("preamble injection needs Quarto; \\index commands emitted without "
         .. "imakeidx setup")
    return place_index(doc, nil)
  end

  if marker then
    -- Quarto emits the package load as
    -- `\@ifpackageloaded{imakeidx}{}{\usepackage[noautomatic]{imakeidx}}`, so a
    -- document whose template or header-includes loads imakeidx FIRST takes
    -- the empty branch and never gets the option — and then every mark below
    -- the marker is dropped from the index, which is the silent corruption the
    -- option exists to prevent. Nothing emitted here can reach a load that
    -- already happened, so the unfixable case is made loud instead: a
    -- begin-document check that says what will be missing and why. It warns
    -- rather than erroring, because a marked-up document must still render
    -- (IP2). `\PassOptionsToPackage` is deliberately NOT emitted alongside it:
    -- it registers the option on the already-loaded package, which would make
    -- this check report success on exactly the document it exists to catch.
    quarto.doc.include_text("in-header",
      "\\makeatletter\\AtBeginDocument{\\@ifpackagewith{imakeidx}{noautomatic}"
      .. "{}{\\PackageWarning{quarto-index}{This document loads imakeidx "
      .. "itself without the noautomatic option, so terms marked after the "
      .. "index placement marker will be missing from the index}}}"
      .. "\\makeatother")
    -- `\printindex` closes the `.idx` file it has just read, so every `\index`
    -- written after it goes to the log instead — silently, and only the marks
    -- BELOW the marker are lost, which is exactly the corruption IP2 forbids.
    -- imakeidx skips that close under `noautomatic`, which costs a document
    -- nothing here: the automatic run needs `-shell-escape`, which Quarto does
    -- not enable, so the index was always built by Quarto's own PDF loop
    -- (GP2). The option is emitted only where a marker made it necessary, so a
    -- document without one keeps the preamble it has always had.
    quarto.doc.use_latex_package("imakeidx", "noautomatic")
  else
    quarto.doc.use_latex_package("imakeidx")
  end
  quarto.doc.include_text("in-header", "\\makeindex[intoc]")
  if xref_both_emitted then
    -- `\providecommand` so a document defining its own version keeps it.
    -- `\seename`/`\alsoname` are resolved where the command is used, in the
    -- generated index, not where it is defined — so nothing here depends on
    -- this landing after imakeidx.
    quarto.doc.include_text("in-header", XREF_BOTH_DEFINITION)
  end

  return place_index(doc,
    pandoc.Blocks({ pandoc.RawBlock("latex", "\\printindex") }))
end

-- The Span pass records the marks; every anchor decision that needs the
-- whole document — which ids are taken, which marks sit inside headings —
-- waits for the Pandoc pass.
return {
  { Span = CollectSort },
  { Span = Span },
  { Pandoc = Pandoc },
}
