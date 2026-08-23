-- Test-only. Never shipped: it lives under tests/ and is named by the three
-- state-reuse fixtures alone.
--
-- M26's oracle. Each fixture is rendered twice off one tree with this filter
-- in its list both times; the environment switch below is the only difference
-- between the two renders. Switched on, it drives a synthetic document through
-- the extension's own passes BEFORE the fixture reaches them, which is exactly
-- what a reused Lua state would do to the second document rendered in it. The
-- two renders' output and warnings must then still agree byte for byte.
--
-- The modules are found in `package.loaded`, never through `require`. A
-- `require` from this directory resolves to a different cache key than the
-- extension's own absolute one and hands back a SECOND copy of each module,
-- whose state nothing reads — the comparison would then pass with no reset
-- written at all. Quarto loads every filter chunk before running any pass, and
-- this filter is listed AFTER the extension, so its modules are already cached
-- here and the pollution lands before the fixture's first mark is seen.
local qi = {}
for key, value in pairs(package.loaded) do
  local name = tostring(key):match("/index/modules/([%a_]+)$")
  if name then qi[name] = value end
end
for _, name in ipairs({ "core", "passes", "marks", "latex", "sortkeys" }) do
  if qi[name] == nil then
    error("tests/state-pollute.lua: no loaded module named " .. name ..
          "; this filter must be listed AFTER the index extension, or it "
          .. "pollutes nothing and every comparison it backs passes vacuously")
  end
end

if os.getenv("QI_STATE_POLLUTE") ~= "1" then
  return {}
end

local function mark(text, attributes)
  return pandoc.Span({ pandoc.Str(text) },
                     pandoc.Attr("", { "index" }, attributes))
end

-- One synthetic document, built so that every cell it fills collides with what
-- one of the three fixtures produces on its own. The comment on each mark says
-- which cell its value is aimed at; a mark whose value matched the fixture's
-- would leave that cell's probe unable to tell a reset from its absence.
local marks = {
  -- range_verdicts: plants a verdict at the document's FIRST range position,
  -- which the rich fixture's refused range mark occupies with nothing planned.
  mark("Refused", { range = "open" }),
  -- range_found: an end the filter refuses, held as a finding and reported by
  -- whichever document draws the range reports next.
  mark("Refused", { range = "sideways" }),
  -- sort_keys: a key for a path the rich fixture marks without one.
  mark("Solo", { sort = "ZZZ" }),
  -- contested_keys: two cross-references and no plain mark on one key, which
  -- the rich fixture marks one way only. xref_list_emitted rides along, being
  -- set by exactly this shape.
  mark("Held", { see = "Nowhere" }),
  mark("Held", { ["see-also"] = "Elsewhere" }),
  -- marked_paths: the path the rich fixture's dangling cross-reference names,
  -- whose report a leaked path set silences.
  mark("Nowhere", {}),
  -- pending_xrefs: a target nothing indexes, carried into whichever document
  -- draws the dangling report next.
  mark("Orphan", { see = "Missing" }),
  -- clamped_paths: the printed path the rich fixture's four-level entry folds
  -- to, filed under a different key, which is the collision that gets reported.
  mark("Deep", { entry = "L1!L2!L3!L4", sort = "dsort" }),
  -- principal_keys and principal_ordinals: two principal mentions, so the
  -- registry hands the rich fixture's own key an ordinal that is not the first
  -- one, and the counter alone hands it a later one still.
  mark("Prior", { mention = "principal" }),
  mark("Pivot", { mention = "principal" }),
  -- xref_both_emitted: one mark carrying both cross-reference kinds.
  mark("Both", { see = "Nowhere", ["see-also"] = "Elsewhere" }),
  -- marks_seen, html_marks and range_at are filled by everything above; the
  -- mark-free fixture reads the first of them.
  mark("Extra", {}),
}

local blocks = {}
for _, span in ipairs(marks) do
  blocks[#blocks + 1] = pandoc.Para({ span })
end
local doc = pandoc.Pandoc(blocks)

-- Silenced for the length of the drive, and restored immediately after. The
-- synthetic document has warnings of its own, and they would land in the
-- polluted render's warning stream and nowhere else — a difference the
-- comparison would report while saying nothing about any accumulator. What
-- must survive into that stream is the fixture's OWN reports, changed by what
-- was left behind here.
local real_warn = qi.core.warn
qi.core.warn = function() end
local ok, err = pcall(function()
  doc = doc:walk({ Span = qi.passes.CollectSort })
  doc = doc:walk({ Span = qi.passes.CollectKeys })
  doc = doc:walk({ Span = qi.passes.CollectRanges })
  -- Called directly rather than through a walk: it is the document hook of the
  -- range pass, and `walk` visits a document's contents rather than the
  -- document itself.
  qi.passes.FinishRanges()
  doc = doc:walk({ Span = qi.passes.Span })
end)
qi.core.warn = real_warn
if not ok then
  error("tests/state-pollute.lua: the synthetic drive failed (" ..
        tostring(err) .. "), so nothing was polluted and every comparison it "
        .. "backs would pass vacuously")
end

return {}
