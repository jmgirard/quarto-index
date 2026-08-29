-- Which indexes a document has, in the order they print, and which one a mark
-- or a placement marker that names none belongs to.
--
-- Read once per document from the `indexes:` metadata, before any pass sees a
-- mark: every accumulator downstream is keyed by the index a mark files in, so
-- the table has to be settled before the first mark is recorded. That is why
-- the per-document reset is a `Pandoc` hook rather than an element one, and
-- why this module's `reset` takes the document.

local qi_core = require("./core")
local qi_languages = require("./languages")

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
-- always printed, and the key the language table holds its own heading under.
-- The English word stays here rather than in that table for the reason the
-- table's own comment gives: it is not a translation, it is the word this
-- extension has printed since its first release.
local DEFAULT_TITLE = "Index"
local TITLE_KEY = "title"

-- The metadata key an author writes the reader-facing text under, and the
-- five keys one map may set. A nested map rather than fields beside `title:`
-- because a flat `see:` would spell the mark attribute `see=` one
-- indentation level away, where the same word names a cross-reference TARGET
-- rather than the word printed in front of one (D-036). The map's name says
-- what kind of value its keys hold, so the keys keep matching the attribute
-- names without inheriting their meaning.
--
-- Three of the five are words -- the group heading and the two
-- cross-reference words -- and two are punctuation: `separator`, the mark
-- between a term and its locators and between one locator and the next, and
-- `xref-separator`, the mark between two cross-references. Punctuation joins
-- the same map rather than getting one of its own because it resolves on the
-- same ladder the words do, an index's own map and then the document's, and a
-- second map would be a second syntax for one question (M58).
--
-- `index-labels` and not the bare `labels` D-036 first chose: `labels:` at a
-- document's top level is QUARTO's own key, and it puts nine title-block
-- strings of its own there -- `abstract`, `authors`, `keywords` and the rest --
-- in every document, written or not. Reading it would mean reporting nine
-- unknown keys on a document that declared nothing, and would leave a future
-- Quarto label spelled `see` silently setting a word this extension prints
-- (D-039). The same name is used at both levels, though only the top one
-- collides, so an author writes one key rather than two.
--
-- The keys are listed rather than derived from the sites that print them:
-- `symbols` is the HTML back-end's group heading, `see` and `see-also` are the
-- cross-reference kinds, and the two separators are punctuation `entry_inlines`
-- writes between an entry's parts -- and a module below this one cannot ask
-- any of them what it prints. What this module owns is which keys are writable
-- and what an unusable one does; the ENGLISH word or ASCII mark each falls
-- back to stays at the site that has always printed it, so nothing printed
-- acquires a second copy.
local LABELS_KEY = "index-labels"
local LABEL_KEYS = { "symbols", "see", "see-also", "separator", "xref-separator" }
local LABEL_KEY_SET = {}
for _, key in ipairs(LABEL_KEYS) do
  LABEL_KEY_SET[key] = true
end

-- The characters this extension counts as printing nothing. A label value made
-- only of these is a value a reader cannot read, exactly as an empty one is,
-- and it is refused for the same reason -- `see-also: "&nbsp;"` printed an
-- emphasized non-breaking space in front of a target, so the reader saw a
-- cross-reference with no word saying what kind it was (M56 review F3).
--
-- Written out here as the one site that says what "blank" means, rather than
-- derived from a character property: the Lua Pandoc embeds has no Unicode
-- category tables, and `%s` follows the C locale, which decides nothing about
-- U+2007 on one machine and something else on another. Spelled with `\u{}`
-- escapes so this source file stays ASCII.
--
-- ASCII space and tab are on the list for completeness rather than for reach:
-- Pandoc parses a metadata value holding only those to empty inlines, so they
-- arrive as the empty string and are refused a line earlier.
local BLANKS = {
  "\u{0009}", "\u{000A}", "\u{000D}", "\u{0020}", -- tab, newline, return, space
  "\u{00A0}",                                     -- no-break space
  "\u{00AD}",                                     -- soft hyphen
  "\u{2000}", "\u{2001}", "\u{2002}", "\u{2003}", -- en quad, em quad, en space, em space
  "\u{2004}", "\u{2005}", "\u{2006}",            -- three-, four- and six-per-em space
  "\u{2007}", "\u{2008}", "\u{2009}", "\u{200A}", -- figure, punctuation, thin, hair space
  "\u{200B}", "\u{200C}", "\u{200D}",            -- zero-width space, non-joiner, joiner
  "\u{2028}", "\u{2029}",                        -- line separator, paragraph separator
  "\u{202F}",                                     -- narrow no-break space
  "\u{205F}",                                     -- medium mathematical space
  "\u{2060}",                                     -- word joiner
  "\u{3000}",                                     -- ideographic space
  "\u{FEFF}",                                     -- zero-width no-break space (byte-order mark)
}
local BLANK_SET = {}
for _, blank in ipairs(BLANKS) do
  BLANK_SET[blank] = true
