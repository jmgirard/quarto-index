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
    -- The project directory the chapter list is relative to. Carried because
    -- a chapter whose record cannot be used is read back from its own source,
    -- and `book.render` names that source relative to here.
    root = root,
  }
end

-- The extension this render is writing pages under, read off this chapter's
-- own output page rather than assumed: `.html` for every book this code runs
-- for, and the one spelling the render is known to be producing.
local function output_extension(ctx)
  return ctx.href:match("(%.[^%./]+)$") or ""
end

-- Another chapter's page, as this book's output tree spells it. The store
-- normally answers this — every record carries its chapter's own `href` — so
-- this is for the chapter whose record could not be used and whose page must
-- therefore be derived from what Quarto's own conventions make it.
--
-- `meta` is that chapter's own parsed metadata. Quarto lets a chapter name its
-- output file there, and probing this book fixture on 2026-08-30 with
-- `output-file: custom-four.html` in one chapter and `output-file: bare-two`
-- in another produced `custom-four.html` and `bare-two.html`: the name is
-- taken as written where it carries an extension, and given the output
-- extension where it does not. It is relative to the chapter, as the chapter's
-- own source path is.
--
-- That same probe found `quarto.doc.output_file` for such a chapter pointing
-- outside the project's output directory, so `book_context` above returns nil
-- for it and it writes no record at all (KI216). A chapter declaring
-- `output-file:` therefore reaches this branch only where an earlier render
-- left it a record this version can no longer use. The branch is written all
-- the same: the alternative is a locator that silently names a page the book
-- does not have.
local function chapter_href(ctx, file, meta)
  local dir = file:match("^(.*/)") or ""
  local declared = meta and meta["output-file"] or nil
  if declared ~= nil then
    local name = as_href(pandoc.utils.stringify(declared))
    if name ~= "" then
      if not name:match("[^/]%.[^%./]+$") then
        name = name .. output_extension(ctx)
      end
      return dir .. name
    end
  end
  return (file:gsub("%.[^%./]*$", "")) .. output_extension(ctx)
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

-- Was this record ever WRITTEN? `io.open` on a record path returns nothing
-- both for a record no render has written and for one that is there and out
-- of reach — a file whose directory has lost the search bit, a path a hand has
-- replaced with a broken link, a store directory replaced by a file — and the
-- two are opposite cases: the first is a first render, which recovery leaves
-- alone, and the second is that chapter's marks lost from every other
-- chapter's index, silently and on every render (D-043, D-044).
--
-- Told apart without reading any error message, by the DIRECTORY LISTING the
-- record's own name would be in: a record whose filename is among the entries
-- of the directory holding it was written there, whatever opening it does.
-- No render produces a file of that name it cannot open, so the name in the
-- listing is the evidence. A file merely NAMED like a record and unopenable —
-- a broken link an author left by hand — is read as written and recovered:
-- the boundary D-044 accepts, because nothing Pandoc's Lua interface exposes
-- separates it from the real thing (KI224).
--
-- Where that directory cannot be listed at all it is itself the unusable
-- thing, provided its own name is in a listing of ITS parent — D-043's test,
-- kept whole and reached through this same probe. A directory that is simply
-- not there fails that test, so a first render and a tree with no store take
-- the absent branch exactly as they did.
--
-- A parent that cannot be listed either hands its own answer down rather than
-- being read as absent: a directory below one that is itself out of reach is
-- out of reach too. That is what makes "every record under such a directory"
-- mean every record however deeply nested, and not only the ones sitting
-- directly in it — the chapter at `sub/two.qmd`, whose record `store_write`
-- puts in a matching subdirectory, is two failed listings below a store
-- directory replaced by a file. The walk therefore ends only at a directory
-- that CAN be listed, and what that listing says about the name below it is
-- the whole answer for the chain.
--
-- The listing consulted is the record's OWN directory, not the store's top
-- level: a book chapter may sit in a subdirectory and `store_write` puts its
-- record in a matching subdirectory of the store, so two chapters of the same
-- filename in different directories share a record basename. Compared against
-- the top-level listing alone, the never-written one of them would read as
-- written and a first render would recover it — the falsifier D-043 names.
--
-- Answered from memory per directory, so a render lists the store once however
-- many records it meets there, which is the cost D-043 settled on; and lazily,
-- so a book whose records all open lists nothing at all.
local function store_probe()
  local seen = {}
  local function listing(dir)
    local answer = seen[dir]
    if answer ~= nil then
      return answer
    end
    local ok, entries = pcall(pandoc.system.list_directory, dir)
    if ok then
      local names = {}
      for _, entry in ipairs(entries) do
        names[entry] = true
      end
      answer = { names = names, lost = false }
    else
      -- `pandoc.path.directory` is its own fixed point at a root ("/" and "."
      -- both map to themselves), which is what stops this walking for ever.
      local parent = pandoc.path.directory(dir)
      local up = parent ~= dir and listing(parent) or nil
      answer = {
        names = nil,
        lost = up ~= nil
          and (up.lost
            or (up.names ~= nil
              and up.names[pandoc.path.filename(dir)] == true)),
      }
    end
    seen[dir] = answer
    return answer
  end
  return function(path)
    local where = listing(pandoc.path.directory(path))
    if where.lost then
      return true
    end
    return where.names ~= nil
      and where.names[pandoc.path.filename(path)] == true
  end
