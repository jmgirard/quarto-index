-- The LaTeX back-end: turning derived levels into `\\index{...}` commands, and
-- the contested-key bookkeeping that decides which shape a key gets.
--
-- The two `emitted` flags below are read by the Pandoc pass, which writes the
-- preamble: a command is defined only in a document that uses it.

local qi_core = require("./core")
local qi_levels = require("./levels")
local qi_sortkeys = require("./sortkeys")

local M = {}

-- Build the `\index{...}` argument from literal levels, joining with the
-- unquoted `!` that makeindex reads as a level separator. With a sort key,
-- each level becomes makeindex's own `sortkey@printed` form: the `@` here is
-- written by this back-end and so is the ONE `@` that stays unquoted, while
-- every `@` the author wrote is still quoted by qi_levels.escape_level (qi_core.LATEX_LITERAL).
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
-- qi_levels.clamp_levels warns about the fold, and a second call would report it twice.
-- `report` is passed through for the same reason: the pass that decides which
-- keys are contested calls this before anything is emitted, and must not
-- report a fold the emitting pass will report.
--
-- `fold` (optional) is a contested key's cross-references, already rendered for
-- the printed field: it is appended to the LAST level's printed half, and that
-- level then always carries a sort field — its own text — so the entry files
-- exactly where it filed before and only what it prints changes. It is applied
-- here, from the levels, rather than by taking the built argument apart again:
-- an author's own `@` is makeindex-quoted inside a level, so "the first `@`"
-- is not something a pattern over the finished string can find.
local function index_argument(levels, sort, context, report, fold, written)
  local clamped = qi_levels.clamp_levels(levels, context, report, written)
  local keys = qi_sortkeys.clamp_sort(sort)
  local parts, filing = {}, {}
  for i, level in ipairs(clamped) do
    local printed = qi_levels.escape_level(level)
    if fold ~= nil and i == #clamped then
      -- A sort field is unavoidable here — the printed half now carries the
      -- folded cross-reference, and without a key the entry would file under
      -- that whole string. What it files under is still decided by the SAME
      -- comparison the uncontested branch below makes, so contesting a key
      -- moves nothing: a key that merely repeats its level declares nothing,
      -- and the level the entry files under is then the clamped text, join
      -- and all, exactly as it is when no cross-reference is folded in.
      local key = level
      if keys ~= nil and keys[i] ~= nil and keys[i] ~= levels[i] then
        key = keys[i]
      end
      parts[#parts + 1] =
        qi_levels.escape_level(key) .. "@" .. printed .. ", " .. fold
      filing[i] = key
      goto continue
    end
    -- Compared against the level the key was ALIGNED with, not against the
    -- clamped text: where levels were folded, the third clamped level is a
    -- join of several and never equals the key resolved for the third level,
    -- so comparing against it emits a sort field on every folded entry —
    -- filing it under the third level's own printed text, which is what the
    -- absence of a sort field already means.
    if keys ~= nil and keys[i] ~= nil and keys[i] ~= levels[i] then
      parts[#parts + 1] = qi_levels.escape_level(keys[i]) .. "@" .. printed
      filing[i] = keys[i]
    else
      parts[#parts + 1] = printed
      -- No sort field emitted, so the index tool files this level under the
      -- text it prints — the CLAMPED text, which is not always the level the
      -- key was compared against.
      filing[i] = level
    end
    ::continue::
  end
  return table.concat(parts, "!"), qi_levels.levels_key(clamped),
         qi_levels.levels_key(filing), clamped
end

-- ---------------------------------------------------------------------------
-- Contested keys.
--
-- makeindex refuses to reconcile two marks that share a key and a printed page
-- but carry different encapsulations. It does not reject them: it logs
-- `Conflicting entries` to the `.ilg`, exits 0, and writes a correct `.ind`.
-- QUARTO is what fails the render, on a regex over that transcript
-- (`findIndexError`, matching any warning continuation line, whatever the exit
-- code) — so the warning is not benign here however benign makeindex finds it,
-- and a marked term still breaks the document, which IP2 forbids. This
-- mechanism is stated exactly rather than as "makeindex rejects it" because
-- the next design decision in this file would otherwise inherit the wrong one:
-- M20 planned against a makeindex-in-isolation probe, read its exit 0 as
-- safety, and shipped a render-breaking emission (D-007, RR01).
-- Page numbers do not exist here, so the pair cannot be kept apart; what CAN be
-- done is to stop emitting rival encapsulations at all for such a key, by
-- folding its cross-references into the entry's printed text, where the index
-- tool reads them as part of the term rather than as a rival encapsulation.
--
-- Which keys are contested takes the whole document to know, so it is settled
-- in a pass of its own (CollectKeys) before anything is emitted. Both passes
-- go through latex_plan, so the pass that decides and the pass that emits
-- cannot drift on what a mark's key or surviving targets are (D-003 records
-- why repairing this sits inside GP2 rather than trading against it).
-- ---------------------------------------------------------------------------

-- Emitted argument -> what the document's marks do with that key: whether any
-- of them is a plain locator mark, and every distinct cross-reference target
-- written on it, in a fixed order. Module-level, like the other accumulators.
local contested_keys = {}
M["xref_list_emitted"] = false
-- Likewise for the typeset-time channel's commands.
M["principal_emitted"] = false

-- Keys some mark of which carries a principal mention, each mapped to the
-- ordinal EVERY locator mark of that key encapsulates with. Keyed on the same
-- emitted argument `contested_keys` is, so the pass that assigns an ordinal
-- and the pass that emits it cannot drift on what a mark's key is; a contested
-- key's marks emit a folded argument, but they look their ordinal up under the
-- unfolded one, exactly as they look their contestation up under it.
--
-- The ordinal is what makes per-locator styling possible at all: makeindex
-- rejects two locators of one key on one page whose encapsulations differ by
-- any byte, so the ONE conflict-free discipline is an encapsulation identical
-- across a key's locators — which then carries no per-locator information, and
-- the role has to travel on the second channel qi_core describes (D-007).
-- Assigned in document order by the pass that already collects keys, so the
-- ordinal is a property of the document rather than of a traversal order.
-- Module-level, like the other accumulators.
local principal_keys = {}
local principal_ordinals = 0

-- Called once per principal mark; idempotent per key, so a term discussed
-- principally in two places (which the author is told about nowhere, since it
-- is not an error — the later registration simply adds a second emphasized
-- page) still has one ordinal.
local function record_principal(source)
  if principal_keys[source] == nil then
    principal_ordinals = principal_ordinals + 1
    principal_keys[source] = qi_core.LOCATOR_ID_PREFIX .. principal_ordinals
  end
  return principal_keys[source]
end

-- The ordinal a key's locator marks encapsulate with, or nil for a key no mark
-- of which is principal — which emits exactly what it emitted before this
-- milestone, so a document with no principal mention is byte-identical.
local function principal_ordinal(source)
  return principal_keys[source]
end
-- Likewise: the both-targets command is defined only in a document that uses
-- it, so a document without one gets nothing extra in its preamble.
M["xref_both_emitted"] = false

-- One mark's LaTeX shape, from levels the caller has already derived. `report`
-- follows the convention the rest of the file uses: only the emitting pass
-- says anything, so a fold is reported once however many passes read the mark.
-- `entry_written` (optional) is the depth the author wrote the ENTRY at, before
-- the empty-level drop; each target carries its own in `written_depth`. Both
-- exist only so the two fold reports can name the count the author can find in
-- their source (D-006); neither changes a level, a key or a comparison. The
-- entry one is NOT called `written`: that name is taken inside the loop below
-- for a target's pre-fold spelling, which is a level list and not a count.
local function latex_plan(levels, sort, xrefs, context, report, fold,
                          entry_written)
  local source, printed_path, filing_path, clamped =
    index_argument(levels, sort, context, report, fold, entry_written)
  -- The self-target comparison against what THIS back-end prints. The
  -- format-neutral pass ran on the levels the author wrote; here the fold has
  -- already rewritten them, so an entry can print a path the author never
  -- spelled and a target spelling that path is a self-reference the first pass
  -- could not see. It lives here, and not beside the first pass, because the
  -- three-level ceiling is a property of this back-end alone: HTML has none,
  -- so the same document keeps the target there, and a format with no index
  -- back-end never reaches this line. Neither side carries an empty level, for
  -- the same reason neither does in the first pass.
  local printed_key = qi_levels.levels_key(clamped)
  local kept = {}
  for _, xref in ipairs(xrefs) do
    -- The target is folded by the rule that folds an entry. This back-end's
    -- ceiling is a property of the level path, not of the slot the author
    -- wrote it in, and a target left unfolded names a path the printed index
    -- does not contain — the cross-reference then answers to nothing a reader
    -- can find (D-005). `clamp_levels` reports in an entry's words, so the
    -- fold is announced here instead, once, in words that fit a target; the
    -- clamp itself is asked to stay silent. Idempotent under the second call
    -- a contested key makes: a list already at or under the ceiling comes back
    -- unchanged, and `written` survives it.
    local written = xref.written or xref.levels
    local folded = qi_levels.clamp_levels(xref.levels, context, false)
    if qi_levels.levels_key(folded) == printed_key then
      if report then
        -- The folded path is quoted because the author never wrote it: it is
        -- what their entry prints once the back-end has folded it, and a report
        -- naming only what they typed would describe a match they cannot see.
        qi_core.warn(("%s= on %s names the folded path this entry prints (%s); the "
              .. "back-end stores %d levels, and the fold made the target a "
              .. "cross-reference to itself, so it is dropped and the term is "
              .. "indexed as usual")
             :format(xref.kind.attr, context, printed_path, qi_levels.MAX_LEVELS))
      end
    else
      -- Reported only for a target that SURVIVES the fold. A target the fold
      -- turns into a self-reference is dropped by the branch above and says so
      -- there; announcing the path it now points at as well would hand the
      -- author two reports contradicting each other about one target — the
      -- defect this milestone exists to remove, in a new shape (review F1).
      -- The path is quoted in the `!` spelling every other report uses, which
      -- is what an author searches their source for; what the reader sees is
      -- the same levels joined as a target, and the message does not claim
      -- otherwise (review F8).
      if report and #xref.levels > qi_levels.MAX_LEVELS then
        qi_core.warn(("%s= on %s names a path %s; the back-end stores %d, so the target is folded exactly as an entry is and now names \"%s\", the path the entry it points at prints"):format(xref.kind.attr, context, qi_levels.depth_phrase(#xref.levels, xref.written_depth), qi_levels.MAX_LEVELS, qi_levels.levels_key(folded)))
      end
      kept[#kept + 1] = { kind = xref.kind, levels = folded, written = written,
                          written_depth = xref.written_depth }
    end
  end
  return source, printed_path, filing_path, kept, clamped
end

-- The encapsulation one mark would put on its key: the empty string for a
-- plain locator mark, `\see`/`\seealso` for a single target, and the
-- both-targets command for a mark carrying two.
--
-- A mention's ROLE is deliberately absent from this, and so is the locator
-- encapsulation that now travels for it. Not because a styled locator is no
-- rival — it is exactly a rival, and a plain one beside it on one page is the
-- render-breaking pair above; an earlier version of this comment said
-- otherwise and was wrong (D-007). It is absent because there is nothing left
-- for contestation to arbitrate: a key carrying a principal mention gives
-- EVERY one of its locators the same encapsulation, so its marks cannot differ
-- from each other whatever contestation decides, and a key carrying none emits
-- what it always did. Routing the role through here would instead make an
-- ordinary document a contested key, and with no cross-references to fold the
-- repair would end its entry on a dangling comma. Shared by the pass that
-- decides which keys are contested and by the pass that emits, because
-- contestation is a fact about these exact strings — makeindex rejects two
-- marks on one key and page whose encapsulations DIFFER, and folds together
-- two whose encapsulations agree.
local function mark_encap(xrefs)
  if #xrefs == 0 then
    return ""
  end
  if #xrefs == 1 then
    return xrefs[1].kind.command ..
      "{" .. qi_levels.target_argument(xrefs[1].levels) .. "}"
  end
  local args = {}
  for _, xref in ipairs(xrefs) do
    args[#args + 1] = "{" .. qi_levels.target_argument(xref.levels) .. "}"
  end
  return qi_core.XREF_BOTH_COMMAND .. table.concat(args)
end

-- Record what one mark does with its key: the encapsulation it would emit, and
-- its targets. Targets are kept in a fixed order — `see` before `see also` as
-- print convention has it, and first appearance within a kind — because every
-- mark of a contested key must emit the SAME text or the index tool sees two
-- entries where the author wrote one.
local function record_contest(source, printed, xrefs)
  local seen = contested_keys[source]
  if not seen then
    seen = { plain = false, encaps = {}, distinct = 0, xrefs = {}, listed = {},
             -- The entry path this key PRINTS, carried alongside the emitted
             -- argument so the report below can name what the author wrote.
             -- The argument itself is the back-end's composition: an entry
             -- with a sort key spells it `key@printed`, which is not a string
             -- the author can search their source for. Every mark of one key
             -- emits one argument and derives this path from the same clamped
             -- levels, so whichever mark arrives first records the same value.
             printed = printed }
    contested_keys[source] = seen
  end
  local encap = mark_encap(xrefs)
  if not seen.encaps[encap] then
    seen.encaps[encap] = true
    seen.distinct = seen.distinct + 1
  end
  if #xrefs == 0 then
    seen.plain = true
  end
  for _, xref in ipairs(xrefs) do
    local id = xref.kind.attr .. "\0" .. qi_levels.levels_key(xref.levels)
    if not seen.listed[id] then
      seen.listed[id] = true
      seen.xrefs[#seen.xrefs + 1] = xref
    end
  end
end

-- Is this key marked in more than one way? Counted in ENCAPSULATIONS a mark
-- would emit, never in targets: one mark carrying both attributes emits a
-- single command and contests nothing, however many targets it names, while
-- two marks carrying the same target emit the same string and are what the
-- index tool folds together by itself.
local function is_contested(seen)
  return seen ~= nil and seen.distinct > 1
end

-- A contested key's cross-references, rendered for the entry's PRINTED field.
-- `\see`/`\seealso` are imakeidx's own two-argument commands and discard the
-- second, so an explicit empty page argument is what makes them usable outside
-- the encap channel — and rendering them here rather than through a second
-- command of our own is what keeps the folded form and the encapsulated form
-- from drifting in how they print a target. `\see{A}{}; \seealso{B}{}`
-- expands to exactly what qi_core.XREF_BOTH_COMMAND prints, so a both-attributes mark
-- reads the same whether its key is contested or not.
local function fold_xrefs(seen)
  local parts = {}
  for _, kind in ipairs(qi_core.XREF_KINDS) do
    for _, xref in ipairs(seen.xrefs) do
      if xref.kind.attr == kind.attr then
        parts[#parts + 1] = "\\" .. kind.command ..
          "{" .. qi_levels.target_argument(xref.levels) .. "}{}"
      end
    end
  end
  return table.concat(parts, "; ")
end

-- Exported through the bracket form, never `M.NAME = NAME`: the source
-- scans take the FIRST match for `NAME =` over the whole source set, and
-- the M16-AC3 probe relocates a definition into another file — a plain
-- `NAME =` line left behind here would then mask it (M16 review F3).
M["index_argument"] = index_argument
M["contested_keys"] = contested_keys
M["latex_plan"] = latex_plan
M["mark_encap"] = mark_encap
M["record_contest"] = record_contest
M["is_contested"] = is_contested
M["record_principal"] = record_principal
M["principal_ordinal"] = principal_ordinal
M["principal_keys"] = principal_keys
M["fold_xrefs"] = fold_xrefs

return M
