# Phase 2 preregistration — frozen 2026-09-12 before any Phase 2 result was read

Question: can Mathlib instruction count be reduced below the Phase 1 candidate
(f6299d7: 912 G local ARM, ±0.5% noise) without changing any verdict?

Pinned: candidate f6299d7; tarball last-modified 2026-09-11 23:27 UTC; oracle =
official v4.34.0-rc2; exports as listed in REPORT.md (byte counts recorded there);
config = Arena config (4 threads, nat+string extensions). Measurement = one
`/usr/bin/time -l` run on this machine with nothing else heavy running; a
candidate keep is re-measured once more before being accepted.

Keep rule (all required): scripts/gate.sh PASS with the six extra exports;
Mathlib instructions <= previous candidate x 0.99 (two noise widths) on both
measurements; peak RSS on Mathlib <= 8.7 GB and on con-leche <= 7 GB locally.
Anything that changes any verdict or declines anything is discarded regardless.
One mutation per commit; a discarded mutation is recorded, not silently dropped.

Stop: after 6 mutations evaluated, or 3 consecutive discards, or when the
projected Arena margin (791 x ratio-to-base vs 834) reaches 5%.

Mutations queued with predictions (P = predicted effect on Mathlib instructions):
1. Rebase onto upstream sokonanoda ceaabb5 ("delete binder names and plicity").
   P: exploratory; upstream perf work, direction unknown, verdict risk unknown.
   (Launched before this file was written: deviation.)
2. mathgraph 801cb6d "equal-hint unfolding for short asymmetric spines".
   P: within noise (|change| <= 1%). (Launched before this file: deviation.)
3. Attribute the remaining +1.9% structural cost of the wide-frame port
   (candidates: extra match arms in prune_env / prune_env_cold, frames table
   find closure, TcCache growth). P: recoverable in part, <= 1.5%.
4-6. From a sampling profile of the candidate on Mathlib, top self-time
   functions; chosen after 1-3 and recorded here before measuring.

Falsifiers of the framing: a mutation that lowers instructions but raises RSS
past the bound (the runner kills at ~15 GB); a mutation whose gain does not
reproduce on the second measurement.
Not claimed under any outcome: soundness; Arena x86 numbers; cedar/cslib.

## Log
- M1 ceaabb5 (upstream master, no wide port): 897.0 G, RSS 7.79 GB. DISCARD: no
  instruction gain vs base 895 G (RSS drop of 0.8 GB noted; not a keep criterion).
- M2 801cb6d equal-hint: 910.5 G vs candidate 912 G. DISCARD: within noise, as predicted.