end

-- One chapter's record: what it marked, where those marks are anchored on its
-- own page, and whether it carries the placement marker. Complete as it
-- stands, and this table is the one written to disk: M60 and M061 also filled
-- in what the chapter CONCLUDED, for the two reports M063 retired, and nothing
-- adds a field to it after it is built.
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
      -- `page_locator` is set on a front-matter mark of an HTML book chapter,
      -- which has no anchor and contributes the chapter's page (D-048); it
      -- travels so the reading chapter files the record's row as the
      -- recovery route files the same mark.
      { levels = mark.levels, xrefs = xrefs, anchor = mark.anchor,
        context = mark.context, role = mark.role, range = mark.range,
        paired = mark.paired, index = mark.index,
        page_locator = mark.page_locator }
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
  -- Exactly this version and nothing else. Deliberately NOT the narrowed test
  -- `store_read` classifies on: usability asks whether this render can read
  -- the record, and a record whose `version` is absent, a string or a boolean
  -- is as unusable as one carrying another number. The narrowed test decides
  -- only which report the chapter draws about a record this one has already
  -- refused, so the two must not be aligned (M073).
  if type(data) ~= "table" or data.version ~= STORE_VERSION then
    return false
  end
  -- A record naming a different chapter than the file it was read from is not
  -- this chapter's record, whatever wrote it.
  if data.file ~= file or type(data.href) ~= "string"
     or type(data.marks) ~= "table" then
    return false
  end
  -- `later`, `adopted` and `unseen` are not validated and not read: M60 and
  -- M061 wrote them for the two reports M063 retired, and no field this
  -- version reads is derived from any of them. A record carrying all three,
  -- or one of them holding a shape this file would once have refused, is
  -- still a perfectly good record — refusing it would cost its chapter's
  -- terms until the whole book rendered again, over a field nothing walks.
  -- `STORE_VERSION` therefore does not move: the fields are ignored, not
  -- outlawed (the M14 lesson).
  --
  -- The indexes this chapter carries a surviving placement marker for, in the
  -- order the chapter places them. A list rather than the boolean version 3
  -- wrote, because one chapter can place several indexes and the book has to
  -- know which; a chapter with no marker writes an empty one. Validated here
  -- rather than trusted, because `marker_chapter` walks it before any marker
  -- logic runs and a non-list would take the render down with it (IP2).
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

-- ---------------------------------------------------------------------------
-- Recovery: one chapter's record rebuilt from that chapter's own source.
--
-- The store is the primary route and stays it. This runs only where the store
-- held a record the reading chapter OPENED and could not use, which costs that
-- chapter every term it marked; a record that is simply ABSENT is not this
-- case and is left alone, so a first render is unchanged (D-041).
--
-- What comes back is the AUTHOR's own values and nothing else: the levels each
-- mark indexes, the index it files in, the sort keys it declares, and which
-- indexes the chapter places.
-- A chapter's own conclusions about itself — the anchor it MINTED, the role it
-- resolved, the verdict it reached about a range, the sort key it RESOLVED by
-- filling its own fallbacks in — are not here and are not invented (D-009,
-- D-021). So a recovered mark indexes as though `range=` and `role=` were
-- absent. An id the AUTHOR wrote on the mark is not one of those conclusions
-- and does come back, as its anchor, so its locator is the chapter's page
-- followed by that id; a mark whose author wrote none gets the page alone,
-- there being no id to mint one against here. A `sort=` the author wrote is one of their own values
-- and does come back, in the declared-key-per-printed-path shape
-- `build_record` writes, so a term files where its author asked whether or not
-- its chapter's record could be read.
--
-- The parse is an AST walk with this extension's own mark reader, which is why
-- D-040's first ground against reading source does not hold here. Its second
-- stands and is this route's boundary: Quarto expands include shortcodes and
-- executable cells before any filter runs, and this parse is of the file on
-- disk, so a mark arriving by either route is not in it. Neither is a mark
-- inside a block or span Quarto shows or hides by format, profile or metadata
-- — `drop_conditional` below takes those out whole before anything is read.
-- ---------------------------------------------------------------------------

-- Quarto's two conditional-content classes. A block or span carrying either is
-- kept or dropped by the format being rendered, the active profile, or a
-- metadata value — settled by Quarto before any filter runs, and recorded
-- nowhere in the file on disk. This route reads the file on disk, so it cannot
-- tell which way the render went, and takes the whole element out rather than
-- guess: a mark inside one is left out even where the render in hand would
-- have kept it. That costs a term, where the other direction puts a term in
-- the index whose page does not carry it.
local CONDITIONAL_CLASSES = { "content-visible", "content-hidden" }

local function is_conditional(el)
  for _, class in ipairs(CONDITIONAL_CLASSES) do
    if el.classes:includes(class) then
      return true
    end
  end
  return false
end

-- The removal itself, as one filter table, because two things are read out of
-- a chapter's source and both carry conditional content: its blocks, and its
-- metadata. The walk is bottom-up, so a conditional nested inside another is
-- removed with its parent either way; a marker div carrying one of the classes
-- goes with the rest.
local CONDITIONAL_FILTER = {
  Div = function(div)
    if is_conditional(div) then
      return {}
    end
    return nil
  end,
  Span = function(span)
    if is_conditional(span) then
      return {}
    end
    return nil
  end,
}