end

-- Does this string hold a character a reader can see? The string is walked one
-- UTF-8 character at a time -- a lead byte and the continuation bytes after it
-- -- rather than byte by byte, since every blank above outside ASCII is two or
-- three bytes and a byte-wise test would call the second byte of one a
-- character of its own.
local function has_visible(text)
  for character in text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
    if not BLANK_SET[character] then
      return true
    end
  end
  return false
end

-- How a report names the level an `index-labels:` map was written at. The
-- document level is one phrase; an index's own names the index, which is the
-- only thing that tells two per-index maps apart in a log.
local DOCUMENT_LEVEL = "in this document's metadata"

local function index_level(name)
  return ('in the entry declaring the index named "%s"'):format(name)
end

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
-- The words an author declared, per level: the document's own map, and one map
-- per index that wrote one. Two cells rather than one keyed by index name,
-- because the document level applies to every index and the unnamed index's
-- name is the empty string -- a single table would have to reserve a key no
-- index can have, and this way the nearest-wins lookup below is two reads.
local doc_labels = {}
local index_labels = {}
-- The row of the shipped language table this document's `lang:` resolves to,
-- or nil where it resolves to none. One cell rather than a lookup per word:
-- the resolution is a fact about the document, settled once when the metadata
-- is read, and a per-word lookup would re-answer it for every entry printed.
local language_words = nil

