# tlfi — the French lexical check on this repo's French index words

**Provenance.** Ingested 2026-08-29 by M057 from the *Trésor de la langue
française informatisé* as served by the CNRTL, retrieved by `curl` on
2026-08-29 from `https://www.cnrtl.fr/definition/<headword>` (`voir`, `index`,
`symbole`, `aussi`).
Pagination: —.
Extraction: verified 2026-08-29 against the retrieved pages, each wording read from the sense it is attributed to — observed 2026-08-29.

**Citation.** *Trésor de la langue française informatisé* (TLFi), ATILF —
CNRS & Université de Lorraine, served through the Centre National de
Ressources Textuelles et Lexicales, cnrtl.fr. Entries cited by headword and by
the sense label the entry itself prints (roman numeral, letter, number).

**Role.** The lexical half of the two-reference check on the French row of
M057's word table. Larousse was tried first and dropped: its entries are keyed
by opaque numeric id, and a guessed id silently serves a neighbouring article
rather than failing, so a value read from it could be a value read from the
wrong word.

## Extracted values

- `INDEX, subst. masc.`, sense II.B.1 — "Liste alphabétique des sujets traités,
  des noms (propres, communs, géographiques, grammaticaux, etc.) étudiés ou
  cités dans un ou des ouvrages, accompagnés de références permettant de les
  localiser", given the synonym "table alphabétique". This is the back-of-book
  sense, and the one the table ships the word for.
- `VOIR` — the reference use, under the sense "Prendre pour exemple, se
  reporter à": at the infinitive, "Synon. de confer (abrév. cf...)". `voir` in
  the imperative-or-infinitive sending a reader elsewhere is the same use this
  extension's `see` label has.
- `SYMBOLE, subst. masc.`, sense II.A.4 (linguistics, after Saussure) — "Signe
  dont le signifiant a un lien naturel avec le signifié"; the entry's own
  senses run from the religious formula through the sign. The plural of the
  headword is `symboles`.
- `AUSSI 1, adv.` — the entry's opening gloss: "Exprime l'idée que deux entités
  différentes (au- issu de aliud) présentent une identité (-si issu de sic)."
  It is the additive adverb, which is what `voir aussi` needs it to be.

## Traces to

- `cairn/references/index-words-by-language.md` — the lexical column of the
  four French rows of the per-word ledger.
- `_extensions/index/modules/languages.lua` — the French row, indirectly,
  through that ledger.

## Open questions

- The TLFi is a closed corpus, last revised well before this repo existed, so
  it attests established usage rather than current preference. Nothing here
  depends on it being current — observed 2026-08-29.
