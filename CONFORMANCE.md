# Conformance

rosetta-shell makes two conformance claims and backs each mechanically.

## 1. Losslessness across shell locales (internal)

**Claim:** every fixture in [`conformance/fixtures/`](conformance/fixtures/)
produces **byte-identical stdout** under every shell locale installed on the
host.

**Proof:** `sh conformance/run.sh` (or `rosetta selftest`) runs each fixture
under each shell, hashes the output with `cksum`, and fails on any divergence.

Verified locales (this dev host, 2026-08-13):

| Locale | Version | Notable gap it exercises |
|---|---|---|
| `/bin/bash` | 3.2.57 | no associative arrays, no `${v,,}` |
| `bash` | 5.3.9 | reference modern bash |
| `zsh` | 5.9 | word-splitting / array-indexing differences |
| `/bin/dash` | POSIX | no arrays, no `local` in the standard |
| `/bin/sh` | 3.2.57 | bash in POSIX mode |
| `ksh` | 93u+ | arrays but rejects `local` |

Result: **2 fixtures × 6 locales, byte-identical.**

### The one extension

The library uses `local` for function-scoped temporaries. `local` is not POSIX,
but is supported by bash/zsh/dash/ash/ksh-function-form. Where a shell rejects it
(strict POSIX `sh`, ksh93), the library installs a **no-op `local`** (via `eval`,
so shells that reject `local` as a function name never parse the definition).
Scoping then degrades to global; internal temporaries use a collision-resistant
`_r*` naming so output stays identical. This is why the losslessness claim covers
ksh and strict POSIX, not just the big four.

### What "lossless" covers

The portable map (`rosetta_map_*`) round-trips keys **and** values containing
spaces, tabs, quotes, newlines, unicode, and shell metacharacters — see
[`conformance/fixtures/edge_values.sh`](conformance/fixtures/edge_values.sh). The
only byte no shell variable can hold is NUL, which is out of scope for every
shell.

## 1a. Portability of a caller's script (the gate)

`rosetta crossrun SCRIPT` runs an arbitrary target script under every installed
shell locale and reports a pass/fail matrix. This is the primary product surface:
it *proves* a script's portability by execution rather than inferring it from
regex (which is what `lint` does, advisory-only).

- Default verdict: a locale passes iff the script exits 0 there.
- `--identical`: additionally require byte-identical stdout across locales —
  catches the insidious case where a shell runs the script but does the wrong
  thing (e.g. bash 3.2 silently mishandling `declare -A` instead of erroring,
  which the exit check alone would miss).

Exit 1 on any failure, so it is a drop-in CI step
([`.github/workflows/portability.yml`](.github/workflows/portability.yml)).

## 2. germinate seed conformance (family, Tier-A)

**Claim:** [`SEED.md`](SEED.md) is a valid germinate seed and behaves correctly
in germinate's `sprout` router.

**Proof:**
- Its frontmatter validates against germinate's
  [`spec/seed.schema.json`](../germinate/spec/seed.schema.json) (required
  `kind` / `soil` / `provenance` present; `provenance` is an object).
- germinate's `germinate.seed.sprout` **surfaces** it on matching contexts
  ("bash 3.2 and zsh portability" → score 3; "service localization" → score 2)
  and keeps it **dormant** on non-matching contexts ("react component") — verified
  against the live germinate Python implementation.

This makes rosetta-shell an **interop node** in the open family: its seed can be
moved/planted/sprouted by any germinate-conformant tool.

## Boundary (ADR-053)

The translation **method** — every shim, the map encoding, the conformance
runner — is open. Any environment-specific priors or tenant rosetta tables stay
private and are never committed here. Public method / private rosetta: the same
seam germinate draws for redaction-by-reference, here applied to shell/env
translation.
