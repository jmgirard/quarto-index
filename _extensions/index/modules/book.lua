-- Book support: the per-chapter sidecar store and the one index the chapter
-- carrying the marker builds out of it.

local qi_core = require("./core")
local qi_html = require("./html")
local qi_indexes = require("./indexes")
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
local STORE_VERSION = 4

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
-- own page, and whether it carries the placement marker. What the chapter
-- CONCLUDED — which chapters after it it could not read, and which indexes it
-- took on — is filled in by `html_book` once it knows, and this table is the
-- one written to disk.
local function build_record(ctx, marker)
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
      -- `range` is the end the AUTHOR wrote and `paired` this chapter's own
      -- verdict about it. Both travel, and they are not the conflation D-009
      -- is about: that verdict is a chapter's conclusion about marks wholly
      -- inside itself, which is exactly the scope a range pairs in. What no
      -- longer happens is the BOOK re-deriving a pairing across chapters from
      -- these fields, which produced one defect in each of three review rounds.
      -- `index` is the index this mark files in, as this chapter resolved it.
      -- A book aggregates chapters that each read the same book-wide
      -- `indexes:` metadata, so the name a chapter wrote down is a name the
      -- reading chapter normally declares too; where it is not — a record left
      -- by a render made before the declaration was edited — the reading
      -- chapter says so and files the mark in its first declared index
      -- (`fold_undeclared` below) rather than dropping the term.
      { levels = mark.levels, xrefs = xrefs, anchor = mark.anchor,
        context = mark.context, role = mark.role, range = mark.range,
        paired = mark.paired, index = mark.index }
  end
  -- The chapter's DECLARED sort keys, one per printed level path, rather than
  -- a resolved key per mark. A mark's resolved key already has this chapter's
  -- fallbacks filled in, and a fallback is indistinguishable from a declared
  -- key once written down — so the book would read one chapter's fallback as
  -- a rival to another chapter's real key, and, being first in book order,
  -- let the fallback win.
  -- One namespace per index, exactly as the in-document registry is keyed:
  -- two indexes of one book are two indexes, so a sort key written in one says
  -- nothing about where the same printed text files in the other (D-021).
  local sorts = {}
  for _, name in ipairs(qi_indexes.names()) do
    local declared_keys = {}
    local any = false
    for path, seen in pairs(qi_sortkeys.for_index(name)) do
      declared_keys[path] = seen.sort
      any = true
    end
    if any then
      sorts[name] = declared_keys
    end
  end
  return { version = STORE_VERSION, file = ctx.file, href = ctx.href,
           marker = marker, marks = marks, sorts = sorts }
end

-- The aggregation reads this chapter's own record alongside every other one,
-- and `fold_undeclared` rewrites what it reads: an index name this book no
-- longer declares is folded to the first one it does. A copy is what goes into
-- that aggregation, because the table `build_record` returned is also the one
-- written to disk, and a folded name written down is a name the record can
-- never report again. Only the fields the fold touches are copied deeply —
-- each mark, because the fold rewrites `mark.index`; `sorts` is replaced
-- wholesale by a table of its own and its nested maps are only read.
local function record_for_reading(record)
  local marks = {}
  for i, mark in ipairs(record.marks) do
    local copy = {}
    for key, value in pairs(mark) do
      copy[key] = value
    end
    marks[i] = copy
  end
  return { version = record.version, file = record.file, href = record.href,
           marker = record.marker, marks = marks, sorts = record.sorts }
end

