# REPORT — omega-checker release — 2026-09-13

Semantic candidate: commit `f6299d79a05c7390d2322161581e851a281cf48a` on branch
`omega` (tag `phase1-candidate`), forked from intgrah/sokonanoda at Arena
revision `7b51784`.

Release packaging (evidence, NOTICE, manifest) may add commits after `f6299d7`
without changing checker semantics. See `RELEASE_MANIFEST.md`.

Build: `cargo build --release` locally; the Arena YAML in `arena-checker.yaml`
uses the PGO + `target-cpu=native` recipe shared with sokonanoda and mathgraph
entries.

Attribution: see `NOTICE.md` for sokonanoda, nanoda lineage, and mathgraph wide-frame port authorship.

## Root cause of the con-leche "reject"

The Arena recorded sokonanoda `7b51784` as *rejecting* the con-leche export (rev
`86cd20a`) with exit 1 and empty stderr. That result is not a kernel verdict.
Locally the unmodified checker **accepts** the byte-identical export (exit 0)
with a 27.4 GB peak RSS; on the Arena runner every checker that reaches roughly
15.2 GB RSS dies at that point (kiota on cedar: exit 137; sokonanoda and
zignodamus on con-leche: exit 1, empty stderr, because their run lines end in
`|| exit 1`, which masks the signal). The memory comes from one declaration:
`ConLeche.checkIotaThmN_inv` allocates about 32 GB in a single check session,
because `key_env` in `eval.rs` returned the environment *unpruned* whenever a
closure body had more than 64 loose bound variables (`if k > 64 { return env }`).
That theorem hits the cutoff 191,336,199 times (max 160 loose variables);
ordinary tests hit it zero times. Unpruned environments defeat closure and frame
sharing, so the bump arena (reset only between declarations) grows without bound.
The fix is exact pruning past 64 variables via "wide framed" environments,
ported commit-by-commit with original authorship from mathgraph, plus one local
change that keeps `key_env` small enough to inline. Nothing in the kernel
checks was disabled, loosened or special-cased; export metadata is not trusted
anywhere new.

The runner kill line is inferred from the Arena's own results table, not
observed directly on the runner (**PROJECTED Arena / unobserved locally**). The
reproduction here is: same bytes, accept locally, 27 GB peak, above that line.

## Verdicts vs the official kernel (v4.34.0-rc2), this machine

Tarball `lean-arena-tests.tar.gz` (last-modified 2026-09-11 23:27 UTC): 119
good, 73 bad. Frozen artifacts: `release/evidence/gate/`.

| set | expected | official | baseline `7b51784` | candidate `f6299d7` |
|---|---|---|---|---|
| bad/ (scored reject) | 73 reject | 73/73 reject | 73/73 | 73/73 |
| good/ (scored accept, excl. corner) | 118 accept | 118/118 accept | 118/118 | 118/118 |
| good/corner-cases (unscored) | either | 1 accept | 1 accept | 1 accept |
| declines / errors | 0 | 0 | 0 | 0 |