-- The parsed blocks with every conditional element removed, whole — its
-- content with it.
local function drop_conditional(blocks)
  return blocks:walk(CONDITIONAL_FILTER)
end

-- The same removal over a chapter's parsed METADATA, returned as a document
-- carrying that metadata and no blocks. `Meta` has no `walk` of its own, so
-- the walk is over a document built around it. The same filter, because the
-- two classes mean the same thing wherever an author writes them and this
-- route can no more tell which way the render went in `abstract:` than it can
-- in the body: verified 2026-09-02 under pandoc 3.11, a `.content-hidden` span
-- and a `.content-hidden` div written in `abstract:` are both taken out by
-- this walk and both survive when it is not made.
local function conditional_free_meta(meta)
  return pandoc.Pandoc({}, meta):walk(CONDITIONAL_FILTER)
end

-- Every index mark in a chapter's parsed blocks, in document order, as a
-- record's marks. The blocks are `drop_conditional`'s, never the raw parse.
-- Silent throughout: every report about what an author wrote is drawn by that
-- chapter's own render, and drawing them again here would name another
-- chapter's mistakes once per chapter that reads it.
--
-- One printed level path files under one sort key, and the FIRST mark in
-- document order to declare it wins — the rule `qi_sortkeys.register_sort`
-- follows inside a rendering chapter, kept here so a chapter recovered from
-- its source and the same chapter read from its record cannot file its terms
-- differently. Silently, like everything else here: the rival-key report is
-- that chapter's own render's to draw.
local function register_recovered_sort(sorts, index, levels, value, context,
                                       kept, depth)
  if value == nil then
    return
  end
  local declared =
    qi_levels.sort_levels(value, levels, context, false, kept, depth)
  if declared == nil then
    return
  end
  for i = 1, #levels do
    local key = declared[i]
    if key then
      local registry = sorts[index]
      if registry == nil then
        registry = {}
        sorts[index] = registry
      end
      local path = qi_levels.level_path(levels, i)
      if registry[path] == nil then
        registry[path] = key
      end
    end
  end
end