-- Every step here can fail on an ordinary machine — a stale file where the
-- directory belongs, a read-only project tree, a full disk — and none of
-- them may take the render down with it: a marked-up document always
-- renders (IP2). The whole write is one guarded unit, reported once.
local function store_write(ctx, record)
  local path = store_path(ctx, ctx.file)
  local ok, err = pcall(function()
    pandoc.system.make_directory(pandoc.path.directory(path), true)
    local fh, open_err = io.open(path, "w")
    if not fh then
      error(tostring(open_err), 0)
    end
    local written, write_err = fh:write(pandoc.json.encode(record))
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
  -- The indexes this chapter carries a surviving placement marker for, in the
  -- order the chapter places them. A list rather than the boolean version 3
  -- wrote, because one chapter can place several indexes and the book has to
  -- know which; a chapter with no marker writes an empty one. Validated here
  -- rather than trusted, because `marker_chapter` walks it before any marker
  -- logic runs and a non-list would take the render down with it (IP2).
  -- M60's boolean, which no version now writes: `unseen` below says what it
  -- said and says WHICH chapters. Still accepted rather than refused, because
  -- a record M60 wrote is otherwise a perfectly good record and refusing it
  -- would cost its chapter's terms until the whole book rendered again — and
  -- nothing reads it, so a record carrying it says nothing about what its
  -- chapter took on, exactly as one carrying neither new field does.
  if data.later ~= nil and type(data.later) ~= "boolean" then
    return false
  end
  -- What the chapter CONCLUDED, as against what it saw. `adopted` is the
  -- indexes it built a section for, in declared order; `unseen` the chapters
  -- after it whose record it could not use. Both are read by the two reports
  -- the book's last chapter draws and by nothing that reaches an index, so
  -- both are optional on exactly the terms the per-mark fields below are: a
  -- record written before they existed is a perfectly good record, and
  -- refusing it would cost an author a whole chapter's terms for a field only
  -- a report reads. Absent is NOT the empty list — a chapter that adopted
  -- nothing writes an empty list, and only a version without the field writes
  -- none, so absent is read as no answer and no answer draws no report.
  -- Validated here rather than trusted, because both are walked with `ipairs`
  -- before any report logic runs and a non-list would take the render down
  -- with it (IP2).
  for _, list in ipairs({ "adopted", "unseen" }) do
    if data[list] ~= nil then
      if type(data[list]) ~= "table" then
        return false
      end
      for _, name in ipairs(data[list]) do
        if type(name) ~= "string" then
          return false
        end
      end
    end
  end
  if data.marker ~= nil then
    if type(data.marker) ~= "table" then
      return false
    end
    for _, name in ipairs(data.marker) do
      if type(name) ~= "string" then
        return false
      end
    end
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
    -- And its verdict, on the same terms: a record written before ranges
    -- existed has neither, which is what such a chapter meant. Held to the
    -- two ends this version knows rather than to any string (review R4-F9):
    -- `build_entry_tree` DROPS a locator on "close", so an unrecognized
    -- verdict must refuse the record, not ride through to it.
    if mark.paired ~= nil and qi_core.RANGE_ENDS[mark.paired] ~= true then
      return false
    end
    -- The field's own type BEFORE anything walks it: `ipairs` on a number
    -- raises, and this function is called outside any `pcall`, so a record
    -- whose `xrefs` is not a list would take the render down through the very
    -- function written to stop that (IP2).
    if mark.xrefs ~= nil and type(mark.xrefs) ~= "table" then
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
    -- Required rather than optional, unlike the four fields above: this is the
    -- field the version bump to 4 is for. A record with no index name is one
    -- whose marks were all resolved to a single index by a version that could
    -- not express any other, and reading it as if every mark belonged in the
    -- reading chapter's first index is exactly the silent misfiling the bump
    -- exists to refuse. The empty string is a name — it is the one a book
    -- declaring nothing has — so the test is the type, not the length.
    if type(mark.index) ~= "string" then
      return false
    end
  end
  -- The chapter's declared sort keys: an index name to that index's own map of
  -- printed level path to the key filed under it, all strings. A record with
  -- none is ordinary — most chapters declare no sort key at all — and so is an
  -- index with none.
  if data.sorts ~= nil then
    if type(data.sorts) ~= "table" then
      return false
    end
    for name, keys in pairs(data.sorts) do
      if type(name) ~= "string" or type(keys) ~= "table" then
        return false
      end
      for path, key in pairs(keys) do
        if type(path) ~= "string" or type(key) ~= "string" then
          return false
        end
      end
    end
  end
  return true
end

-- A stored record names the index each of its marks files in, and the READING
-- chapter is the one that says whether that name is an index this book has:
-- `indexes:` is book metadata, so a name the reading chapter does not declare
-- is one that WAS declared when the record was written and is not now — a
-- record left behind by a render made before the declaration was edited, or by
-- an entry the declaration syntax has since refused. Dropping those marks
-- would cost an author a whole chapter's terms for an edit they made somewhere
-- else entirely (IP2), so they are filed in the first index this book does
-- declare and both the chapter and the name are named.
--
-- The chapter's sort keys for that name move with its marks, for the reason a
-- key travels at all: the term files under the key its author wrote, and
-- leaving the key behind would file it under its printed text in silence. A
-- key arriving at a path the destination index already has one for loses, the
-- same first-one-wins rule the in-document registry follows.
--
-- Every name is settled here, before any judgement is made about a mark, so
-- the aggregation below never sees an index name this book does not have.
--
-- Returns the chapter-and-name pairs it refiled, once per name per record, in
-- the order it met them — the caller's to report. Every rendering chapter
-- calls this function, so a report drawn from inside it is drawn once per
-- chapter RENDERED, and what the refiling costs is a section's share of that
-- chapter's terms: the count belongs to the chapters that build a section, and
-- only the caller knows which those are (M062).
local function fold_undeclared(records)
  local default = qi_indexes.default()
  local refiled = {}
  for _, record in ipairs(records) do
    local reported = {}
    local function fold(name)
      if qi_indexes.declared_for(name) ~= nil then
        return name
      end
      if not reported[name] then
        reported[name] = true
        refiled[#refiled + 1] = { file = record.file, name = tostring(name) }
      end
      return default
    end
    for _, mark in ipairs(record.marks or {}) do
      mark.index = fold(mark.index)
    end
    if record.sorts ~= nil then
      -- A fixed order for the same reason `book_sort_keys` sorts its paths:
      -- `pairs` walks a Lua table however it likes, and which of two folded
      -- keys reaches a path first must not change between renders. Sorting the
      -- names alone is not enough: first-one-wins would then hand a shared path
      -- to whichever name sorts first, so a stale name could beat the
      -- destination index's own key on nothing but its spelling (review F2).
      -- The names this book still declares go first, each keeping its own keys;
      -- the folded ones follow, filling only the paths left over.
      local kept, folded = {}, {}
      for name in pairs(record.sorts) do
        if qi_indexes.declared_for(name) ~= nil then
          kept[#kept + 1] = name
        else
          folded[#folded + 1] = name
        end
      end
      table.sort(kept)
      table.sort(folded)
      local names = kept
      for _, name in ipairs(folded) do
        names[#names + 1] = name
      end
      local rebuilt = {}
      for _, name in ipairs(names) do
        local into = fold(name)
        local target = qi_core.namespace(rebuilt, into)
        local paths = {}
        for path in pairs(record.sorts[name]) do
          paths[#paths + 1] = path
        end
        table.sort(paths)
        for _, path in ipairs(paths) do
          if target[path] == nil then
            target[path] = record.sorts[name][path]
          end
        end
      end
      record.sorts = rebuilt
    end
  end
  return refiled
end

-- Returns the usable records in book order, the chapters whose record this
-- version refused for being written by another one — the caller's to report —
-- and the chapters AFTER this one whose record this render could not use.
--
-- That last list is the half of the store a chapter cannot see for itself:
-- chapters render in book order, so the ones before it have just written, and
-- the ones after it have written nothing this render. A chapter with a name in
-- that list cannot yet tell whether some later chapter places an index, and so
-- cannot conclude it is the last chapter that places anything. The chapters
-- BEFORE it are deliberately not listed: one of them missing or refused hides
-- a marker at a position this chapter already stands after, which cannot make
-- this chapter the last placer when it is not.
--
-- One pass. M60 asked the same files a second question in a second walk, which
-- opened, decoded and validated every later record twice over.
--
-- `own` is this chapter's own record, built in memory and spliced in at this
-- chapter's own position rather than read back off the disk: the store is read
-- BEFORE this chapter writes, which is the only moment these files still say
-- what the render found them saying, and a chapter reading its own file back
-- would see the state some earlier render left. It is also why nothing here
-- reports on this chapter's own file — there is no stale or unreadable record
-- of its own for it to find, whatever the write does afterwards.
local function store_read(ctx, own)
  local records, stale, unseen = {}, {}, {}
  for position, file in ipairs(ctx.chapters) do
    if file == ctx.file then
      records[#records + 1] = own
    else
      local usable = false
      local fh = io.open(store_path(ctx, file), "r")
      if fh then
        local text = fh:read("a")
        fh:close()
        local ok, data = pcall(pandoc.json.decode, text, false)
        if ok and valid_record(data, file) then
          records[#records + 1] = data
          usable = true
        else
          -- Never silent: the cost of a record this version cannot use is a
          -- chapter missing from the index, and the fix is the same either way
          -- — render that chapter again. WHY it could not be used is not: a
          -- record left by an older version of this extension is perfectly
          -- readable and simply stale, and calling that unreadable sends an
          -- author looking for a corrupt file that is not there.
          if ok and type(data) == "table" and data.version ~= STORE_VERSION then
            -- Handed back rather than reported here: a version-skewed record
            -- costs the chapters that BUILD an index their share of that
            -- chapter's terms, and every other chapter of the book reads the
            -- store without printing anything out of it. Reported by the caller,
            -- once per chapter that builds (M55).
            stale[#stale + 1] = file
          else
            qi_core.warn(("the recorded index marks for %s could not be read and were "
                  .. "ignored; render that chapter again, or render the whole "
                  .. "book, to put its terms back in the index"):format(file))
          end
        end
      end
      -- Missing, refused for its version, refused for its shape: all three leave
      -- this render without a record it can use, which is the one question the
      -- chapters after this one are asked. Why it could not be used is the
      -- reports' business above, not this list's.
      if not usable and position > ctx.position then
        unseen[#unseen + 1] = file
      end
    end
  end
  return records, stale, unseen
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
--
-- One namespace per index (D-021): a rivalry is a rivalry inside ONE index,
-- and the same printed path in another index of the book files under a key of
-- its own. The report says which index wherever the book declares several, for
-- the reason the in-document rival report does — an author told only the two
-- chapters would go looking for a rivalry that is not in the index they read.
--
-- `report` is what separates the two callers: the rivalry is a book-wide
-- judgement and is reported once, by the last chapter in book order — the only
-- one that has seen every record, and the same chapter the other two book-wide
-- reports are drawn by. Every chapter that BUILDS an index needs the same
-- merged registry to file its entries with, and asks for it silently.
local function book_sort_keys(records, report)
  local resolved = {}
  for _, record in ipairs(records) do
    -- One chapter's indexes and paths in a fixed order. `pairs` walks a Lua
    -- table in whatever order it likes, and two chapters each declaring two
    -- rival keys would otherwise report them in an order that changed between
    -- renders.
    local names = {}
    for name in pairs(record.sorts or {}) do
      names[#names + 1] = name
    end
    table.sort(names)
    for _, name in ipairs(names) do
      local registry = qi_core.namespace(resolved, name)
      local paths = {}
      for path in pairs(record.sorts[name]) do
        paths[#paths + 1] = path
      end
      table.sort(paths)
      for _, path in ipairs(paths) do
        local key = record.sorts[name][path]
        local seen = registry[path]
        if seen == nil then
          registry[path] = { sort = key, file = record.file, reported = {} }
        elseif report and seen.sort ~= key and not seen.reported[key] then
          -- Once per RIVAL KEY at this path, the same rule the in-document
          -- report follows: a term marked in three chapters under one rival key
          -- is one thing for the author to fix, while a second, different rival
          -- is a second thing and names a key the first report never mentions.
          seen.reported[key] = true
          local scope = qi_indexes.scope_phrase(name, "book")
          if scope == "book" then
            qi_core.warn(('index entry "%s" is sorted as "%s" in %s and as "%s" in %s; '
                  .. 'one entry cannot file in two places, so the first in book '
                  .. 'order wins')
                 :format(path, seen.sort, seen.file, key, record.file))
          else
            -- One literal. The scope clause sits between the two chapters and
            -- the tail, and the tail itself differs by one word, so neither
            -- message is a substring of the other and each has a
            -- placeholder-free clause of its own for the run to grep by
            -- (D-022).
            qi_core.warn(('index entry "%s" is sorted as "%s" in %s and as "%s" in %s, and both keys are written in %s; one entry cannot file in two places there, so the first in book order wins'):format(path, seen.sort, seen.file, key, record.file, scope))
          end
        end
      end
    end
  end
  return resolved
end

-- The book counterpart of `qi_sortkeys.sort_for`: the same level-path lookup with the
-- same printed-text fallback, reading one index's share of the book's merged
-- registry rather than this chapter's own.
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

-- The book's range report (D-009). A range pairs within one Pandoc process and nowhere
-- else: a single document is one process, and a PDF book is one merged document, but an
-- HTML book renders each chapter in its own, so the pairing would have to be re-derived
-- here from records whose fields mix what the author wrote with what that chapter
-- concluded. Three review rounds each produced one defect from that conflation, so this
-- does not pair at all — each such mark indexes as though the attribute were absent.
--
-- What the book names is only the marks whose COUNTERPART it can see in another
-- chapter's record (review R4-F1): an opening one chapter refused as never
-- closed, whose closing a later chapter refused as never opened — the one
-- shape whose cause is chapter-crossing. A mark with no counterpart anywhere
-- is a one-chapter fault its own chapter's pairing reports already state, and
-- re-reporting it here named the wrong cause. Matched in book order, first
-- open to first close per key, over the UNPAIRED ends alone — deliberately
-- not what one merged process would pair, since a merged process would see
-- the in-chapter pairs too and pair across them; under D-009 the chapter
-- verdicts are primary, and this walk only asks which leftovers face each
-- other across a chapter boundary.
--
-- Drawn by the last chapter in book order alone (its caller decides), for the same reason
-- the dangling-target report is: it is the only chapter that has seen every other one's
-- record. One report for the book, naming every mark it found, rather than one per mark —
-- the author's fix is a single decision about the book, not a decision per mark.
-- One pairing namespace per index (D-021): an opening in one index and a
-- closing in another are two unpaired marks, not a split pair, so each index's
-- leftovers are matched against its own alone and the report says which index
-- it is about wherever the book declares several.
local function report_book_ranges(records)
  local named, pending = {}, {}
  for at, record in ipairs(records) do
    for _, mark in ipairs(record.marks or {}) do
      if qi_core.RANGE_ENDS[mark.range or ""] and mark.paired == nil then
        local open_here = qi_core.namespace(pending, mark.index)
        local key = qi_levels.levels_key(mark.levels)
        -- Named with its chapter, for the reason the book's dangling-target report names
        -- one: the reader of this warning has a book open, not a file.
        local name = (mark.context or "a mark") .. " in " .. record.file
        if mark.range == "open" then
          if open_here[key] == nil then
            open_here[key] = { chapter = at, name = name }
          end
        elseif open_here[key] ~= nil then
          -- A counterpart in the SAME chapter cannot arise — the chapter
          -- would have paired the two itself — but the guard keeps this
          -- report's promise independent of that.
          if open_here[key].chapter ~= at then
            local list = qi_core.namespace(named, mark.index)
            list[#list + 1] = open_here[key].name
            list[#list + 1] = name
          end
          open_here[key] = nil
        end
      end
    end
  end
  -- In declared order, so a book with two indexes reports them in the order it
  -- prints them rather than in whatever order `pairs` walks.
  for _, index in ipairs(qi_indexes.names()) do
    local list = named[index]
    if list ~= nil and #list > 0 then
      local scope = qi_indexes.scope_phrase(index, "book")
      if scope == "book" then
        qi_core.warn(('%s= is not paired across the chapters of an HTML book, so each of these marks indexes on its own rather than as one end of a range: %s. A range whose two marks are in one chapter, and a range in a PDF book, are both paired as usual'):format(qi_core.RANGE_ATTR, table.concat(list, "; ")))
      else
        -- The scope clause sits before the list rather than after it, so
        -- neither shape is a prefix of the other (D-022).
        qi_core.warn(('%s= is not paired across the chapters of an HTML book, and these marks are in %s, so each indexes on its own rather than as one end of a range: %s. A range whose two marks are in one chapter, and a range in a PDF book, are both paired as usual'):format(qi_core.RANGE_ATTR, scope, table.concat(list, "; ")))
      end
    end
  end
end

local function book_marks(ctx, records)
  local book_keys = book_sort_keys(records, false)
  local marks = {}
  for _, record in ipairs(records) do
    for _, mark in ipairs(record.marks or {}) do
      local xrefs = {}
      for _, xref in ipairs(mark.xrefs or {}) do
        local kind = qi_core.XREF_KIND_BY_ATTR[xref.attr]
        if kind then
          xrefs[#xrefs + 1] = { kind = kind, levels = xref.levels }
        end
      end
      marks[#marks + 1] = {
        levels = mark.levels,
        -- Which index this mark files in, as its own chapter resolved it and
        -- `fold_undeclared` settled against what this book declares now. It is
        -- what splits the book's marks into sections, exactly as a single
        -- document's own `index=` does.
        index = mark.index,
        -- The book's keys for this mark's levels, not this chapter's own: a
        -- term marked in three chapters with a sort key written in one of
        -- them files under that key everywhere, exactly as it does inside one
        -- document — and a level's key applies wherever that level appears,
        -- alone or as some sub-entry's parent. Read from that mark's own
        -- index's share of the registry: a key written for a printed path in
        -- one index says nothing about the same path in another (D-021).
        sort = book_sort_for(qi_core.namespace(book_keys, mark.index),
                             mark.levels),
        xrefs = xrefs,
        anchor = mark.anchor,
        -- The chapter's own resolved role, which is all a book needs now that
        -- nothing pairs here: a mark carries whatever role its own chapter
        -- concluded for it.
        role = mark.role,
        -- This chapter's own verdict, carried through untouched: a range whose
        -- two marks are in one chapter pairs there, and its closing
        -- contributes no locator here either.
        paired = mark.paired,
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
-- following it in the book's index would find it.
--
-- One namespace per index (D-021), and one report pass per index in declared
-- order: a target written in one index that names a term only the other index
-- marks is the dangling target it is to a reader, who has one index section in
-- front of them and not the union of two.
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
      local set = qi_core.namespace(paths, mark.index)
      for i = 1, #mark.levels do
        set[qi_levels.level_path(mark.levels, i)] = true
      end
    end
  end
  for _, record in ipairs(records) do
    for _, mark in ipairs(record.marks or {}) do
      local list = qi_core.namespace(xrefs, mark.index)
      for _, xref in ipairs(mark.xrefs or {}) do
        -- The same filter `book_marks` applies before the entry tree is
        -- built: an attribute name this version does not know never reaches
        -- the index, so reporting on it would name a cross-reference no
        -- reader will ever see (review F8).
        if qi_core.XREF_KIND_BY_ATTR[xref.attr] then
          list[#list + 1] = {
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
  for _, name in ipairs(qi_indexes.names()) do
    -- The scope the report names is the set the target was judged against,
    -- which is this ONE index wherever the book declares several;
    -- `scope_phrase` hands the outer word back where there is genuinely one
    -- namespace, and the report reads exactly as it always did.
    qi_marks.report_dangling(paths[name] or {}, xrefs[name] or {}, "book", name)
  end
end

-- The first chapter in book order that carries a marker for each declared
-- index, by position. One index, one placement site, resolved across the book
-- the same way `resolve_markers` resolves it inside one chapter.
--
-- A stored marker naming an index this book no longer declares places nothing:
-- it is a stale record's leftover, and folding it to the first declared index
-- would let it take the placement site away from the marker the author has
-- actually written for that index in some other chapter. Its own chapter's
-- marks are refiled by `fold_undeclared`, and the report `html_book` draws
-- from what that returns is what tells the author the record is stale.
local function marker_chapter(ctx, records)
  local first = {}
  for _, record in ipairs(records) do
    local position = ctx.positions[record.file]
    if position then
      for _, name in ipairs(record.marker or {}) do
        local index = qi_indexes.declared_for(name)
        if index ~= nil
           and (first[index] == nil or position < first[index]) then
          first[index] = position
        end
      end
    end
  end
  return first
end

-- Does any chapter file a mark in this index? An index nothing marks prints no
-- section however it is placed, so a deferral reported for it would promise a
-- section a further render would not print either.
local function marks_in(records, name)
  for _, record in ipairs(records) do
    for _, mark in ipairs(record.marks or {}) do
      if mark.index == name then
        return true
      end
    end
  end
  return false
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
-- because they are what the book's index links back to; an index itself is
-- built by the one chapter that places it.
--
-- `marker` is the list of index names this chapter has a surviving placement
-- marker for, in the order it places them.
local function html_book(doc, ctx, marker, taken)
  -- Built before the store is read and written after every judgement is made:
  -- this chapter's record carries what it CONCLUDED as well as what it saw,
  -- and what it concluded is not known until the placement below is settled.
  -- The copy is what the aggregation reads, because `fold_undeclared` rewrites
  -- the record it walks (`record_for_reading`).
  local record = build_record(ctx, marker)
  local reading = record_for_reading(record)
  local records, stale, unseen = store_read(ctx, reading)
  -- This chapter's answer to a question only it can answer: which chapters
  -- after this one had no record this render could use? Chapters render in
  -- book order and each rewrites its own record as it goes, so no later
  -- chapter can reconstruct what an earlier one saw — and the book's last
  -- chapter has to know it, because it is the chapter that reports an index
  -- section left unplaced, and names there what stood in the way.
  record.unseen = unseen
  reading.unseen = unseen
  local later = #unseen == 0
  -- Before any judgement is made about a mark: an index name this book no
  -- longer declares is settled against what it declares now, so every
  -- accumulator below sees only names this book has.
  local refiled = fold_undeclared(records)
  -- Before anything about the marker: a broken cross-reference is a defect
  -- whether or not this book places an index, and the last chapter is the one
  -- that can see the whole book's marks (report_book_dangling). A book whose
  -- last chapter is not rendered gets no report — the same partial-render
  -- limit every cross-chapter judgement here already carries. The sort-key
  -- rivalry is the third book-wide judgement and is drawn here for the same
  -- reason, rather than by whichever chapter happens to build an index: with
  -- an index per marker there can be several of those, and the rivalry is one
  -- fact about the book rather than one per section.
  if ctx.position == #ctx.chapters then
    report_book_dangling(records)
    report_book_ranges(records)
    book_sort_keys(records, true)
  end
  -- Which chapter places each index. What THIS chapter carries is known here,
  -- and is never read back from the store: a chapter whose own record failed
  -- to write would otherwise conclude that some other chapter holds its
  -- marker, build no index, and report a chapter that does not exist.
  local placing = marker_chapter(ctx, records)
  for _, name in ipairs(marker) do
    if placing[name] == nil or placing[name] > ctx.position then
      placing[name] = ctx.position
    end
  end

  -- The indexes THIS chapter builds, and where the book's placement sites
  -- begin and end. `first` draws the reports that are about the book rather
  -- than about one section, so a book placing three indexes in three chapters
  -- still reports each of them once.
  local mine, first, last = {}, nil, nil
  for _, name in ipairs(qi_indexes.names()) do
    local at = placing[name]
    if at ~= nil then
      if first == nil or at < first then first = at end
      if last == nil or at > last then last = at end
      if at == ctx.position then
        mine[name] = true
      end
    end
  end
  -- An index no marker names goes after the ones markers do place: it is
  -- handed to the LAST chapter that places anything, where `place_index`
  -- appends it below that chapter's own markers, in declared order. A chapter
  -- whose author wrote no marker at all therefore never grows an index
  -- section, and every section of the book sits in a chapter its author asked
  -- for one in — which is the single document's rule read for a book.
  -- Each of this chapter's markers for an index some EARLIER chapter marks a
  -- place for. Reported before anything is built, because a chapter can both
  -- build one index and lose another to a chapter ahead of it.
  for _, name in ipairs(marker) do
    if placing[name] ~= ctx.position then
      -- One index is placed once, the same rule `resolve_markers` applies
      -- inside one chapter, read across the book.
      if qi_indexes.scope_phrase(name, "book") == "book" then
        qi_core.warn(("index placement marker in %s is ignored; %s comes first in book "
              .. "order and carries one too, and a book has a single index")
             :format(ctx.file, ctx.chapters[placing[name]]))
      else
        -- The index name sits between the two chapters rather than after them,
        -- so neither shape is a prefix of the other (D-022).
        qi_core.warn(('index placement marker in %s for the index named "%s" is ignored; %s comes first in book order and carries a marker for that index too, and each index of a book is placed where the first marker naming it stands'):format(ctx.file, name, ctx.chapters[placing[name]]))
      end
    end
  end

  local builds = next(mine) ~= nil
  -- ...but only a chapter that has seen a record for every chapter after it
  -- may conclude it is the last one that places anything. On a first render no
  -- chapter has written yet when the chapters before it run, so an early
  -- placing chapter would otherwise take on every index no marker names and
  -- print it in a chapter its author asked nothing for. Where that picture is
  -- missing the section waits for a further render, and the book's last
  -- chapter says so below — the placement rule itself is unchanged.
  if first ~= nil and ctx.position == last and later then
    for _, name in ipairs(qi_indexes.names()) do
      if placing[name] == nil then
        mine[name] = true
        builds = true
      end
    end
  end

  -- Which indexes this chapter built a section for, in declared order —
  -- whether its own marker placed one or it took on an index no marker names.
  -- Recorded rather than re-derived, because the chapter that reports on it
  -- renders later and cannot see the store as this one found it. The two
  -- causes are deliberately not told apart here: what the reports are about is
  -- how many chapters printed a section, and which of them a marker sent
  -- there is a question `marker_chapter` answers from the same records.
  local adopted = {}
  for _, name in ipairs(qi_indexes.names()) do
    if mine[name] then
      adopted[#adopted + 1] = name
    end
  end
  record.adopted = adopted
  reading.adopted = adopted

  -- Everything this chapter concluded is settled, so the record goes to disk
  -- here rather than before the store was read: one write, after the last
  -- judgement, and the aggregation above ran over the copy of it.
  store_write(ctx, record)

  -- Drawn by the last chapter in book order alone, the same chapter the three
  -- book-wide reports are drawn by: it is the only one that has seen every
  -- record, so it is the only one that can say an index is named by no marker
  -- anywhere. Whether the chapter that should have taken it on did so is read
  -- off that chapter's own record, which it wrote as it rendered; a chapter
  -- that renders later cannot see what an earlier one saw.
  if ctx.position == #ctx.chapters and first ~= nil then
    -- The record of the chapter an index no marker names is owed to. It is
    -- read for what that chapter CONCLUDED — the sections it built, and the
    -- chapters it could not read — rather than for a picture re-derived here
    -- from the store as it stands now, which is not the store that chapter
    -- saw. `records` always holds it: `last` is a position `marker_chapter`
    -- read out of these same records.
    local placer = nil
    for _, other in ipairs(records) do
      if other.file == ctx.chapters[last] then
        placer = other
      end
    end
    -- A record with neither field was written by a version that had neither,
    -- and says nothing about what its chapter took on. A report drawn on that
    -- silence is a report about a section that may well be on the page, so
    -- silence draws none.
    if placer ~= nil and placer.adopted ~= nil then
      local took = {}
      for _, name in ipairs(placer.adopted) do
        took[name] = true
      end
      -- Named where there are any, and "none" where there are not: a chapter
      -- can have read every record and still not have taken the section on,
      -- when the store it read named a LATER chapter as the last placer —
      -- a marker that chapter has since lost, or a record left claiming one.
      local blocked = #(placer.unseen or {}) > 0
        and table.concat(placer.unseen, ", ") or "none"
      for _, name in ipairs(qi_indexes.names()) do
        if placing[name] == nil and not took[name]
           and marks_in(records, name) then
          qi_core.warn(('no placement marker in this book names the index "%s", so its section goes to %s, the last chapter of the book that places one — and when that chapter rendered it did not take the section on. Chapters whose record it could not read then: %s. A chapter takes on an index no marker names only once it has read a usable record for every chapter after it'):format(name, ctx.chapters[last], blocked))
        end
      end
    end

    -- ...and the other way round: an index with a section in more than one
    -- chapter. Read off the same recorded adoptions, because that is the only
    -- place a chapter's own conclusion survives its process — nothing on this
    -- render's pages tells the last chapter what an earlier one printed. Named
    -- in book order, once per index, by the one chapter that has seen every
    -- record. A record with no `adopted` field is a chapter that says nothing
    -- about what it built, and a chapter that says nothing is not counted as
    -- one of two.
    local built = {}
    for _, other in ipairs(records) do
      for _, name in ipairs(other.adopted or {}) do
        local carrying = qi_core.namespace(built, name)
        carrying[#carrying + 1] = other.file
      end
    end
    for _, name in ipairs(qi_indexes.names()) do
      local carrying = built[name] or {}
      -- `adopted` is what a chapter DECIDED to build, and a declared index no
      -- mark files in is decided for and then printed nowhere: an index with
      -- no marks anywhere in the book has no section to have twice. Guarded
      -- on the same `marks_in` the unplaced-section report above is guarded
      -- on, and for the same reason (M061 review F1).
      if #carrying > 1 and marks_in(records, name) then
        qi_core.warn(('the index "%s" has a section in more than one chapter of this book — %s. A chapter builds a section for an index its own marker places, and the last chapter that places any index also builds one for each index no marker names; a placement marker added between two renders changes which chapter that is, and a render made before every chapter has read the new marker builds the section in each of them'):format(name, table.concat(carrying, ", ")))
      end
    end
  end

  -- The two reports about a stored record this render could not use as it
  -- stands: one refused for its version, one refiled because it names an index
  -- this book no longer declares. Both cost the same thing — a section's share
  -- of that chapter's terms — so both are drawn on the same rule, at one site
  -- (M062).
  --
  -- Once per chapter that BUILDS a section, which is what M55 decided: a
  -- chapter that prints nothing has nothing to say about a record it never
  -- printed out of. A book placing three indexes in three chapters therefore
  -- says so three times, once per section the record is missing from.
  --
  -- ...and once by each chapter whose records show NO chapter of the book
  -- placing any index. Left at the building rule alone, a book with no
  -- placement marker anywhere reports a record it cannot use zero times, and
  -- an author whose chapter has silently dropped out of a book that will get
  -- an index as soon as they write a marker is told nothing at all.
  if builds or first == nil then
    for _, file in ipairs(stale) do
      qi_core.warn(("the recorded index marks for %s were written by a different "
            .. "version of this extension and were ignored; render that "
            .. "chapter again, or render the whole book, to put its "
            .. "terms back in the index"):format(file))
    end
    for _, entry in ipairs(refiled) do
      qi_core.warn(('the recorded index marks for %s name the index "%s", which this book does not declare; they are filed in the first index it does declare, and their sort keys with them — render that chapter again, or render the whole book, once the %s: metadata is settled'):format(entry.file, entry.name, qi_indexes.INDEXES_KEY))
    end
  end

  if builds then
    if not any_marks(records) then
      -- The book path's counterpart to the single-document no-marks warning,
      -- which cannot be asked of one chapter. Without it a marker in a book
      -- that marks nothing renders an empty index section. Drawn by the first
      -- placing chapter alone: it is one fact about the book.
      if ctx.position == first then
        qi_core.warn("index placement marker in a book whose chapters have no index "
             .. "marks; there is no index to place")
      end
      return qi_marker.place_index(doc, nil)
    end
    -- Named for what it holds rather than `later`, which in this function is
    -- already the boolean this chapter recorded about the store.
    local after = {}
    for position = ctx.position + 1, #ctx.chapters do
      after[#after + 1] = ctx.chapters[position]
    end
    if #after > 0 then
      -- Chapters render in book order, so a chapter after this one has not
      -- run yet in this render: what the index shows for it is whatever an
      -- earlier render recorded, which may name terms that chapter no longer
      -- marks and link to anchors its page no longer has.
      -- Drawn once per PLACING chapter rather than once for the book: with an
      -- index per marker the chapters after one placing chapter are not the
      -- chapters after another, and each sentence is a fact about the one
      -- chapter it names.
      -- The count names the sequence it is over (D-014), which for a book is
      -- the render list rather than the files on disk: a part heading with no
      -- file of its own is not a chapter and is not counted, and a file the
      -- book does not render is not in the sequence at all.
      qi_core.warn(("an index placement marker is in %s, and %d chapter(s) come "
            .. "after it (%s); an index is built where its marker is, so "
            .. "those chapters are represented by what an earlier render "
            .. "recorded — entries and links for them can be out of date or "
            .. "dead. Put the marker chapter last in the book. The chapter "
            .. "count is over the files this book renders, in the order the "
            .. "book's render list gives them")
           :format(ctx.file, #after, table.concat(after, ", ")))
    end
    -- Only the marks of the indexes this chapter builds. Another chapter's
    -- section is built in that chapter's own process, out of the same records.
    local mine_marks = {}
    for _, mark in ipairs(book_marks(ctx, records)) do
      if mine[mark.index] then
        mine_marks[#mine_marks + 1] = mark
      end
    end
    return qi_marker.place_index(doc,
      qi_html.html_index_blocks(mine_marks, taken))
  end

  if ctx.position == #ctx.chapters and first == nil and any_marks(records) then
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
M["report_book_ranges"] = report_book_ranges
M["STORE_DIR"] = STORE_DIR
M["STORE_SUFFIX"] = STORE_SUFFIX
M["STORE_VERSION"] = STORE_VERSION
M["as_href"] = as_href
M["strip_prefix"] = strip_prefix
M["book_context"] = book_context
M["relative_href"] = relative_href
M["store_path"] = store_path
M["build_record"] = build_record
M["record_for_reading"] = record_for_reading
M["store_write"] = store_write
M["valid_record"] = valid_record
M["fold_undeclared"] = fold_undeclared
M["store_read"] = store_read
M["book_sort_keys"] = book_sort_keys
M["book_sort_for"] = book_sort_for
M["book_marks"] = book_marks
M["report_book_dangling"] = report_book_dangling
M["marker_chapter"] = marker_chapter
M["marks_in"] = marks_in
M["any_marks"] = any_marks
M["html_book"] = html_book

return M
