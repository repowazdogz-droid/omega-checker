# REPORT — Phase 1 (con-leche) — 2026-09-12

Candidate submission: commit `f6299d79a05c7390d2322161581e851a281cf48a` on branch `omega`
(tag `phase1-candidate`), a fork of intgrah/sokonanoda at the Arena revision `7b51784`.
Build: `cargo build --release` (the Arena YAML in `arena-checker.yaml` uses the same
PGO + `target-cpu=native` recipe as the sokonanoda and mathgraph entries).

## Root cause of the con-leche "reject"

The Arena recorded sokonanoda `7b51784` as *rejecting* the con-leche export (rev `86cd20a`)
with exit 1 and empty stderr. That result is not a kernel verdict. Locally the unmodified
checker **accepts** the byte-identical export (exit 0) with a 27.4 GB peak RSS; on the Arena
runner every checker that reaches roughly 15.2 GB RSS dies at that point (kiota on cedar:
exit 137; sokonanoda and zignodamus on con-leche: exit 1, empty stderr, because their run
lines end in `|| exit 1`, which masks the signal). The memory comes from one declaration:
`ConLeche.checkIotaThmN_inv` allocates about 32 GB in a single check session, because
`key_env` in `eval.rs` returned the environment *unpruned* whenever a closure body had more
than 64 loose bound variables (`if k > 64 { return env }`). That theorem hits the cutoff
191,336,199 times (max 160 loose variables); ordinary tests hit it zero times. Unpruned
environments defeat closure and frame sharing, so the bump arena (reset only between
declarations) grows without bound. The fix is exact pruning past 64 variables via "wide
framed" environments, ported commit-by-commit with original authorship (Heath Sanchez,
Metalogic Labs, Apache-2.0) from mathgraph, plus one local change that keeps `key_env`
small enough to inline. Nothing in the kernel checks was disabled, loosened or special-cased;
export metadata is not trusted anywhere new.

The runner kill line is inferred from the Arena's own results table, not observed directly.
The reproduction here is: same bytes, accept locally, 27 GB peak, above that line.

## Verdicts vs the official kernel (v4.34.0-rc2), this machine

Tarball `lean-arena-tests.tar.gz` (last-modified 2026-09-11 23:27 UTC): 119 good, 73 bad.

| set | expected | official | baseline `7b51784` | candidate `f6299d7` |
|---|---|---|---|---|
| bad/ (scored reject) | 73 reject | 73/73 reject | 73/73 | 73/73 |
| good/ (scored accept, excl. corner) | 118 accept | 118/118 accept | 118/118 | 118/118 |
| good/corner-cases (unscored) | either | 1 accept | 1 accept | 1 accept |
| declines / errors | 0 | 0 | 0 | 0 |

Exports not in the tarball, regenerated with the Arena's own `lka.py build-test` (byte counts
equal to the Arena's where the Arena publishes them):

| export | bytes (local = Arena) | official | baseline | candidate |
|---|---|---|---|---|
| con-leche rev 86cd20a (the recorded reject) | 559,853,093 = yes | accept | accept, 27.4 GB, 588 G instr | accept, 6.2 GB, 177 G |
| con-leche rev 3e00480 (current Arena yaml) | 567,612,971 (Arena: n/a) | accept (27,552 decls) | accept, 15.8–28 GB | accept, 6.3 GB, 183 G |
| init | 324,561,407 = yes | accept (54,472) | not run | accept, 0.7 GB, 54 G |
| std | 551,674,936 = yes | accept (93,046) | not run | accept, 1.2 GB, 88 G |
| perf/magma-string-n4 | 17,248,623 | accept | not run | accept |
| perf/magma-string-pair-n9 | 17,250,845 | accept | not run | accept |
| mathlib | 5,636,308,621 / 100,001,405 lines = yes | accept (670,627 decls) | accept | accept |

Not run locally: cedar (791 MB) and cslib (2.0 GB) — they need full builds of cedar-spec and
cslib and disk was at 10–16 GB free. The Arena shows sokonanoda `7b51784` accepting both; the
candidate has not been checked on them here.

The candidate agrees with official v4.34.0-rc2 on all 192 tarball tests and on the six extra
exports listed above. This is agreement on those inputs, not a soundness claim.

## Mathlib cost (this machine: M4 Max, plain `cargo build --release`, 4 threads, runs alone)

Instruction counts are from macOS `/usr/bin/time -l` ("instructions retired", ARM). They are
comparable only to each other, not to the Arena's x86 numbers. Run-to-run noise is about
±0.5% (baseline: 900.2 / 895.3 / 895.1 G; wide build: 933.8 / 934.4 / 934.0 G).

