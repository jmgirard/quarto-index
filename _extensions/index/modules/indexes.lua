-- Which indexes a document has, in the order they print, and which one a mark
-- or a placement marker that names none belongs to.
--
-- Read once per document from the `indexes:` metadata, before any pass sees a
-- mark: every accumulator downstream is keyed by the index a mark files in, so
-- the table has to be settled before the first mark is recorded. That is why
-- the per-document reset is a `Pandoc` hook rather than an element one, and
-- why this module's `reset` takes the document.

local qi_core = require("./core")

local M = {}

-- The attribute naming which index a mark or a placement marker belongs to.
-- `index` is not an HTML attribute, so Pandoc data-prefixes it exactly as it
-- does `see` and `range` -- there is no `mention`-shaped collision to avoid
-- here, where a real HTML attribute name would have reached output verbatim.
local INDEX_ATTR = "index"

-- The metadata key an author declares under, and the two fields one
-- declaration carries. A declaration is a two-field map rather than a one-key
-- `name: title` pair so that a later per-index setting is a third field, not a
-- change to syntax authors have already written (GP5).
local INDEXES_KEY = "indexes"
local NAME_FIELD = "name"
local TITLE_FIELD = "title"

-- The heading a document that declares nothing prints, which is what it has
-- always printed. It is also what a FOLDED render heads its single section
-- with, for the reason `section_id` keeps that section's id bare: the section
-- holds every declared index's marks, so heading it with one declared index's
-- title would claim it is that index rather than the union it is.
local DEFAULT_TITLE = "Index"

-- What a declared name may be. The name reaches output as the section's HTML
-- id (`section_id` below) and as the fragment of every link to it, so a name
-- that is no id fragment is a section no link resolves against -- a space, a
-- `#`, a `"` or a `<` each break the id, the URL fragment or both. The rule is
-- stated positively rather than as a blacklist: an author reading the report
-- learns what to write, and a character nobody thought of is refused rather
-- than emitted.
-- Two characters an id may legally hold are refused anyway, both for the one
-- reason: the id has to be nameable by a plain `#id` selector, which is how a
-- stylesheet reaches the section and how a script finds it. A leading digit
-- is a selector no `#id` rule can name without escaping. A dot is worse,
-- because it does not fail loudly -- `#qi-index-my.index` parses as the id
-- `qi-index-my` carrying the class `index`, so the selector is valid, matches
-- something other than the section, and says nothing (M38 review round 2).
local NAME_SHAPE = "^[A-Za-z][A-Za-z0-9_%-]*$"

-- The name of the one index a document that declares nothing has. The empty
-- string is not a name an author can write -- a declaration whose `name:` is
-- empty is refused below -- so this cell can never collide with a declared
-- one, and `qi-index` stays the id such a document's section has always had.
local UNNAMED = ""

-- The declared names in print order, and the title each prints under. Both are
-- module-level accumulators like every other, emptied in place by `reset` for
-- the reason marks.lua's own `reset` states.
-- Initialized to the unnamed index rather than to empty tables, and `reset`
-- restores exactly this: the rest of the filter is written against "there is
-- always an index to file a mark in", and a module that only acquired one once
-- `reset` had run would hand a nil index to every accumulator keyed by one.
-- Nothing in the shipped filter reads these before `reset`; the M26 pollution
-- probe does, which is what makes the invariant testable rather than assumed.
local order = { UNNAMED }
local titles = { [UNNAMED] = DEFAULT_TITLE }
-- Did the document declare anything? A document that did not is not the same
-- as one that declared a single index: the first prints the bare `qi-index`
-- section it always has, and the second prints an index named after what its
-- author wrote.
local declared = false
-- Does the running back-end keep ONE index whatever the marks name? True for
-- an HTML book alone, whose sidecar store carries no per-record index name
-- yet, so every chapter's record folds to the reading chapter's default. It
-- says so out loud rather than dropping a named mark in silence (IP2).
-- A LaTeX-derived render no longer folds (M49): it writes one `.idx` per
-- declared index and imakeidx builds each of the named ones itself, under the
-- restricted shell escape a TeX installation grants `makeindex` by default.
local folded = false

-- Does this render build an index at all? The fold reports say a mark was
-- indexed in the document's one index instead, which is only true where an
-- index is built: in a format with no back-end nothing is indexed either way,
-- and the sentence would be a claim about output that does not exist.
local function builds_index()
  return qi_core.is_latex_derived() or qi_core.is_html()
