---
kind: seed
schema_version: 1
id: rosetta-shell-localization
seed_type: problem-shape
soil:
  - cross-shell script portability
  - cross-env script portability
  - service localization
  - bash 3.2
  - zsh
  - posix
tags:
  - shell
  - portability
  - rosetta
  - localization
  - conformance
antipatterns:
  - single-target-runtime
  - "modern-bash-only"
provenance:
  minted_from: "ARCS phase-2 bash3.2-vs-zsh friction, 2026-08-13"
  note: "generic, clean-room — no client specifics"
  lineage: "germinate private-rosetta (redaction-by-reference), extended to shell/env translation"
lineage:
  parents:
    - germinate-private-rosetta
triggers:
  - a script breaks across bash 3.2 / zsh / POSIX
  - porting a tool to a new host environment
care: >
  Keep the conformance suite green across every shell present; add a fixture
  BEFORE a new shim. The losslessness claim is only as good as the suite.
applications:
  - lossless shell translation
  - service localization
  - rosetta-by-reference for environments
---
# rosetta-shell — lossless shell/environment translation

**Surfaces when** your context mentions cross-shell portability, `bash 3.2`,
`zsh`, `posix`, or "service localization" (see `soil`). **Suppressed** for
single-runtime / modern-bash-only contexts (see `antipatterns`) — there is no
second locale to translate to, so the shape would be over-build.

The problem shape: a script authored against one shell's features (associative
arrays, `${v,,}`, arrays, `echo -e`) silently breaks when it moves to another
shell locale. The fix is a **rosetta layer** — one portable shim per divergent
construct — plus a **conformance test** that proves each shim yields byte-
identical output across every shell present. Portability becomes provable, and a
script gets "localized" to each environment the way a UI gets localized to a
language.

This is the germinate *private rosetta stone* concept (public method / private
priors) extended from redaction-by-reference to shell/environment translation.