-- One `index-labels:` map, at whichever level it was written. Returns the
-- words it usably sets, or nil where it sets none.
--
-- The discipline is `read_declaration`'s: anything unusable is reported and
-- falls back, never half-installed. The unit that falls back is the KEY, as
-- the unit there is the entry -- a map whose `see:` is empty still sets its
-- `symbols:`, exactly as an index whose `title:` is empty still declares its
-- name. What falls back falls to the next level out and then to the English
-- word the printing site has always used, so an unusable map can only ever
-- leave a reader with the words this extension printed before it was written.
local function read_labels(value, where)
  if value == nil then
    return nil
  end
  if pandoc.utils.type(value) ~= "table" then
    qi_core.warn(("%s: %s is not a map of label keys to the words to print; it sets no word, so each word falls back to the next level it is written at and then to the English one"):format(LABELS_KEY, where))
    return nil
  end
  -- The unknown keys are collected and sorted before any is reported: `pairs`
  -- gives no order, so two unknown keys in one map would otherwise be
  -- reported in whichever order the table happened to hold them, and a log is
  -- something a check reads.
  local unknown = {}
  for key in pairs(value) do
    if not LABEL_KEY_SET[key] then
      unknown[#unknown + 1] = key
    end
  end
  table.sort(unknown)
  for _, key in ipairs(unknown) do
    qi_core.warn(('%s: %s sets the key "%s", which names no word this extension prints; the keys are %s, so this key sets nothing'):format(LABELS_KEY, where, key, table.concat(LABEL_KEYS, ", ")))
  end
  local words = {}
  for _, key in ipairs(LABEL_KEYS) do
    if value[key] ~= nil then
      -- A key whose own value is a map or a list, before the value is
      -- stringified: `pandoc.utils.stringify` joins a nested map's leaf values
      -- into one string, so over-indenting the whole map by one level used to
      -- install "siehesiehe auch" as a printed word with nothing said (M56
      -- review F11). The shape the author wrote is named back to them, since
      -- the two mistakes are written differently and are fixed differently.
      local shape = pandoc.utils.type(value[key])
      if shape == "table" or shape == "List" then
        qi_core.warn(('%s: %s gives the key "%s" a value written as a %s, where one word belongs; it sets no word, so that word falls back to the next level it is written at and then to the English one'):format(LABELS_KEY, where, key, shape == "table" and "map" or "list"))
      else
        local word = pandoc.utils.stringify(value[key])
        -- One report for the empty value and the blank-only one: they are the
        -- same fact about the same reader, and the empty report's own words
        -- always described both.
        if not has_visible(word) then
          qi_core.warn(('%s: %s gives the key "%s" a value with no character a reader can see; that word falls back to the next level it is written at and then to the English one'):format(LABELS_KEY, where, key))
        else
          words[key] = word
        end
      end
    end
  end
  if next(words) == nil then
    return nil
  end
  return words
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
-- The one further message a refused `indexes:` entry that also wrote an
-- `index-labels:` map draws. Every refusal below returns before the
-- `read_labels` call at the foot of `read_declaration`, so without this an
-- author who repeated an index name and wrote a correct label map in the
-- second entry was told about the name and nothing about the map (M56 review
-- F8). The map is not read: the entry declares no index, so there is no index
-- for its words to be the words of, and reporting the map's own mistakes
-- beside a declaration that has to be fixed first is noise.
--
-- One call site reached from every refusal branch rather than a message per
-- branch: the four emitted lines differ by the entry position they name, which
-- is what tells them apart in a log, and one literal is one message the
-- distinctness scan can read whole at the site that emits it.
local function report_dropped_labels(item, position)
  if item[LABELS_KEY] ~= nil then
    qi_core.warn(("entry %d of the %s: metadata also writes an %s: map, which sets no word: the entry declares no index, so there is nothing for that map to set the words of"):format(position, INDEXES_KEY, LABELS_KEY))
  end
end

local function read_declaration(item, position, kept, seen)
  if pandoc.utils.type(item) ~= "table" then
    qi_core.warn(("entry %d of the %s: metadata is not a map with a %s: and a %s:; it declares no index, so marks naming one are filed in the first index this document does declare"):format(position, INDEXES_KEY, NAME_FIELD, TITLE_FIELD))
    return
  end
  if item[NAME_FIELD] == nil then
    qi_core.warn(("entry %d of the %s: metadata has no %s:, so there is nothing for a mark to name it by and it declares no index"):format(position, INDEXES_KEY, NAME_FIELD))
    report_dropped_labels(item, position)
    return
  end
  local name = pandoc.utils.stringify(item[NAME_FIELD])
  if name == UNNAMED then
    qi_core.warn(("entry %d of the %s: metadata has an empty %s:, which no mark can name, so it declares no index"):format(position, INDEXES_KEY, NAME_FIELD))
    report_dropped_labels(item, position)
    return
  end
  if not name:match(NAME_SHAPE) then
    qi_core.warn(('entry %d of the %s: metadata declares the name "%s", which cannot be a section id a `#id` selector names; a name holds ASCII letters, digits, hyphen and underscore and begins with a letter, so this entry declares no index'):format(position, INDEXES_KEY, name))
    report_dropped_labels(item, position)
    return
  end
  if seen[name] then
    qi_core.warn(('entry %d of the %s: metadata declares the name "%s" a second time; one name is one index, so this entry is ignored and the first declaration of that name is the one that prints'):format(position, INDEXES_KEY, name))
    report_dropped_labels(item, position)
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
  kept[#kept + 1] = { name = name, title = title,
                      labels = read_labels(item[LABELS_KEY], index_level(name)) }
end

-- Read the declaration. Anything unusable leaves the document with the one
-- unnamed index it would have had without the key at all, which is exactly
-- today's behavior -- never with no index to file marks in, and never with a
-- partly installed declaration.
local function read(meta)
  -- Read BEFORE the declaration and outside its early returns: a document that
  -- declares no index is exactly the document most likely to write `index-labels:`
  -- at all, since it has no index entry to write one in (D-036).
  -- The language table, before anything else the metadata says: the untitled
  -- heading installed below is one of its words, and it has to be in place
  -- before a declaration can replace the whole title table.
  language_words = qi_languages.resolve(meta and meta.lang or nil)
  if language_words ~= nil and language_words[TITLE_KEY] ~= nil then
    -- ONLY the heading an undeclared document falls back to. A declared index
    -- with no `title:` is headed by its own `name`, which is text its author
    -- wrote, and the `qi_core.empty(titles)` below throws this cell away the
    -- moment a declaration takes (D-038). That is also why no word of this
    -- table can reach LaTeX: `\makeindex[title={...}]` is written only when
    -- `is_declared()`, and this heading exists only when it is not.
    titles[UNNAMED] = language_words[TITLE_KEY]
  end
  local words = read_labels(meta and meta[LABELS_KEY] or nil, DOCUMENT_LEVEL)
  if words ~= nil then
    for key, word in pairs(words) do
      doc_labels[key] = word
    end
  end
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
    index_labels[entry.name] = entry.labels
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
  qi_core.empty(doc_labels)
  qi_core.empty(index_labels)
  language_words = nil
  declared = false
  order[1] = UNNAMED
  titles[UNNAMED] = DEFAULT_TITLE
  if doc ~= nil then
    read(doc.meta)
  end
end

local function names()
  return order
end

-- The heading this index's section carries: the title its author declared, or
-- the neutral one for a document that declared nothing.
local function title(name)
  return titles[name] or DEFAULT_TITLE
end

-- The text this index prints for `key`: the nearest one an author declared --
-- the index's own map first, then the document's -- and `fallback` where
-- neither level names it. Nearest wins KEY BY KEY rather than map by map, so a
-- per-index map resetting one key keeps the document's others (D-036).
--
-- Below both author levels sits the shipped table for the document's `lang:`,
-- and below that the English word: an author who wrote nothing gets their own
-- language, and an author who wrote one word keeps the table's others
-- (D-035). Per key here too -- a language covering three of the four words
-- leaves the fourth to English rather than dropping its whole row. The table
-- holds words only, so a punctuation key falls straight past it to `fallback`
-- on every document: no row localizes the separators (M58).
--
-- `fallback` is the English word or ASCII mark the calling site has always
-- printed, passed in rather than held here: this module owns which keys exist
-- and what an unusable one does, and what is printed stays where it is
-- printed.
local function label(name, key, fallback)
  local mine = name ~= nil and index_labels[name] or nil
  if mine ~= nil and mine[key] ~= nil then
    return mine[key]
  end
  if doc_labels[key] ~= nil then
    return doc_labels[key]
  end
  if language_words ~= nil and language_words[key] ~= nil then
    return language_words[key]
  end
  return fallback
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
-- a document that declares nothing, or declares one index.
local function scope_phrase(name, outer)
  -- A caller with no index in hand -- a finding whose message names no scope
  -- at all -- gets the outer word back untouched, so this is safe to call on
  -- every finding rather than only on the ones that print a scope.
  if name == nil or not declared or #order < 2 then
    return outer
  end
  return ('index "%s"'):format(name)
end

local function is_declared()
  return declared
end

-- The index a mark naming `value` belongs to: the one it names, or the default
-- where it names none. A value naming no declared index is reported in EVERY
-- format, like every other judgement about what the author wrote -- a mark
-- filed somewhere other than where its author said is a defect wherever the
-- document is rendered.
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
  return name
end

-- The index a mark or a marker names: the declared index it names, or the
-- default where it names none, or names one this document never declared.
-- Silent, because the reports about what the author wrote are drawn once by
-- the emitting pass; this is for the caller that only has to know which index
-- the value resolves to.
local function authored_index(value)
  return declared_for(value) or order[1]
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
    return order[1]
  end
  return name
end

-- The id the section for this index carries. A document that declared nothing
-- keeps the bare name it has always had, so its readers' links still resolve;
-- a declared index is named after itself rather than numbered, so a link keeps
-- pointing at the same index when the author reorders the declaration.
-- Whether the id is actually free is `mint_section_id`'s question, not this
-- one's: this says what to ask for.
local function section_id(name)
  if not declared then
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
M["TITLE_KEY"] = TITLE_KEY
M["LABELS_KEY"] = LABELS_KEY
M["LABEL_KEYS"] = LABEL_KEYS
M["NAME_SHAPE"] = NAME_SHAPE
M["UNNAMED"] = UNNAMED
M["reset"] = reset
M["read"] = read
M["names"] = names
M["title"] = title
M["label"] = label
M["default"] = default
M["scope_phrase"] = scope_phrase
M["is_declared"] = is_declared
M["declared_for"] = declared_for
M["authored_index"] = authored_index
M["mark_index"] = mark_index
M["marker_index"] = marker_index
M["section_id"] = section_id

return M