end

-- One declaration's `name:`/`title:`, appended to `kept` in declared order, or
-- nothing where the entry is unusable. Reported rather than skipped in
-- silence: a declaration the author wrote and this filter ignored is an index
-- whose marks all land somewhere else (IP2).
--
-- `kept` is a local of the read below rather than the module's own table,
-- because a declaration that yields nothing usable must leave the document
-- with exactly the single unnamed index it started with -- half a declaration
-- installed over that would be a document with an index its author never
-- named.
local function read_declaration(item, position, kept, seen)
  if pandoc.utils.type(item) ~= "table" then
    qi_core.warn(("entry %d of the %s: metadata is not a map with a %s: and a %s:; it declares no index, so marks naming one are filed in the first index this document does declare"):format(position, INDEXES_KEY, NAME_FIELD, TITLE_FIELD))
    return
  end
  if item[NAME_FIELD] == nil then
    qi_core.warn(("entry %d of the %s: metadata has no %s:, so there is nothing for a mark to name it by and it declares no index"):format(position, INDEXES_KEY, NAME_FIELD))
    return
  end
  local name = pandoc.utils.stringify(item[NAME_FIELD])
  if name == UNNAMED then
    qi_core.warn(("entry %d of the %s: metadata has an empty %s:, which no mark can name, so it declares no index"):format(position, INDEXES_KEY, NAME_FIELD))
    return
  end
  if not name:match(NAME_SHAPE) then
    qi_core.warn(('entry %d of the %s: metadata declares the name "%s", which cannot be a section id a `#id` selector names; a name holds ASCII letters, digits, hyphen and underscore and begins with a letter, so this entry declares no index'):format(position, INDEXES_KEY, name))
    return
  end
  if seen[name] then
    qi_core.warn(('entry %d of the %s: metadata declares the name "%s" a second time; one name is one index, so this entry is ignored and the first declaration of that name is the one that prints'):format(position, INDEXES_KEY, name))
    return
  end
  local title = name
  if item[TITLE_FIELD] == nil then
    qi_core.warn(('the index named "%s" has no %s: in the %s: metadata; its section is headed with the name itself, which is probably not what a reader should read'):format(name, TITLE_FIELD, INDEXES_KEY))
  else
    title = pandoc.utils.stringify(item[TITLE_FIELD])
    if title == UNNAMED then
      qi_core.warn(('the index named "%s" has an empty %s: in the %s: metadata; its section is headed with the name itself, since a section with no heading text is one a reader cannot find'):format(name, TITLE_FIELD, INDEXES_KEY))
      title = name
    end
  end
  seen[name] = true
  kept[#kept + 1] = { name = name, title = title }
end

-- Read the declaration. Anything unusable leaves the document with the one
-- unnamed index it would have had without the key at all, which is exactly
-- today's behavior -- never with no index to file marks in, and never with a
-- partly installed declaration.
local function read(meta)
  local value = meta and meta[INDEXES_KEY] or nil
  if value == nil then
    return
  end
  if pandoc.utils.type(value) ~= "List" then
    qi_core.warn(("%s: in this document's metadata is not a list of index declarations; it is ignored, and every mark is filed in the one index this document has always had"):format(INDEXES_KEY))
    return
  end
  if #value == 0 then
    qi_core.warn(("%s: in this document's metadata is an empty list, so it declares no index; every mark is filed in the one index this document has always had"):format(INDEXES_KEY))
    return
  end
  local kept, seen = {}, {}
  for position, item in ipairs(value) do
    read_declaration(item, position, kept, seen)
  end
  if #kept == 0 then
    -- Every entry was refused, and each said why. What this adds is the
    -- outcome: the document is back to the single index it started with.
    qi_core.warn(("no entry of the %s: metadata declared a usable index, so every mark is filed in the one index this document has always had"):format(INDEXES_KEY))
    return
  end
  -- The unnamed index installed by `reset` is replaced whole, so the FIRST
  -- declared name is the default a mark naming none files in -- and so the
  -- unnamed cell cannot survive alongside the declared ones as an index no
  -- mark can reach but the printer would still emit.
  qi_core.empty(order)
  qi_core.empty(titles)
  for i, entry in ipairs(kept) do
    order[i] = entry.name
    titles[entry.name] = entry.title
  end
  declared = true
end

-- Every mutable cell this module owns, back to the value its declaration
-- gives, for the reason marks.lua's own `reset` states. The two tables are
-- emptied in place because they are exported by reference.
--
-- The unnamed index is installed BEFORE the declaration is read, so there is
-- never a moment at which the document has no index to file a mark in -- a
-- warning drawn while reading the declaration is drawn by a mark-less pass,
-- but the invariant is what the rest of this module is written against.
local function reset(doc)
  qi_core.empty(order)
  qi_core.empty(titles)
  declared = false
  order[1] = UNNAMED
  titles[UNNAMED] = DEFAULT_TITLE
  -- An HTML book renders a chapter per Pandoc process and aggregates through
  -- the sidecar store, whose record format carries no index name, so every
  -- record folds to the reading chapter's default and the book prints one
  -- section. Every other render -- a single HTML page, and every LaTeX-derived
  -- one, a merged book included -- keeps the indexes their author declared.
  -- `doc.meta.book` is the same test index.lua uses for "this looks like a
  -- book", and it is available here, which the resolved chapter context is not
  -- -- that is computed in the final Pandoc pass, long after the first mark has
  -- been recorded.
  folded = qi_core.is_html() and doc ~= nil and doc.meta ~= nil
           and doc.meta.book ~= nil
  if doc ~= nil then
    read(doc.meta)
  end
end

local function names()
  return order
end

-- The heading this index's section carries. A folded render prints ONE section
-- holding every declared index's marks, so it is headed with the neutral title
-- rather than with the first declared index's -- the same reason `section_id`
-- keeps that section's id bare, and the same heading a document that declares
-- nothing has always printed.
local function title(name)
  if declared and folded then
    return DEFAULT_TITLE
  end
  return titles[name] or DEFAULT_TITLE
end

local function default()
  return order[1]
end

-- The set a per-index judgement was made within, as a report must name it.
-- A cross-reference target and a range pairing are settled inside ONE index
-- (M38), so a document that declares several cannot call that set "this
-- document": the term the author is told nothing indexes may be marked in the
-- document all along, in another index, and "mark that term somewhere" is then
-- advice that does not fix anything (review O1/O2).
-- `outer` is the word the caller would otherwise have used -- "document",
-- "book", "chapter" -- and is kept wherever there is genuinely one namespace:
-- a document that declares nothing or declares one index, and any back-end
-- that folds, which resolved every mark to the one index before these
-- judgements ran.
local function scope_phrase(name, outer)
  -- A caller with no index in hand -- a finding whose message names no scope
  -- at all -- gets the outer word back untouched, so this is safe to call on
  -- every finding rather than only on the ones that print a scope.
  if name == nil or not declared or folded or #order < 2 then
    return outer
  end
  return ('index "%s"'):format(name)
end

local function is_declared()
  return declared
end

local function folds()
  return folded
end

-- The index a mark naming `value` belongs to, before the back-end folds
-- anything: the one it names, or the default where it names none. A value
-- naming no declared index is reported in EVERY format, like every other
-- judgement about what the author wrote -- a mark filed somewhere other than
-- where its author said is a defect wherever the document is rendered.
local function declared_for(value)
  if value == nil or titles[value] == nil then
    return nil
  end
  return value
end

-- A mark's index, and the report for a value naming none. `report` follows the
-- convention the rest of the filter uses: only the emitting pass says
-- anything, so a mark's warnings fire once however many passes read it.
local function mark_index(value, context, report)
  local name = declared_for(value)
  if name == nil then
    if value ~= nil and report then
      qi_core.warn(('%s="%s" on %s names no index this document declares; declare it under %s: in the metadata, or the mark is filed in the first index the document has'):format(INDEX_ATTR, value, context, INDEXES_KEY))
    end
    return order[1]
  end
  if folded and name ~= order[1] then
    if report and builds_index() then
      qi_core.warn(('%s="%s" on %s names a second index, and this output has one index only, so the mark is indexed in that one index instead; an HTML book aggregates its chapters through a per-chapter record carrying no index name, which is why it builds one'):format(INDEX_ATTR, value, context))
    end
    return order[1]
  end
  return name
end

-- The index a mark or a marker names as its author wrote it, before any
-- back-end folds anything: the declared index it names, or the default where it
-- names none, or names one this document never declared. Silent, because the
-- reports about what the author wrote are drawn once by the emitting pass; this
-- is for the caller that has to know which index the AUTHOR meant even where
-- the running back-end will not build it.
local function authored_index(value)
  return declared_for(value) or order[1]
end

-- The same for a placement marker. A separate call rather than a shared one
-- with a composed noun: the message-distinctness scan reads the string
-- literals INSIDE a `warn()` call, so a message built elsewhere and handed in
-- is text no such scan can see.
--
-- `fold` says what became of this marker under a back-end that keeps one index,
-- which only the caller can know: under fold there is one index and one place
-- to put it, and which marker holds that place is a question about the whole
-- document rather than about this marker. `"places"` is the marker that holds
-- it, `"elsewhere"` one that lost it to the marker naming the index this
-- back-end does build, and `"quiet"` one whose own report is drawn by the
-- caller instead -- a second marker for the same index, whose duplicate report
-- says everything this one would and says which marker took the place.
local FOLD_PLACES = "places"
local FOLD_ELSEWHERE = "elsewhere"
local FOLD_QUIET = "quiet"

local function marker_index(value, report, fold)
  local name = declared_for(value)
  if name == nil then
    if value ~= nil and report then
      qi_core.warn(('%s="%s" on an index placement marker names no index this document declares; declare it under %s: in the metadata, or the marker places the first index the document has'):format(INDEX_ATTR, value, INDEXES_KEY))
    end
    return order[1], false
  end
  if folded and name ~= order[1] then
    if report and builds_index() and fold ~= FOLD_QUIET then
      if fold == FOLD_PLACES then
        qi_core.warn(('%s="%s" on an index placement marker names a second index, and this output has one index only, so the marker places that one index instead; an HTML book aggregates its chapters through a per-chapter record carrying no index name, which is why it builds one'):format(INDEX_ATTR, value))
      else
        qi_core.warn(('%s="%s" on an index placement marker names a second index, and this output has one index only, which goes where this document already places it, so this marker places nothing; an HTML book aggregates its chapters through a per-chapter record carrying no index name, which is why it builds one'):format(INDEX_ATTR, value))
      end
    end
    return order[1], true
  end
  return name, false
end

-- The id the section for this index carries. A document that declared nothing
-- keeps the bare name it has always had, so its readers' links still resolve;
-- a declared index is named after itself rather than numbered, so a link keeps
-- pointing at the same index when the author reorders the declaration.
-- Whether the id is actually free is `mint_section_id`'s question, not this
-- one's: this says what to ask for.
local function section_id(name)
  -- A document that declared nothing keeps the bare name, so its readers'
  -- links still resolve. So does a render that FOLDS: there is exactly one
  -- section there and it holds every index's marks, so naming it after one of
  -- the declared indexes would claim it is that index rather than the union it
  -- is. Only where the sections are actually one-per-index is each named after
  -- the index it holds.
  if not declared or folded then
    return qi_core.HTML_SECTION_ID
  end
  return qi_core.HTML_SECTION_ID .. "-" .. name
end

-- Exported through the bracket form, never `M.NAME = NAME`: the source
-- scans take the FIRST match for `NAME =` over the whole source set, and
-- the M16-AC3 probe relocates a definition into another file — a plain
-- `NAME =` line left behind here would then mask it (M16 review F3).
M["INDEX_ATTR"] = INDEX_ATTR
M["INDEXES_KEY"] = INDEXES_KEY
M["NAME_FIELD"] = NAME_FIELD
M["TITLE_FIELD"] = TITLE_FIELD
M["DEFAULT_TITLE"] = DEFAULT_TITLE
M["NAME_SHAPE"] = NAME_SHAPE
M["UNNAMED"] = UNNAMED
M["reset"] = reset
M["read"] = read
M["names"] = names
M["title"] = title
M["default"] = default
M["scope_phrase"] = scope_phrase
M["is_declared"] = is_declared
M["folds"] = folds
M["builds_index"] = builds_index
M["declared_for"] = declared_for
M["authored_index"] = authored_index
M["mark_index"] = mark_index
M["FOLD_PLACES"] = FOLD_PLACES
M["FOLD_ELSEWHERE"] = FOLD_ELSEWHERE
M["FOLD_QUIET"] = FOLD_QUIET
M["marker_index"] = marker_index
M["section_id"] = section_id

return M
