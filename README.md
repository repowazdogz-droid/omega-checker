# About

This is a fork of [sokonanoda](https://github.com/intgrah/sokonanoda)
(Apache-2.0). Changes in this fork:

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

Currently, it is about 9x faster than the official kernel, measured on mathlib.

Basically, the core conversion algorithm is entirely replaced by something closure-based. There are also some non-theoretical, purely programming optimisations.
