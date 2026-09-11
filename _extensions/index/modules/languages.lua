-- The words this extension prints for itself, per document language.
--
-- Three of the four -- the two cross-reference labels and the heading over
-- entries that file under no letter -- are printed by the HTML and EPUB
-- back-ends. The fourth is the heading an index gets when the document
-- declared no index at all. The LaTeX back-end prints none of them: it emits
-- `\see`, `\seealso` and an untitled `\printindex`, and babel supplies the
-- words from the document's own language, so a PDF has followed `lang:` since
-- the first release and the other two back-ends never could. This module is
-- what lets them (D-035).
--
-- Nothing here is copied from another project. Every string was checked
-- against two references of different kinds -- one typographic or editorial,
-- one lexical -- and re-typed. The ledger naming both references for every
-- word, and the one word it withholds, is
-- `cairn/references/index-words-by-language.md`.
--
-- This module requires nothing but `core`, and only `indexes` requires it: the
-- table is consulted BELOW an author's own `index-labels:` and ABOVE the
-- English word the printing site has always held, which is the order
-- `indexes.label` implements.

local M = {}

-- The table. A row holds two things, kept apart. `words` holds the keys an
-- author writes under `index-labels:` -- `symbols`, `see` and `see-also` --
-- spelled the same so one lookup serves both surfaces. `title` is NOT such a
-- key: an author who wants a particular heading writes `title:`, which wins
-- outright, so it names only the default an undeclared document falls back to
-- (D-038). It sits outside `words` because `indexes.label` looks up whatever
-- key it is handed in that table, and a label key spelled `title` would
-- otherwise print the index heading (M093).
--
-- Keyed by the lowercased BCP-47 tag the row covers -- a primary
-- subtag here, since no row covers a region -- and holding only the words that
-- ship. A word a row omits is not a gap to report: it is a word two references
-- did not agree on, and it falls through to the English one, which is why a
-- partly covered language is an expected state and not a defect (D-035).
--
-- There is no `en` row. English is not a translation this table supplies; it is
-- the word each printing site has always held, and a second copy here would be
-- a second place to correct it.
--
-- German ships three words and no `symbols`: Unicode's own locale data heads
-- that category `Zeichen` while a German dictionary's word for a symbol is
-- `Symbol`, and this repo does not pick between two strings in a language it
-- cannot read (ledger row W-DE4).
local WORDS = {
  es = {
    words = {
      ["symbols"] = "Símbolos",
      ["see"] = "véase",
      ["see-also"] = "véase también",
    },
    title = "Índice alfabético",
  },
  fr = {
    words = {
      ["symbols"] = "Symboles",
      ["see"] = "voir",
      ["see-also"] = "voir aussi",
    },
    title = "Index",
  },
  de = {
    words = {
      ["see"] = "siehe",
      ["see-also"] = "siehe auch",
    },
    title = "Index",
  },
  it = {
    words = {
      ["symbols"] = "Simboli",
      ["see"] = "vedi",
      ["see-also"] = "vedi anche",
    },
    title = "Indice analitico",
  },
}

-- Is this a well-formed BCP-47 language tag? Only well-formedness, never
-- whether the tag names a real language: a tag naming a language this table
-- omits is a `miss`, which is a normal outcome, and refusing to tell the two
-- apart would collapse the four outcomes `resolve` names.
--
-- The primary subtag is two to eight letters; every subtag after it is one to
-- eight letters or digits. Letters and digits are the ASCII ranges, written
-- out, never `%a` or `%w`: those follow the C library's locale, and under a
-- locale that reads a byte above 0x7F as a letter, `lang: es-êê` resolved to
-- the Spanish row on one machine and to English on another (M093). BCP-47
-- tags are ASCII, so the ranges lose no tag.
--
-- `_` is read as a separator too, so `es_ES` resolves exactly as `es-ES` does.
-- Not a kindness: rendering `index-lang-malformed.qmd` with `lang: es_ES` to
-- LaTeX put `spanish` in the `\documentclass` options and `Tabla de contenidos`
-- in the preamble (observed 2026-08-29), so Quarto reads that spelling as
-- Spanish and localizes the whole document from it. Refusing it here would
-- leave the index the one part of that document still in English, which is the
-- split this table exists to close.
--
-- Nothing here reports anything. An author writes `lang:` for Quarto and did
-- not address this filter, so a value this filter cannot use leaves the index
-- in English and says nothing (IP2).
local function well_formed(tag)
  local first, subtags = true, 0
  for part in (tag .. "-"):gmatch("([^%-]*)%-") do
    subtags = subtags + 1
    if first then
      if not part:match("^[A-Za-z][A-Za-z][A-Za-z]?[A-Za-z]?[A-Za-z]?[A-Za-z]?[A-Za-z]?[A-Za-z]?$") then
        return false
      end
      first = false
    elseif not part:match("^[A-Za-z0-9][A-Za-z0-9]?[A-Za-z0-9]?[A-Za-z0-9]?[A-Za-z0-9]?[A-Za-z0-9]?[A-Za-z0-9]?[A-Za-z0-9]?$") then
      return false
    end
  end
  return subtags > 0
end

-- The row this document's language gets, and the outcome that produced it.
-- Returns nil for every outcome but a hit, so a caller never has to know which
-- token means "no words": `if row ~= nil` is the whole test, and the token is
-- for a check that wants to say WHICH miss it exercised. The four tokens:
--
--   exact      the tag names a row of the table
--   subtag     the tag's primary subtag does, where the whole tag did not
--   miss       a well-formed tag naming no row
--   malformed  no usable tag at all: absent, empty, or not a language tag
--
-- `malformed` and `miss` behave identically -- English, silently -- and are
-- still two tokens, because they are two different things for a check to say
-- it exercised.
--
-- `value` is the raw metadata value, not a string: this module does the
-- stringifying so that a `lang:` written as a list or a map -- neither of which
-- is a language tag -- reaches `well_formed` as the nonsense it is rather than
-- crashing a `:lower()` call on a table.
local function resolve(value)
  if value == nil then
    return nil, "malformed"
  end
  local tag = pandoc.utils.stringify(value)
  if tag == "" then
    return nil, "malformed"
  end
  tag = tag:lower():gsub("_", "-")
  if not well_formed(tag) then
    return nil, "malformed"
  end
  local row = WORDS[tag]
  if row ~= nil then
    return row, "exact"
  end
  local primary = tag:match("^([^%-]+)")
  if primary ~= tag then
    row = WORDS[primary]
    if row ~= nil then
      return row, "subtag"
    end
  end
  return nil, "miss"
end

-- Exported through the bracket form for the reason indexes.lua's own export
-- block states. One function only: the table and the well-formedness test are
-- this module's own workings, and an export nothing
-- reads is surface to keep in step for nobody (GP5).
M["resolve"] = resolve

return M