Exports not in the tarball, regenerated with the Arena's own `lka.py build-test`
(byte counts equal to the Arena's where the Arena publishes them):

| export | bytes (local = Arena) | official | baseline | candidate |
|---|---|---|---|---|
| con-leche rev 86cd20a (the recorded reject) | 559,853,093 = yes | accept | accept, 27.4 GB, 588 G instr | accept, 6.2 GB, 177 G |
| con-leche rev 3e00480 (current Arena yaml) | 567,612,971 (Arena: n/a) | accept (27,552 decls) | accept, 15.8–28 GB | accept, 6.3 GB, 183 G |
| init | 324,561,407 = yes | accept (54,472) | not run | accept, 0.7 GB, 54 G |
| std | 551,674,936 = yes | accept (93,046) | not run | accept, 1.2 GB, 88 G |
| perf/magma-string-n4 | 17,248,623 | accept | not run | accept |
| perf/magma-string-pair-n9 | 17,250,845 | accept | not run | accept |
| mathlib | 5,636,308,621 / 100,001,405 lines = yes | accept (670,627 decls) | accept | accept |

### cedar and cslib — unverified locally

**Not run locally:** cedar (791 MB export) and cslib (2.0 GB export). They
require full builds of cedar-spec and cslib; disk was at 10–16 GB free during
Phase 1. The Arena results table shows sokonanoda `7b51784` accepting both on
the runner; the candidate has **not** been checked on cedar or cslib on this
machine or on the Arena runner under this fork. Any performance or verdict
claim for cedar/cslib is **unverified** until measured.

The candidate agrees with official v4.34.0-rc2 on all 192 tarball tests and on
the six extra exports listed above. This is agreement on those inputs, not a
soundness claim.

## Performance — OBSERVED ARM (this machine)

**Platform:** MacBook M4 Max, macOS, plain `cargo build --release`, 4 threads,
runs alone.

**Method:** `/usr/bin/time -l` → `instructions retired` field. Raw stderr files
in `release/evidence/measurements/`. Counts are comparable only to each other
on this machine, **not** to Arena x86 numbers.

| build | instructions retired | peak RSS | source file |
|---|---:|---:|---|
| sokonanoda `7b51784` (base) | 900,157,551,455 (~900 G) | 8.6 GB | `sokonanoda-mathlib.stderr` |
| omega-checker fork (Mathlib) | 933,795,598,537 (~934 G) | 8.6 GB | `omega-checker-mathlib.stderr` |
| mathgraph `d6a7327` | 970,290,083,154 (~970 G) | 8.6 GB | `mathgraph-mathlib.stderr` |
| official v4.34.0-rc2 (1 thread) | 12,118,869,062,178 (~12,119 G) | 8.2 GB | `official-mathlib.stderr` |

**Removed claim:** A Mathlib total of 912 G for candidate commit `f6299d7` was
previously reported in prose. **No raw stderr artifact supports that number.**
It is not cited in this release. The only preserved omega-checker Mathlib ARM
measurement is 933,795,598,537 instructions retired; the artifact does not
record which git commit was built.

Con-leche (OBSERVED ARM, preserved): omega-checker accepts rev 3e00480 at
182,748,787,318 instructions retired and 6.3 GB peak RSS
(`omega-checker-con-leche.stderr`).

## Performance — PROJECTED x86 / Arena (not observed locally)

The Arena runner measures x86 instruction counts with `perf`. Published Arena
results (2026-09-11 snapshot) include, for Mathlib:

| checker | Arena Mathlib instructions | source |
|---|---:|---|
| sokonanoda `7b51784` | ~791 G | Arena results table |
| mathgraph `d6a7327` | ~834 G | Arena results table |

These are **PROJECTED x86 / Arena** figures. They were **not** remeasured on
this ARM machine. Do not treat ARM ratios above as transferring to Arena x86
without a runner remeasurement.

No Arena x86 Mathlib number exists yet for this omega-checker fork. Ranking
relative to mathgraph on the Arena is **unverified** until the fork is built
and run on the Arena runner.

## Phase 2 (closed by its stop rule)

Keep rule: gate clean with extras; Mathlib instructions at or below 0.99× prior
candidate on two runs; RSS bounds. Three mutations, three discards, stop rule
fired. Details in `PHASE2-PREREG.md`.

**Evidence note:** Phase 2 mutation Mathlib totals (897 G, 910.5 G, 910.6 G) were
logged in prose only. No raw stderr artifacts for those runs are preserved.
They are listed as **unverified** in `RELEASE_MANIFEST.md`.

The semantic candidate remains `f6299d7`. Build-recipe parity needs no work: the
fork already has mimalloc and fat LTO, and the Arena YAML applies the same PGO +
`target-cpu=native` recipe as the sokonanoda and mathgraph entries.

## What was done, in order

1. Oracle: official checker built at v4.34.0-rc2 from the Arena repo; mathgraph
   built at its Arena rev `d6a7327` (branch dulce-de-leche); nanoclo cloned as
   fallback (unused).
2. `scripts/gate.sh`: runs all tarball tests through the candidate and the
   oracle, fails on any mismatch, decline or error; oracle verdicts cached per
   tarball. Release copy in `release/evidence/gate/`.
3. Instrumentation: every panic during a declaration check now prints the
   declaration index and name; `SOKO_TRACE=<ms>` prints slow declarations and
   how often pruning was skipped.
4. Trace on con-leche named `checkIotaThmN_inv` (88 s, 32 GB in one session).
   Reduced export of that theorem and its cone (34 MB): base 354 G / 28 GB;
   mathgraph 21.5 G / 2.4 GB; official 36 G / 0.1 GB. Counter: 191 M skipped
   prunes, max 160 loose variables.
5. Ported mathgraph's four wide-frame commits with `git am` (authorship
   preserved). Reduced export: 20.7 G / 2.4 GB, 0 skipped prunes. Gate clean.
   Both con-leche revs accepted.
6. Mathlib cost measured on ARM; preserved stderr files listed above.

## Not claimed

"Sound" is not claimed. The claim is: agrees with official v4.34.0-rc2 on all
186 scored tarball tests (and the 1 corner case, 6 extra exports) on this
machine, with frozen artifacts under `release/evidence/gate/`.

**Unverified:** cedar, cslib, Arena x86 Mathlib ranking, candidate-commit-linked
Mathlib ARM total (912 G removed), Phase 2 mutation Mathlib totals without raw
files. Kernel-kill explanation for the Arena con-leche result is inferred from
the Arena's results table, not observed on the runner.
