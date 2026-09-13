# Phase 2 preregistration — frozen 2026-09-12 before any Phase 2 result was read

Question: can Mathlib instruction count be reduced below the Phase 1 candidate
without changing any verdict?

Pinned: semantic candidate `f6299d7`; tarball last-modified 2026-09-11 23:27 UTC;
oracle = official v4.34.0-rc2; exports as listed in REPORT.md (byte counts
recorded there); config = Arena config (4 threads, nat+string extensions).
Measurement = one `/usr/bin/time -l` run on this machine with nothing else heavy
running; a candidate keep is re-measured once more before being accepted.

Keep rule (all required): scripts/gate.sh PASS with the six extra exports;
Mathlib instructions <= previous candidate x 0.99 (two noise widths) on both
measurements; peak RSS on Mathlib <= 8.7 GB and on con-leche <= 7 GB locally.
Anything that changes any verdict or declines anything is discarded regardless.
One mutation per commit; a discarded mutation is recorded, not silently dropped.

Stop: after 6 mutations evaluated, or 3 consecutive discards, or when the
projected Arena margin (791 G sokonanoda vs 834 G mathgraph on the runner)
reaches 5% — **PROJECTED x86 / Arena**, not OBSERVED ARM.

Mutations queued with predictions (P = predicted effect on Mathlib instructions):
1. Rebase onto upstream sokonanoda ceaabb5 ("delete binder names and plicity").
   P: exploratory; upstream perf work, direction unknown, verdict risk unknown.
   (Launched before this file was written: deviation.)
2. mathgraph 801cb6d "equal-hint unfolding for short asymmetric spines".
   P: within noise (|change| <= 1%). (Launched before this file: deviation.)
3. Attribute the remaining structural cost of the wide-frame port
   (candidates: extra match arms in prune_env / prune_env_cold, frames table
   find closure, TcCache growth). P: recoverable in part, <= 1.5%.
4-6. From a sampling profile of the candidate on Mathlib, top self-time
   functions; chosen after 1-3 and recorded here before measuring.

Falsifiers of the framing: a mutation that lowers instructions but raises RSS
past the bound (the runner kills at ~15 GB); a mutation whose gain does not
reproduce on the second measurement.
Not claimed under any outcome: soundness; Arena x86 numbers; cedar/cslib.

## Log

- M1 ceaabb5 (upstream master, no wide port): reported 897.0 G, RSS 7.79 GB.
  **No raw stderr preserved.** DISCARD: no instruction gain vs preserved base
  900 G (`sokonanoda-mathlib.stderr`); RSS drop of 0.8 GB noted; not a keep
  criterion.
- M2 801cb6d equal-hint: reported 910.5 G. **No raw stderr preserved.**
  DISCARD: within noise, as predicted.
- M3 lazily allocated wide caches: reported 910.6 G; reduced export 20.2 G /
  2.4 GB. **No raw stderr preserved.** DISCARD: within noise. Prediction
  (<= 1.5% recoverable) NOT met.
- STOP: three consecutive discards. Semantic candidate remains `f6299d7`.

## Evidence repair (2026-09-13)

A Mathlib total of 912 G for candidate `f6299d7` appeared in early Phase 2
prose. **No raw ARM measurement artifact supports 912 G.** The only preserved
omega-checker Mathlib stderr reports 933,795,598,537 instructions retired
(`release/evidence/measurements/omega-checker-mathlib.stderr`); build commit not
recorded in the file. That 912 G figure is withdrawn from all release-bound
documents.