| build | instructions | vs base | peak RSS | wall |
|---|---|---|---|---|
| sokonanoda `7b51784` (base) | 895 G | — | 8.6 GB | 37.5 s |
| + instrumentation only (`843f439`) | 895 G | +0.0% | 8.6 GB | 34.9 s |
| + wide frames as ported (`d181d7b`) | 934 G | +4.3% | 8.6 GB | 35.5 s |
| + `key_env` cold path outlined (`f6299d7`, candidate) | 912 G | +1.9% | 8.6 GB | 35.2 s |
| mathgraph `d6a7327` (Arena leader) | 970 G | +8.4% | 8.6 GB | 36.8 s |
| official v4.34.0-rc2 (1 thread) | 12,119 G | +1254% | 8.2 GB | 1983 s |

What the +4.3% was and was not: it is not the wide path executing (with the path compiled in
but never entered, Mathlib still costs 931 G), and it is not the 8-byte growth of `Env`
(boxing the wide payload back to 64 bytes: 933 G). Outlining the over-64 block out of the
`#[inline] key_env` recovers half (912 G). Outlining the wide arm of `Env::lookup` recovers
nothing (912 G). The remaining +1.9% is **not attributed**; it is inside the 2% line the brief
set, so the recovery loop stopped there.

Projection to the Arena (assumption: the ratio transfers from ARM to x86): sokonanoda's Arena
count 791 G × 912/895 ≈ 806 G, against mathgraph's 834 G, a margin of about 3.4%. Under the
brief's rule that is a thin margin (<5%), so Phase 2 was run under the frozen rule in
`PHASE2-PREREG.md`.

## Phase 2 (closed by its stop rule)

Keep rule: gate clean with extras, and Mathlib instructions at or below 0.99× the candidate on
two runs. Three mutations, three discards, then the stop rule fired:

| mutation | Mathlib | verdict |
|---|---|---|
| M1 upstream sokonanoda `ceaabb5` (no wide port) | 897 G, RSS 7.8 GB | discard: no instruction gain over base; 0.8 GB less RSS noted |
| M2 mathgraph `801cb6d` equal-hint unfolding | 910.5 G | discard: within noise |
| M3 lazily allocated wide caches | 910.6 G | discard: within noise |

The candidate is unchanged at `f6299d7`. The residual +1.9% over the base remains
unattributed. Build-recipe parity needs no work: the fork already has mimalloc and fat LTO,
and the Arena YAML applies the same PGO + `target-cpu=native` recipe as the sokonanoda and
mathgraph entries.

Peak RSS on con-leche is 6.3 GB, and on Mathlib 8.6 GB locally (the Arena measured 7.2 GB for
the base build on its allocator; the fix does not change Mathlib RSS here).

## What was done, in order

1. Oracle: official checker built at v4.34.0-rc2 from the Arena repo; mathgraph built at its
   Arena rev `d6a7327` (branch dulce-de-leche); nanoclo cloned as fallback (unused).
2. `scripts/gate.sh`: runs all tarball tests through the candidate and the oracle, fails on any
   mismatch, decline or error; oracle verdicts cached per tarball. Baseline run recorded with
   stderr for every test in `~/lean-arena/gate-out-baseline/`.
3. Instrumentation: every panic during a declaration check now prints the declaration index
   and name (the original process had no message on this reject because there was no panic);
   `SOKO_TRACE=<ms>` prints slow declarations and how often pruning was skipped.
4. Trace on con-leche named `checkIotaThmN_inv` (88 s, 32 GB in one session). Reduced export of
   that theorem and its cone (34 MB): base 354 G / 28 GB; mathgraph 21.5 G / 2.4 GB; official
   36 G / 0.1 GB. Counter: 191 M skipped prunes, max 160 loose variables.
5. Ported mathgraph's four wide-frame commits with `git am` (authorship preserved). Reduced
   export: 20.7 G / 2.4 GB, 0 skipped prunes. Gate clean. Both con-leche revs accepted.
6. Mathlib cost isolated by single-variable builds as tabulated above; candidate chosen.

## Not claimed

"Sound" is not claimed. The claim is: agrees with official v4.34.0-rc2 on all 186 scored
tarball tests (and the 1 corner case, 6 extra exports) on this machine. Instruction counts are
local ARM measurements; the Arena's ranking will come from its own x86 run. cedar and cslib
are unverified locally. The kernel-kill explanation for the Arena result is inferred from the
Arena's results table, not observed on the runner.
