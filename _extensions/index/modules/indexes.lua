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
-- always printed.
local DEFAULT_TITLE = "Index"

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
-- every LaTeX-derived render -- Quarto's PDF loop builds only the main `.idx`,
-- so a second index would print empty at exit 0 -- and true for an HTML book,
-- whose sidecar store carries no per-record index name yet. Both fold, and
-- both say so out loud rather than dropping a named mark in silence (IP2).
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
  -- the sidecar store, whose record format carries no index name; a merged
  -- LaTeX book and a single PDF both reach one `.idx`. `doc.meta.book` is the
  -- same test index.lua uses for "this looks like a book", and it is available
  -- here, which the resolved chapter context is not -- that is computed in the
  -- final Pandoc pass, long after the first mark has been recorded.
  folded = not qi_core.is_html() or (doc ~= nil and doc.meta ~= nil
                                     and doc.meta.book ~= nil)
  if doc ~= nil then
    read(doc.meta)
  end
end

local function names()
  return order
end

local function title(name)
  return titles[name] or DEFAULT_TITLE
end

local function default()
  return order[1]
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
      qi_core.warn(('%s="%s" on %s names a second index, and this output has one index only, so the mark is indexed in that one index instead; more than one index prints in a single HTML document today'):format(INDEX_ATTR, value, context))
    end
    return order[1]
  end
  return name
end

-- The same for a placement marker. A separate call rather than a shared one
-- with a composed noun: the message-distinctness scan reads the string
-- literals INSIDE a `warn()` call, so a message built elsewhere and handed in
-- is text no such scan can see.
local function marker_index(value, report)
  local name = declared_for(value)
  if name == nil then
    if value ~= nil and report then
      qi_core.warn(('%s="%s" on an index placement marker names no index this document declares; declare it under %s: in the metadata, or the marker places the first index the document has'):format(INDEX_ATTR, value, INDEXES_KEY))
    end
    return order[1], false
  end
  if folded and name ~= order[1] then
    if report and builds_index() then
      qi_core.warn(('%s="%s" on an index placement marker names a second index, and this output has one index only, so the marker places that one index instead; more than one index prints in a single HTML document today'):format(INDEX_ATTR, value))
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
M["UNNAMED"] = UNNAMED
M["reset"] = reset
M["read"] = read
M["names"] = names
M["title"] = title
M["default"] = default
M["is_declared"] = is_declared
M["folds"] = folds
M["builds_index"] = builds_index
M["declared_for"] = declared_for
M["mark_index"] = mark_index
M["marker_index"] = marker_index
M["section_id"] = section_id

return M
