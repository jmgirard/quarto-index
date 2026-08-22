-- Book support: the per-chapter sidecar store and the one index the chapter
-- carrying the marker builds out of it.

local qi_core = require("./core")
local qi_html = require("./html")
local qi_levels = require("./levels")
local qi_marker = require("./marker")
local qi_marks = require("./marks")
local qi_sortkeys = require("./sortkeys")

local M = {}

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
  for _, mark in ipairs(qi_marks.html_marks) do
    local xrefs = {}
    for _, xref in ipairs(mark.xrefs) do
      xrefs[#xrefs + 1] = { attr = xref.kind.attr, levels = xref.levels }
    end
    marks[#marks + 1] =
      -- `context` is how a report names the mark — `entry="..."` or the term
      -- the author wrote. Derived where the mark was read and carried here,
      -- because the book's dangling-target report runs in another chapter's
      -- process, where the mark itself is long gone and only this record is
      -- left to name it.
      -- `range` is the end the AUTHOR wrote, never this chapter's verdict
      -- about it: a range opened here and closed two chapters on is unmatched
      -- in both, and only the record that says which end was written lets the
      -- chapter reading every record pair the two.
      { levels = mark.levels, xrefs = xrefs, anchor = mark.anchor,
        context = mark.context, role = mark.role, range = mark.range }
  end
  -- The chapter's DECLARED sort keys, one per printed level path, rather than
  -- a resolved key per mark. A mark's resolved key already has this chapter's
  -- fallbacks filled in, and a fallback is indistinguishable from a declared
  -- key once written down — so the book would read one chapter's fallback as
  -- a rival to another chapter's real key, and, being first in book order,
  -- let the fallback win.
  local sorts = {}
  for path, seen in pairs(qi_sortkeys.sort_keys) do
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
    qi_core.warn(("could not record index marks for %s (%s); this chapter's marks "
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
    -- Optional, and deliberately not a version bump (review F4): `context`
    -- is read by one warning and by nothing that reaches the index, so a
    -- record written before it existed is still a perfectly good record. The
    -- alternative — invalidating every stored chapter — costs an author their
    -- terms until the whole book is rendered again, which is a real loss
    -- traded for a warning that reads slightly better.
    if mark.context ~= nil and type(mark.context) ~= "string" then
      return false
    end
    -- Optional for the same reason and on the same terms (M20): a record
    -- written before roles existed simply has no principal locator in it,
    -- which is what such a chapter meant. Bumping the version for it would
    -- drop every other chapter's terms until the whole book re-rendered.
    if mark.role ~= nil and type(mark.role) ~= "string" then
      return false
    end
    -- And once more on the same terms (M21): a record written before ranges
    -- existed carries no range end, which is what such a chapter meant. An
    -- end this version does not recognize simply never pairs, exactly as it
    -- would inside one document.
    if mark.range ~= nil and type(mark.range) ~= "string" then
      return false
    end
    -- Validated here rather than trusted (review F9): a record whose xref
    -- lost its levels reaches `qi_levels.levels_key` and takes the render down with it,
    -- which IP2 forbids. Two consumers read these now — the entry builder and
    -- the book's dangling-target report — and the report reads them on every
    -- last-chapter render, before any of the marker logic runs.
    for _, xref in ipairs(mark.xrefs or {}) do
      if type(xref) ~= "table" or type(xref.attr) ~= "string"
         or type(xref.levels) ~= "table" or #xref.levels == 0 then
        return false
      end
      for _, level in ipairs(xref.levels) do
        if type(level) ~= "string" then
          return false
        end
      end
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
          qi_core.warn(("the recorded index marks for %s were written by a different "
                .. "version of this extension and were ignored; render that "
                .. "chapter again, or render the whole book, to put its "
                .. "terms back in the index"):format(file))
        else
          qi_core.warn(("the recorded index marks for %s could not be read and were "
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
        qi_core.warn(('index entry "%s" is sorted as "%s" in %s and as "%s" in %s; '
              .. 'one entry cannot file in two places, so the first in book '
              .. 'order wins')
             :format(path, seen.sort, seen.file, key, record.file))
      end
    end
  end
  return resolved
end

-- The book counterpart of `qi_sortkeys.sort_for`: the same level-path lookup with the
-- same printed-text fallback, reading the book's merged registry rather than
-- this chapter's.
local function book_sort_for(keys, levels)
  local resolved, any = {}, false
  for i = 1, #levels do
    local seen = keys[qi_levels.level_path(levels, i)]
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

-- Pair the book's ranges across every chapter's record. The set a range has to
-- be closed within is the BOOK, not a chapter: a range opened in one chapter
-- and closed in a later one is unmatched in both, and each chapter's own
-- render is silent about its half for exactly that reason (qi_marks). Records
-- arrive in book order and marks within a record in document order, so this
-- reads the book the way a reader does.
--
-- Returns the verdicts, keyed by where the mark sits, and the findings — the
-- two having different owners: the chapter that builds the index needs the
-- verdicts, and the last chapter in book order draws the reports, exactly as
-- the dangling-target report is drawn.
local function book_ranges(records)
  local items, at = {}, {}
  for ri, record in ipairs(records) do
    for mi, mark in ipairs(record.marks or {}) do
      if qi_core.RANGE_ENDS[mark.range or ""] then
        items[#items + 1] = {
          key = qi_levels.levels_key(mark.levels),
          ending = mark.range,
          principal = mark.role == "principal",
          -- Named with its chapter, for the reason the book's dangling-target
          -- report names one: the reader of this warning has a book open, not
          -- a file.
          context = (mark.context or "a mark") .. " in " .. record.file,
        }
        at[#items] = ri .. "\0" .. mi
      end
    end
  end
  local verdicts, found = qi_marks.pair_ranges(items)
  local paired = {}
  for i, where in ipairs(at) do
    -- The whole verdict, not just its ending: the role is the RANGE's, settled
    -- by the pairing from whichever end declared it, and a book is the one
    -- place where the end that declared it and the end that carries the
    -- locator can be in different chapters — neither of which can resolve it
    -- alone. Kept as the ending only, the closing's role was dropped and a
    -- cross-chapter range whose closing declared it printed a plain locator,
    -- while the same input in one document printed it emphasized (review
    -- round 2, R2-F1).
    paired[where] = verdicts[i] or nil
  end
  return paired, found
end

-- The book's counterpart of the in-document range reports, drawn by the last
-- chapter in book order alone (its caller decides), for the same reason the
-- dangling-target report is: it is the only chapter that has seen every
-- other one's record.
local function report_book_ranges(records)
  local _, found = book_ranges(records)
  for _, one in ipairs(found) do
    qi_marks.report_range(one, "book")
  end
end

local function book_marks(ctx, records)
  local book_keys = book_sort_keys(records)
  local paired = book_ranges(records)
  local marks = {}
  for ri, record in ipairs(records) do
    for mi, mark in ipairs(record.marks or {}) do
      local xrefs = {}
      for _, xref in ipairs(mark.xrefs or {}) do
        local kind = qi_core.XREF_KIND_BY_ATTR[xref.attr]
        if kind then
          xrefs[#xrefs + 1] = { kind = kind, levels = xref.levels }
        end
      end
      local verdict = paired[ri .. "\0" .. mi]
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
        -- Resolved from the book's verdict where there is one, exactly as the
        -- single-document path resolves it from this document's (qi_passes):
        -- a range's role belongs to the span, so the end that carries the
        -- locator carries the role whichever end the author wrote it on.
        role = (verdict and verdict.principal) and "principal" or mark.role,
        paired = verdict and verdict.ending or nil,
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

-- The book's counterpart of the in-document dangling-target report: the path
-- set is every chapter's marks and the targets are every chapter's too, so a
-- target naming a term another chapter indexes resolves, exactly as a reader
-- following it in the book's one index would find it.
--
-- Drawn by the last chapter in book order alone (its caller decides), which is
-- the only chapter that has seen every other one's record — a book whose
-- marker sits first would otherwise report every resolving cross-chapter
-- target as broken. Records arrive in book order and marks within a record in
-- document order, so the reports do not depend on render order.
local function report_book_dangling(records)
  local paths, xrefs = {}, {}
  for _, record in ipairs(records) do
    for _, mark in ipairs(record.marks or {}) do
      for i = 1, #mark.levels do
        paths[qi_levels.level_path(mark.levels, i)] = true
      end
    end
  end
  for _, record in ipairs(records) do
    for _, mark in ipairs(record.marks or {}) do
      for _, xref in ipairs(mark.xrefs or {}) do
        -- The same filter `book_marks` applies before the entry tree is
        -- built: an attribute name this version does not know never reaches
        -- the index, so reporting on it would name a cross-reference no
        -- reader will ever see (review F8).
        if qi_core.XREF_KIND_BY_ATTR[xref.attr] then
          xrefs[#xrefs + 1] = {
            attr = xref.attr,
            levels = xref.levels,
            -- Which chapter the mark is in, joined onto how the mark names
            -- itself: in a book of forty chapters `term "Shared Term"` alone
            -- is not somewhere an author can go (review F3). The fallback is
            -- for a record written before chapters carried their marks'
            -- naming strings — it names the file, which is the half that
            -- matters most here.
            context = (mark.context or "a mark") .. " in " .. record.file,
          }
        end
      end
    end
  end
  qi_marks.report_dangling(paths, xrefs, "book")
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
  -- Before anything about the marker: a broken cross-reference is a defect
  -- whether or not this book places an index, and the last chapter is the one
  -- that can see the whole book's marks (report_book_dangling). A book whose
  -- last chapter is not rendered gets no report — the same partial-render
  -- limit every cross-chapter judgement here already carries.
  if ctx.position == #ctx.chapters then
    report_book_dangling(records)
    report_book_ranges(records)
  end
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
      qi_core.warn("index placement marker in a book whose chapters have no index "
           .. "marks; there is no index to place")
      return qi_marker.place_index(doc, nil)
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
      qi_core.warn(("the index placement marker is in %s, and %d chapter(s) come "
            .. "after it (%s); the index is built where the marker is, so "
            .. "those chapters are represented by what an earlier render "
            .. "recorded — entries and links for them can be out of date or "
            .. "dead. Put the marker chapter last in the book")
           :format(ctx.file, #later, table.concat(later, ", ")))
    end
    return qi_marker.place_index(doc, qi_html.html_index_blocks(book_marks(ctx, records), taken))
  end

  if marker then
    qi_core.warn(("index placement marker in %s is ignored; %s comes first in book "
          .. "order and carries one too, and a book has a single index")
         :format(ctx.file, ctx.chapters[placing]))
  elseif ctx.position == #ctx.chapters and placing == nil
         and any_marks(records) then
    -- Reported by the last chapter in book order, which is the only chapter
    -- that can know no other one asked for the index: every earlier chapter
    -- has written its record by the time this one runs. One full render
    -- therefore reports this exactly once.
    qi_core.warn("this book has index marks but no chapter carries an index "
         .. "placement marker, so no index was built; write an empty div "
         .. "with class qi-index-here in the chapter that should hold the "
         .. "index, usually the last one")
  end
  return qi_marker.place_index(doc, nil)
end

-- Exported through the bracket form, never `M.NAME = NAME`: the source
-- scans take the FIRST match for `NAME =` over the whole source set, and
-- the M16-AC3 probe relocates a definition into another file — a plain
-- `NAME =` line left behind here would then mask it (M16 review F3).
M["book_ranges"] = book_ranges
M["report_book_ranges"] = report_book_ranges
M["STORE_DIR"] = STORE_DIR
M["STORE_SUFFIX"] = STORE_SUFFIX
M["STORE_VERSION"] = STORE_VERSION
M["as_href"] = as_href
M["strip_prefix"] = strip_prefix
M["book_context"] = book_context
M["relative_href"] = relative_href
M["store_path"] = store_path
M["store_write"] = store_write
M["valid_record"] = valid_record
M["store_read"] = store_read
M["book_sort_keys"] = book_sort_keys
M["book_sort_for"] = book_sort_for
M["book_marks"] = book_marks
M["report_book_dangling"] = report_book_dangling
M["marker_chapter"] = marker_chapter
M["any_marks"] = any_marks
M["html_book"] = html_book

return M