-- Returns the marks and the DECLARED sort keys, one map per index, in
-- `build_record`'s own shape — a resolved key would carry this reader's
-- fallbacks and beat another chapter's real one, which is the conflation
-- `build_record` states at length.
--
-- Over the chapter's METADATA as well as its blocks, because that is what the
-- chapter's own render reads. The render's collect passes are filter tables
-- carrying a `Span` function, and Pandoc hands such a table a document's
-- metadata as readily as its blocks, so a mark an author writes in YAML front
-- matter is indexed by that chapter's own render exactly as one in the body
-- is. A recovery walk over the blocks alone left such a mark out of every
-- index of the book, silently, whenever the chapter was recovered rather than
-- read from its record.
local function recovered_marks(meta, blocks)
  local marks, sorts = {}, {}
  -- Which of the two walks below is running. The author's own id is carried
  -- out of the blocks and never out of the metadata: a front-matter mark of an
  -- HTML book chapter files the chapter's page and no fragment on the record
  -- route too (D-048), and the two routes have to keep printing the one row.
  local in_blocks = false
  local function collect(span)
    if not span.classes:includes(qi_core.INDEX_CLASS) then
      return nil
    end
    local entry = span.attributes["entry"]
    local visible = qi_marks.span_text(span)
    local context = qi_marks.describe(entry, visible)
    local xrefs, declared = {}, 0
    for _, kind in ipairs(qi_core.XREF_KINDS) do
      local value = span.attributes[kind.attr]
      if value ~= nil then
        declared = declared + 1
        local levels = qi_marks.target_levels(value, kind.attr, context, false)
        if levels then
          xrefs[#xrefs + 1] = { attr = kind.attr, levels = levels }
        end
      end
    end
    local sort_value = span.attributes["sort"]
    local levels, _, kept, depth =
      qi_marks.derive_levels(entry, visible, declared, #span.content, context,
                             sort_value, false)
    if levels == nil then
      return nil
    end
    -- The format-neutral self-target drop the emitting pass makes: a target
    -- naming the entry it is written on says nothing, and the mark then
    -- indexes as usual. Made here too, so what survives is what decides
    -- whether this mark contributes a locator at all.
    local own_key = qi_levels.levels_key(levels)
    local surviving = {}
    for _, xref in ipairs(xrefs) do
      if qi_levels.levels_key(xref.levels) ~= own_key then
        surviving[#surviving + 1] = xref
      end
    end
    local index_name =
      qi_indexes.mark_index(span.attributes[qi_indexes.INDEX_ATTR], context,
                            false)
    register_recovered_sort(sorts, index_name, levels, sort_value, context,
                            kept, depth)
    marks[#marks + 1] = {
      levels = levels,
      xrefs = surviving,
      context = context,
      -- Resolved against what the READING chapter declares, which for a book
      -- is the same `indexes:` metadata the recovered chapter read: the name
      -- is settled here rather than left for `fold_undeclared`, exactly as a
      -- mark's own chapter settles it.
      index = index_name,
      -- The id the mark's AUTHOR wrote, which is one of their own values and
      -- comes back like the rest of them; nothing here mints one, because a
      -- minted id is settled against the ids of the whole rendered page and
      -- this route sees one chapter's source. So `mark_target` builds a
      -- fragment where the author wrote an id and the chapter's bare page
      -- where they wrote none.
      --
      -- Only where this mark contributes a locator: a cross-reference mark
      -- carries an id as readily as any other span, and giving it an anchor
      -- would make it contribute a locator through the `mark.anchor or
      -- mark.page_locator` test in `html.lua`, which is the one thing it must
      -- not do.
      anchor = (in_blocks and #surviving == 0 and span.identifier ~= "")
        and span.identifier or nil,
      -- Kept beside the anchor rather than replaced by it: it is what says a
      -- recovered mark's locator is the chapter's PAGE, which is what makes
      -- `build_book_marks` write an href at all, and it still stands alone for
      -- a recovered mark whose author wrote no id. Without it a recovered mark
      -- is indistinguishable from a cross-reference mark, which has no anchor
      -- either and must contribute no locator.
      page_locator = #surviving == 0 or nil,
    }
    return nil
  end

  -- Metadata first and blocks second, which is the order the ordinary render
  -- sees them in — verified 2026-09-02 under pandoc 3.11, a filter table with
  -- a `Span` function is handed a span in `abstract:` before one in the body.
  -- The order is load-bearing and not decorative: `register_recovered_sort` is
  -- first-wins, so a sort key declared in front matter beats one declared in
  -- the body, and it must beat it here exactly where it beats it there. Two
  -- walks rather than one over a rebuilt document, so the order is this
  -- reader's own statement rather than a traversal order read off Pandoc.
  --
  -- Both sides go through the conditional-content removal, the metadata by
  -- `conditional_free_meta` and the blocks by `drop_conditional` in the
  -- caller. An author writes `.content-visible` and `.content-hidden` in
  -- front matter as readily as in the body, and this route cannot tell which
  -- way either went.
  conditional_free_meta(meta):walk({ Span = collect })
  in_blocks = true
  blocks:walk({ Span = collect })
  return marks, sorts
end

-- The indexes a chapter places, in the order it places them: one entry per
-- index, the first marker naming it holding the site, exactly as
-- `resolve_markers` settles it inside a rendering chapter. Top-level markers
-- alone — a nested one places nothing there and places nothing here. The
-- blocks are `drop_conditional`'s, so a marker Quarto would drop places
-- nothing here either.
local function recovered_markers(blocks)
  local names, seen = {}, {}
  for _, block in ipairs(blocks) do
    if qi_marker.is_marker(block) then
      local name =
        qi_indexes.authored_index(block.attributes[qi_indexes.INDEX_ATTR])
      if not seen[name] then
        seen[name] = true
        names[#names + 1] = name
      end
    end
  end
  return names
end

-- The chapter sources this route reads, lower-cased. A book's chapter files
-- are named by its author and listed by Quarto, which takes an `.ipynb`
-- chapter as readily as a `.qmd` one; the reader below is Pandoc's markdown
-- reader and nothing else, so what it may be handed is the markdown-source
-- extensions and no other kind. Handed a notebook it does not refuse: it
-- accepts the raw JSON as markdown, and what comes back is a mark whose
-- attribute values carry the JSON's own quoting — a term filed into whatever
-- index that mangled name resolves to, with nothing said. That was the
-- behavior through 0.2.0, recorded as a known issue and fixed here (M070).
local SOURCE_EXTENSIONS = {
  [".qmd"] = true,
  [".md"] = true,
  [".markdown"] = true,
  [".rmd"] = true,
}

-- Whether this route may read <file> at all: its own extension, lower-cased
-- so a chapter written `.Rmd` and one written `.rmd` are the same file kind.
-- A chapter whose name carries no extension is refused with the rest — there
-- is nothing to test it against, and guessing is the second reader this route
-- is not.
local function readable_source(file)
  local _, ext = pandoc.path.split_extension(file)
  -- `split_extension` returns the empty string, never nil, for a name that
  -- carries no extension (verified 2026-09-02 under pandoc 3.11), so the
  -- lookup below is the whole test: no entry answers to "".
  return SOURCE_EXTENSIONS[ext:lower()] == true
end

-- One chapter's record, rebuilt from its source, or nil where nothing could be
-- rebuilt. Every step that TOUCHES the file is inside one guard: it may be
-- gone, unreadable or something Pandoc's markdown reader refuses, and none of
-- that may take the render down with it (IP2). The file-kind test ahead of the
-- guard touches nothing — it reads the path string this route was handed —
-- which is the whole point of its being ahead of it. A failure returns nil and the caller reports it.
--
-- Two ways of returning nothing, because they are two different things to tell
-- an author: a source this route could not read as it hoped to, and a source
-- this route never offers to read. The second is the boolean, and the caller
-- names the file in a report of its own.
local function recover_record(ctx, file)
  if not readable_source(file) then
    return nil, true
  end
  local ok, record = pcall(function()
    local fh = io.open(pandoc.path.join({ ctx.root, file }), "r")
    if not fh then
      error("cannot open", 0)
    end
    local text = fh:read("a")
    fh:close()
    if text == nil then
      error("cannot read", 0)
    end
    local parsed = pandoc.read(text, "markdown")
    -- The conditional-content removal reaches both inputs, but not both here:
    -- the blocks are cleaned on the way in and the metadata is cleaned inside
    -- `recovered_marks`, which is also where the order of the two walks is
    -- stated. A second caller must pass `drop_conditional`'s blocks, as this
    -- one does, or it recovers body conditionals while still dropping
    -- front-matter ones.
    local blocks = drop_conditional(parsed.blocks)
    local marks, sorts = recovered_marks(parsed.meta, blocks)
    return { version = STORE_VERSION, file = file,
             href = chapter_href(ctx, file, parsed.meta),
             marker = recovered_markers(blocks),
             marks = marks, sorts = sorts }
  end)
  if not ok then
    return nil
  end
  return record
end

-- The chapters one report covers, as the text that stands where a single
-- chapter's name used to. Commas with a final "and", and never a newline: each
-- of these reports is one log line, and the scan that holds this extension's
-- messages mutually distinct refuses a message it cannot match line for line.
local function chapter_list(files)
  if #files <= 2 then
    return table.concat(files, " and ")
  end
  return table.concat(files, ", ", 1, #files - 1) .. " and " .. files[#files]
end

-- The one wording for a chapter whose source this route will not read, in one
-- place because it is drawn from three: inline, by the chapter that met the
-- record, where the record was opened and could not be used; and at the report
-- site, once per chapter that builds an index section, where the record was
-- written by another version of this extension (D-049) or where no render has
-- written it at all (M074). A second `warn()` call carrying these words would
-- be a second copy of them to keep in step, and the source scan that holds this
-- extension's messages mutually distinct would read the pair as one message
-- written twice.
--
-- `who` is one chapter's name, or several joined by `chapter_list`: the
-- never-written draw covers every such chapter of the render in one line, and
-- the other two sites pass the single chapter they met. The sentence says
-- "each such chapter" so that it is true of either.
local function warn_source_refused(who)
  qi_core.warn(("no record of the index marks for %s could be used, and each such chapter's source is not one this route reads — it reads a chapter written as .qmd, .md, .markdown or .Rmd source and no other kind — so none of its terms are in the index; render each again, or render the whole book, to restore them"):format(who))
end

-- Returns the usable records in book order, the chapters whose record this
-- version refused for being written by another one, and the chapters no render
-- has written a record for at all — the last two the caller's to report.
--
-- One pass, and only these three answers. M60 and M061 also asked which
-- chapters AFTER this one had no usable record, because a chapter then had to
-- work out whether it was the last one placing anything before it could take
-- on an index no marker names. M063 hands that index to the book's last
-- chapter, which every chapter names the same way from `ctx.chapters`, so no
-- chapter asks the store where the other markers are any more.
--
-- `own` is this chapter's own record, built in memory and spliced in at this
-- chapter's own position rather than read back off the disk: the store is read
-- BEFORE this chapter writes, which is the only moment these files still say
-- what the render found them saying, and a chapter reading its own file back
-- would see the state some earlier render left. It is also why nothing here
-- reports on this chapter's own file — there is no stale or unreadable record
-- of its own for it to find, whatever the write does afterwards.
--
-- `recover_absent` is the caller's answer to a question the store cannot be
-- asked: may a record NO render has written be recovered from its chapter's
-- source in this chapter? True for a chapter carrying a placement marker of
-- its own and for the book's last chapter — between them, every chapter that
-- can print an index section — and false everywhere else, so a chapter that
-- prints nothing pays nothing for a book whose store has never been written.
-- Both halves are settled before the store is opened, from `resolve_markers`
-- and from `ctx.position` against `ctx.chapters`, so no two chapters of one
-- render can disagree about either.
local function store_read(ctx, own, recover_absent)
  local records, stale = {}, {}
  -- The never-written chapters this render met, in book order, one list per
  -- wording. Handed back rather than reported here (M074): what such a record
  -- costs is a section's share of that chapter's terms, and only a chapter that
  -- builds a section — or one whose records show the book placing nothing —
  -- pays it. `recover_absent` admits a chapter that can print a section, which
  -- is not the same as one that does: the book's last chapter is admitted and
  -- builds nothing where every declared index is placed earlier. The caller
  -- knows which, and draws one line per list.
  local absent = { refused = {}, recovered = {}, lost = {} }
  -- One probe for this whole pass: a record this loop cannot open whose name
  -- is nonetheless in the listing of the directory it belongs in was not
  -- never-written, it is out of reach, and the source route is what it is for
  -- (D-043, D-044).
  local was_written = store_probe()
  for _, file in ipairs(ctx.chapters) do
    if file == ctx.file then
      records[#records + 1] = own
    else
      local path = store_path(ctx, file)
      local fh = io.open(path, "r")
      local unusable, never_written, ok, data = false, false, false, nil
      if fh then
        local text = fh:read("a")
        fh:close()
        ok, data = pcall(pandoc.json.decode, text, false)
        if ok and valid_record(data, file) then
          records[#records + 1] = data
        else
          unusable = true
        end
      elseif was_written(path) then
        unusable = true
      elseif recover_absent then
        -- Never written, and this chapter is one that can print a section, so
        -- the terms would otherwise be lost from the index it prints rather
        -- than merely absent from a page nobody reads.
        never_written = true
      end
      if unusable or never_written then
        -- Out of reach, which is the one case the source route is for: this
        -- record costs its chapter every term it marked, and the chapter's own
        -- source still says what its author wrote (D-041). Either the record
        -- was opened and could not be used, or it could not be opened while
        -- its own name stood in the listing of the directory it belongs in —
        -- the store directory itself being there and unlistable among those
        -- (D-043, D-044). A record that is simply ABSENT is the third case,
        -- and reaches here only in a chapter that can print a section
        -- (`recover_absent`): everywhere else it is read as absent exactly as
        -- it always was.
        local rebuilt, refused = recover_record(ctx, file)
        if rebuilt ~= nil then
          records[#records + 1] = rebuilt
        end
        -- Three outcomes, not two. A parse that succeeds and finds no mark
        -- at all is not a recovery: the chapter's terms are as absent as
        -- they were, and telling the author they came back sends them
        -- looking in the index for a term that is not there. It is the
        -- ordinary shape for a chapter whose marks arrive through an
        -- include shortcode or an executed cell, neither of which is in the
        -- file this route reads.
        local recovered = rebuilt ~= nil and #rebuilt.marks > 0
        -- Silent in one case only, the one below that says so. Everywhere
        -- else the fix is the same — render that chapter again — but WHY the
        -- record could not be used is not: a record left by an older version
        -- of this extension is perfectly readable and simply stale, one no
        -- render has written was never there at all, and calling either
        -- unreadable sends an author looking for a corrupt file that is not
        -- there. What recovery returned is a second axis, and each report
        -- says which case and which outcome its chapter had.
        --
        -- Two draw sites, split on the record's state and not on the wording.
        -- Two states are handed to the caller and drawn there, whether the
        -- chapter was refused or recovered, because what each costs is a
        -- section's share of that chapter's terms and only a chapter that
        -- builds a section pays it: a version-skewed record, and a record no
        -- render has written at all (M074). The states that are drawn HERE,
        -- by every chapter that reads the store, are the ones about a record
        -- that was there — listed and unopenable, opened but undecodable, and,
        -- since the test below narrowed, opened and decoding to a table
        -- carrying no version this render reads as a number, whose count moved
        -- to this site with its wording (D-051) — each at the count it has
        -- always had.
        -- A NUMBER other than the one this render writes, not merely "not
        -- equal to it". `~= STORE_VERSION` alone is satisfied by a record
        -- whose `version` is missing — `pandoc.json.decode` gives such a
        -- table a nil field, and nil is not the number — so a truncated or
        -- hand-emptied file that still decodes as a table was read as a
        -- record another version of this extension wrote, which asserts a
        -- version that is not in the file (KI236). What the field carries is
        -- the only evidence there is: a number this render does not write is
        -- a version, and anything else — absent, a string, a boolean — is a
        -- record whose bytes cannot be used, which is the wording it now
        -- takes. `valid_record` is unchanged and refuses both alike, so this
        -- test decides only which report the chapter draws.
        if ok and type(data) == "table" and type(data.version) == "number"
           and data.version ~= STORE_VERSION then
          -- Handed back rather than reported here, refused or not: a
          -- version-skewed record costs the chapters that BUILD an index their
          -- share of that chapter's terms, and every other chapter of the book
          -- reads the store without printing anything out of it. Reported by
          -- the caller, once per chapter that builds (M55), which is the count
          -- every wording about a version-skewed record follows — the
          -- refusal's included, since what it costs is the same thing (D-049).
          -- The `refused` flag is what the caller draws the refusal's own
          -- wording on, ahead of the three below and instead of them: a
          -- refused chapter says one thing, and never that its record was
          -- written by a different version (D-046's precedence clause).
          if refused then
            stale[#stale + 1] = { file = file, refused = true }
          else
            stale[#stale + 1] =
              { file = file, recovered = recovered, parsed = rebuilt ~= nil }
          end
        elseif never_written then
          -- Handed back, never drawn here (M074). A record no render has
          -- written costs the chapters that BUILD an index their share of
          -- that chapter's terms, exactly as a version-skewed one does, and
          -- `recover_absent` admits a chapter that CAN print a section rather
          -- than one that does: the book's last chapter is admitted and builds
          -- nothing where every declared index is placed earlier, and used to
          -- report every chapter of the book from there. The caller knows
          -- whether this chapter builds; this loop does not.
          --
          -- One list per wording, and the caller draws each list as one line
          -- naming every chapter on it. Three outcomes reach here and a fourth
          -- does not: a source that PARSED and reached no mark is passed over
          -- in silence, because it is the ordinary shape for a chapter of a
          -- book whose store has never been written — every chapter marking
          -- nothing is one — and it has lost nothing, so reporting it would
          -- fire for most of a correct book on every render.
          --
          -- The refusal is its own list and stands ahead of the other two at
          -- the caller, one wording for all of them: what the record was
          -- decides nothing an author can act on, the source cannot stand in
          -- for it whichever it was, and the fix is the same one. A refused
          -- source was never read, so nothing here knows whether it marks a
          -- term; staying silent would be a guess, and the guess costs the
          -- author every term of that chapter with no way to find out.
          if refused then
            absent.refused[#absent.refused + 1] = file
          elseif recovered then
            absent.recovered[#absent.recovered + 1] = file
          elseif rebuilt ~= nil then
            -- Silent, and the one outcome that adds nothing to any list.
          else
            absent.lost[#absent.lost + 1] = file
          end
        elseif refused then
          -- Drawn here, by this chapter, for the record states that are about
          -- a record that WAS there: listed and unopenable, opened but
          -- undecodable, and — since the test above narrowed — opened and
          -- decoding to a table that carries no version this render reads as a
          -- number (D-051). Those are the states whose own sibling wordings
          -- are drawn here too, once per chapter that reads the store, so the
          -- refusal follows the count of the reports it stands in for. Ahead
          -- of every branch below, and one wording for all of them. What the
          -- record was decides nothing an author can act on here: the source
          -- cannot stand in for it whichever it was, and the fix is the same
          -- one. A refused chapter therefore says this and nothing else.
          --
          -- "No record could be used" rather than "the recorded marks could
          -- not be used": the same words are drawn on the never-written path
          -- at the caller, where there is no record to have failed, and one
          -- wording covering both must send no author looking for a corrupt
          -- file that was never there.
          warn_source_refused(file)
        elseif recovered then
          qi_core.warn(("the recorded index marks for %s could not be read, so that chapter's terms were recovered from its own source instead; they are in the index without the links into its page that a record carries, without anything reaching that chapter through an include or an executed cell, and without anything inside a block or span Quarto shows or hides by format, profile or metadata — render that chapter again, or render the whole book, to restore them"):format(file))
        elseif rebuilt ~= nil then
          qi_core.warn(("the recorded index marks for %s could not be read, and that chapter's own source carries no index mark this route can reach, so none of its terms are in the index; a mark that reaches that chapter through an include or an executed cell, or that sits inside a block or span Quarto shows or hides by format, profile or metadata, is not one this route reads — render that chapter again, or render the whole book, to restore them"):format(file))
        else
          qi_core.warn(("the recorded index marks for %s could not be read and neither could that chapter's own source, so none of its terms are in the index; render that chapter again, or render the whole book, once both files can be read"):format(file))
        end
      end
    end
  end
  return records, stale, absent
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
        -- Set only on a mark recovered from a chapter's source, and on a
        -- front-matter mark of an HTML book chapter: it says this mark
        -- contributes a locator whether or not it carries an anchor, and that
        -- its locator names the chapter's page. Without it a recovered mark
        -- carrying no author id is indistinguishable from a cross-reference
        -- mark, which has no anchor either and must contribute no locator.
        page_locator = mark.page_locator,
        -- The chapter's own resolved role, which is all a book needs now that
        -- nothing pairs here: a mark carries whatever role its own chapter
        -- concluded for it.
        role = mark.role,
        -- This chapter's own verdict, carried through untouched: a range whose
        -- two marks are in one chapter pairs there, and its closing
        -- contributes no locator here either.
        paired = mark.paired,
        -- A mark in the chapter holding the index links within its own page,
        -- exactly as a single document's does — except a page locator, whose
        -- whole target is the page: with no anchor to link within, it names
        -- its own page the way a page locator in any other chapter does.
        -- Written exactly as Quarto writes its own links to that page,
        -- raw rather than percent-escaped: Quarto normalizes a link target
        -- either way, so an escape here is undone before it reaches output
        -- (its own sidebar link to a space-named chapter is `./a b.html`).
        href = (record.file ~= ctx.file or mark.page_locator)
          and relative_href(ctx, record.href) or nil,
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
  -- Built before the store is read, and written unchanged further down. The
  -- copy is what the aggregation reads, because `fold_undeclared` rewrites the
  -- record it walks (`record_for_reading`).
  local record = build_record(ctx, marker)
  local reading = record_for_reading(record)
  -- May this chapter recover a record no render has written? Only where the
  -- terms would otherwise be lost from a section this chapter itself prints:
  -- a chapter carrying a placement marker of its own, and the book's last
  -- chapter, which takes on every index no marker names. Both are settled
  -- here, before the store is opened — `marker` is what `resolve_markers`
  -- left of this chapter's own source, and the position is the render list
  -- Quarto hands every chapter — so no two chapters of one render can reach
  -- different answers, and no chapter that prints nothing parses the rest of
  -- the book to find that out.
  local records, stale, absent =
    store_read(ctx, reading, #marker > 0 or ctx.position == #ctx.chapters)
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

  -- The indexes THIS chapter builds, and the first chapter of the book that
  -- places anything. `first` draws the reports that are about the book rather
  -- than about one section, so a book placing three indexes in three chapters
  -- still reports each of them once. Where the LAST placement site stands is
  -- no longer asked: M60 and M061 handed an index no marker names to the last
  -- chapter that placed one, a position each chapter derived from a different
  -- mixture of this render's records and the previous render's and so
  -- disagreed about within one render.
  local mine, first = {}, nil
  for _, name in ipairs(qi_indexes.names()) do
    local at = placing[name]
    if at ~= nil then
      if first == nil or at < first then first = at end
      if at == ctx.position then
        mine[name] = true
      end
    end
  end
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
  -- An index no marker names goes to the book's LAST chapter, provided some
  -- chapter of the book places one. Every chapter of every render names that
  -- chapter the same way — it is the end of `ctx.chapters`, the render list
  -- Quarto hands each process — so no two chapters of one render can disagree
  -- about which of them owes the section, and no render can print it in two
  -- chapters. The proviso keeps the single document's rule: a book whose
  -- author wrote no marker anywhere is a book asking for no index, and its
  -- last chapter grows no section either. `first` is read off the records this
  -- chapter could read plus its own marker, so a last chapter that carries no
  -- marker and can read no placing chapter's record concludes the book places
  -- nothing and builds no section (KI214).
  --
  -- Where the last chapter carries no marker of its own, `place_index`
  -- appends the section at the end of that chapter's body; where it carries
  -- one, the section follows the ones its own markers place, in declared
  -- order.
  if first ~= nil and ctx.position == #ctx.chapters then
    for _, name in ipairs(qi_indexes.names()) do
      if placing[name] == nil then
        mine[name] = true
        builds = true
      end
    end
  end

  -- The one write of this chapter's own record. `store_read` skips this
  -- chapter's own path, so nothing above depends on the write happening after
  -- it; the position is kept because the aggregation above runs over the copy
  -- (`reading`) rather than over the table going to disk.
  store_write(ctx, record)

  -- The three reports about a record this render could not build out of as it
  -- stands: one refused for its version, one refiled because it names an index
  -- this book no longer declares, and one no render has written at all (M074).
  -- All three cost the same thing — a section's share of that chapter's terms
  -- — so all three are drawn on the same rule, at one site (M062). A chapter
  -- whose source this route will not read arrives among the first and the
  -- third — flagged in the first, a list of its own in the third, and never
  -- among the second, which no refused chapter can reach — and is drawn here
  -- on that same rule when its record was written by another version (D-049)
  -- or was never written; where the record was there and could not be used,
  -- that chapter drew its refusal where it met it.
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
    for _, entry in ipairs(stale) do
      if entry.refused then
        -- Ahead of the three below and instead of them. This chapter's source
        -- is not one the recovery route reads, so nothing was read back and
        -- nothing is known about what it marked; the record's own version
        -- decides nothing the author acts on differently, and a refused
        -- chapter says one thing (D-046's precedence clause, D-049).
        warn_source_refused(entry.file)
      elseif entry.recovered then
        qi_core.warn(("the recorded index marks for %s were written by a different version of this extension, so that chapter's terms were recovered from its own source instead; they are in the index without the links into its page that a record carries, without anything reaching that chapter through an include or an executed cell, and without anything inside a block or span Quarto shows or hides by format, profile or metadata — render that chapter again, or render the whole book, to restore them"):format(entry.file))
      elseif entry.parsed then
        qi_core.warn(("the recorded index marks for %s were written by a different version of this extension, and that chapter's own source carries no index mark this route can reach, so none of its terms are in the index; a mark that reaches that chapter through an include or an executed cell, or that sits inside a block or span Quarto shows or hides by format, profile or metadata, is not one this route reads — render that chapter again, or render the whole book, to restore them"):format(entry.file))
      else
        qi_core.warn(("the recorded index marks for %s were written by a different version of this extension and that chapter's own source could not be read, so none of its terms are in the index; render that chapter again, or render the whole book, once its source can be read"):format(entry.file))
      end
    end
    for _, entry in ipairs(refiled) do
      qi_core.warn(('the recorded index marks for %s name the index "%s", which this book does not declare; they are filed in the first index it does declare, and their sort keys with them — render that chapter again, or render the whole book, once the %s: metadata is settled'):format(entry.file, entry.name, qi_indexes.INDEXES_KEY))
    end
    -- ...and the records no render has written, one line per wording naming
    -- every chapter that wording covers (M074). Once per wording rather than
    -- once per chapter: a chapter reading a cold store meets every other
    -- chapter of the book at once, and nothing about where it sits tells a
    -- first whole-book render from a single-chapter render, so volume is the
    -- only axis left. The refusal stands first, ahead of the two below and
    -- instead of them for the chapters on its list, the precedence a refused
    -- chapter has wherever it is drawn (D-046).
    if #absent.refused > 0 then
      warn_source_refused(chapter_list(absent.refused))
    end
    if #absent.recovered > 0 then
      -- "Could not be read" would be false here: there is no file to read,
      -- and an author sent looking for a corrupt record would find nothing.
      qi_core.warn(("no render has written a record of the index marks for %s; each such chapter's terms were recovered from its own source instead, and are in the index without the links into its page that a record carries, without anything reaching that chapter through an include or an executed cell, and without anything inside a block or span Quarto shows or hides by format, profile or metadata — render each again, or render the whole book, to restore them"):format(chapter_list(absent.recovered)))
    end
    if #absent.lost > 0 then
      -- The never-written family's third outcome: no record, and no source to
      -- stand in for it either. Its own sentence rather than the lost wording
      -- for a record that WAS written, which says the record "could not be
      -- read" and so asserts a file no render ever made (KI230). Its opening
      -- clause is its own: the recovery wording just above opens with words
      -- the suite greps that report by, and a shared opening would make one
      -- key count both reports.
      qi_core.warn(("no record of the index marks for %s has been written by any render, and each such chapter's own source could not be read either, so none of its terms are in the index; render each again, or render the whole book, once its source can be read"):format(chapter_list(absent.lost)))
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
M["output_extension"] = output_extension
M["chapter_href"] = chapter_href
M["store_path"] = store_path
M["build_record"] = build_record
M["record_for_reading"] = record_for_reading
M["store_write"] = store_write
M["valid_record"] = valid_record
M["fold_undeclared"] = fold_undeclared
M["recovered_marks"] = recovered_marks
M["recovered_markers"] = recovered_markers
M["recover_record"] = recover_record
M["store_read"] = store_read
M["book_sort_keys"] = book_sort_keys
M["book_sort_for"] = book_sort_for
M["book_marks"] = book_marks
M["report_book_dangling"] = report_book_dangling
M["marker_chapter"] = marker_chapter
M["any_marks"] = any_marks
M["html_book"] = html_book

return M
