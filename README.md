# rosetta-shell

> A lossless shell/environment **translation layer** — write one script, run it
> natively in **bash 3.2 ↔ zsh ↔ POSIX sh** (and ksh) with byte-identical
> behavior. Think i18n, but for shells: **service localization** for scripts.

**License:** MIT · **Status:** v0.1.0 (draft) · **Locales verified:** bash 3.2.57,
bash 5.3, zsh 5.9, dash (POSIX), /bin/sh, ksh93 — all against one shared
[conformance suite](conformance/).

**In one line:** the constructs that silently break a script when it moves
environments — associative arrays, `${v,,}`, arrays, `echo -e`, process
substitution — get one portable shim each, and a conformance runner proves the
shim produces *identical* output in every shell present.

---

## The problem

The trigger is concrete and everyday:

- **bash 3.2** (the version Apple still ships at `/bin/bash`, frozen at the last
  GPLv2 release) has **no associative arrays** and **no `${v,,}`** case expansion.
- **macOS default shell is zsh**, whose word-splitting and array indexing differ
  from bash.
- **CI and containers** run whatever POSIX `sh` (often dash/ash) — **no arrays at
  all**, no `local` in the standard, no bashisms.
- **ksh93** has arrays but rejects `local`.

A script authored on a modern bash laptop breaks the moment it lands on any of
these. rosetta-shell is the phrasebook that makes the script speak each locale.

## The four moving parts

| Part | What it is | Command / API |
|---|---|---|
| **rosetta.sh** | sourceable shim library — a lossless portable map + case/echo/split shims | `. lib/rosetta.sh` |
| **doctor** | localizes your environment: which shell, which native features missing | `rosetta doctor` |
| **lint** | scans a script for non-portable constructs, names the shim to use (advisory, never rewrites) | `rosetta lint FILE…` |
| **conformance** | runs fixtures under every installed shell and asserts byte-identical stdout — the losslessness proof | `rosetta selftest` |

## Quick start

```sh
# See what locale you're in and what's missing:
bin/rosetta doctor

# Prove losslessness across every shell on this host:
bin/rosetta selftest

# Flag non-portable constructs in your own scripts:
bin/rosetta lint path/to/script.sh
```

In your own script:

```sh
. /path/to/rosetta-shell/lib/rosetta.sh

# Associative array that works in bash 3.2 AND POSIX sh:
rosetta_map_set env REGION us-east
rosetta_map_set env "feature flag" on
rosetta_map_get env REGION            # -> us-east
rosetta_map_keys env                  # -> insertion-ordered, one per line

rosetta_lower "ARCS"                   # -> arcs   (no bash4 ${v,,} needed)
```

The map is **byte-lossless**: keys and values may contain spaces, tabs, quotes,
newlines, unicode, and shell metacharacters, and round-trip unchanged (verified
in [`conformance/fixtures/edge_values.sh`](conformance/fixtures/edge_values.sh)).

## How losslessness is defined

A fixture is **lossless** iff its stdout is *byte-identical* under every shell
locale present. The [conformance runner](conformance/run.sh) hashes each shell's
output and fails on any divergence. This is the same "one shared suite, many
implementations" discipline germinate uses — here the "implementations" are the
shells themselves.

## Conformance & the germinate family

rosetta-shell is a **Tier-A candidate** in the open ARCS / flashesofbrilliance
family: it declares conformance to the germinate seed contract and ships its own
[`SEED.md`](SEED.md). The lineage is germinate's *private rosetta stone*
(redaction-by-reference) — this repo extends that same public-method / private-
priors seam from redaction to **shell/environment translation**. See
[`CONFORMANCE.md`](CONFORMANCE.md).

## Design principles

- **Lossless or it fails.** No "close enough" — byte-identical across locales.
- **Advisory, never destructive.** `lint` names the fix; it never rewrites your
  script. The construct→shim table is explicit and inspectable.
- **Written in the intersection.** The library itself uses only the portable
  subset (see [`CONFORMANCE.md`](CONFORMANCE.md) §"The one extension").
- **No dependencies.** Pure shell + coreutils (`printf`, `od`, `tr`, `cksum`).

---

*Part of the ARCS / flashesofbrilliance family. The translation **method** here is
open; any environment-specific priors stay private. The animating spark stays
private.*
