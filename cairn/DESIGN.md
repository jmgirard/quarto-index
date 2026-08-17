# Design

## Purpose & Scope

quarto-index is a Quarto extension for book-quality subject indexing: authors
mark index entries with a format-neutral span syntax, and per-format back-ends
realize the index — LaTeX/PDF first, HTML and others to follow. **The marking
syntax is the product; output formats are back-ends** (a future format request
is in-scope work, not someone else's problem).

Audience: the general Quarto community from day one — documentation, tests,
and edge-case coverage are commitments, not extras. The capability roster is
**completeness-driven**: the target is a full indexing suite — cross-references
(see/see also), page-range & styling control, multiple named indexes, sort
keys, an HTML back-end, and multi-file book support — not a minimal personal
tool.

Distribution ambition (declared at init 2026-08-16): **tagged public
releases**, with changelog discipline from the start; at first release, submit
to the Quarto extension listing and aim for discoverability — README and
examples are a discovery surface, held to that bar. Release timing stays
user-declared. Toolchain profile: generic (see `cairn/PROFILE.md`).

## Contract boundary

- The extension's job **ends at correct emitted output for each supported
  format** (e.g., correct `\index{}` marks and preamble LaTeX). Whether the
  user's toolchain then builds the index (makeindex runs, engine config) is a
  documentation surface — known failure modes documented, never detected or
  managed; imakeidx's automatic makeindex run covers the common path.
- Index-mark values (`entry=` and successors) are **structured, format-neutral
  data** the extension parses and realizes per format — never raw back-end
  code passed through.
- Quarto version support is part of the contract: a stated minimum version in
  `_extension.yml` and README, eventually CI-tested against the floor and
  latest.

## Function Families

_None yet — populated as the codebase takes shape._

## Conventions

- Numeric results carry **no oracle-verification commitment** (declared at
  init, 2026-08-16): the universal ≥2-independent-oracle-types bar is waived;
  numeric results, if any arise, are checked ad hoc. Revisit if scoring or
  statistical work enters the project.
- **Pure Pandoc-Lua, self-contained**: the extension ships as Lua files with
  zero runtime dependencies beyond Quarto itself; LaTeX-side needs stay
  limited to imakeidx (bundled in TeX distributions). `quarto add` is the
  entire install story.
- **API stability**: the span syntax is fluid until the first tagged release;
  from then on, documented syntax forms change only via a deprecation cycle.
- **Unicode posture**: non-ASCII terms must always appear correctly in the
  index (an escaping/encoding commitment); collation beyond what the user's
  index processor provides is best-effort, aided by sort keys.

## Design Principles

<!-- IP<n> = Inviolable (hard constraint) block first, then GP<n> = Guiding
     (tradeable with justification); numbers never reused. Principles are
     elicited from the user (`/design-interview`), never invented. -->

_None formalized yet — Phase 2 of the design interview (2026-08-16) works from
the banked ledger below; this interim section is replaced at write-out._

### Banked principle candidates (design-interview 2026-08-16, interim ledger)

1. Community-grade quality — docs, tests, and edge-case coverage are
   commitments, not extras (from: audience = general community from day one).
2. The syntax carries format-neutral meaning — LaTeX is the first back-end,
   not the definition (from: boundary = full indexing suite).
3. Marked text never silently corrupts or breaks a build (from: confirmed
   warts — LaTeX escaping edge cases incl. `@ ! |` active inside `\index{}`,
   version drift, toolchain variance).
4. Entry values are structured data the extension interprets, never raw
   back-end code (from: entry= design round; amends M01's raw pass-through).
5. Syntax fluid pre-release; documented forms deprecation-cycled from first
   tagged release (from: API-stability round).
6. A stated Quarto version floor, eventually CI-tested, is part of the
   contract (from: version-floor round).
7. The extension's job ends at correct emitted output per format; toolchain
   behavior beyond that is a documentation surface (from: toolchain round).
8. Pure Pandoc-Lua, self-contained; `quarto add` is the whole install story
   (from: dependency round).
9. Non-ASCII terms appear correctly as a commitment; collation is best-effort
   with sort keys (from: Unicode round).
10. README and examples are discovery surface, held to listing quality (from:
    distribution round).

## Architecture

_None yet — describes the system as it **is**, once it exists._

## Known issues

_None._
