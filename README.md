# About

This is a fork of [sokonanoda](https://github.com/intgrah/sokonanoda)
(Apache-2.0). See `NOTICE.md` for full attribution (sokonanoda lineage,
mathgraph wide-frame port). Release evidence: `RELEASE_MANIFEST.md`.

Changes in this fork:

- Exact environment pruning past 64 loose bound variables ("wide framed
  environments"), ported commit-by-commit with original authorship from
  [mathgraph](https://github.com/metalogiclabs/mathgraph-lean-kernel)
  (Metalogic Labs, Apache-2.0). Without it, one con-leche theorem
  (`ConLeche.checkIotaThmN_inv`) allocates about 32 GB in a single check.
- Every rejection names the declaration being checked when the panic fired.
- `SOKO_TRACE=<ms>` prints declarations whose check took at least `<ms>` ms.
- `scripts/gate.sh` runs the Lean Kernel Arena tarball against the official
  kernel and fails on any verdict mismatch, decline or error.

The original README follows.


This is an experimental fork on top of:
- [nanoda_lib](https://github.com/ammkrn/nanoda_lib)
- [sonanoda](https://github.com/datokrat/sonanoda)
- [still-nanoda](https://github.com/SchrodingerZhu/still-nanoda)

It is essentially a testing bed for high-performance typechecking for Lean.

You shouldn't use this for serious purposes.

On Mathlib, OBSERVED ARM instruction counts for this fork vs the official
kernel are in `release/evidence/measurements/` and `REPORT.md`. Arena x86
ranking is **not** claimed until remeasured on the Arena runner.

Basically, the core conversion algorithm is entirely replaced by something closure-based. There are also some non-theoretical, purely programming optimisations.
