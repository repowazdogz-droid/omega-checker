# NOTICE — omega-checker

## This fork

omega-checker is a fork of
[sokonanoda](https://github.com/intgrah/sokonanoda) (Apache-2.0), maintained
for Lean Kernel Arena submission. Semantic candidate commit:
`f6299d79a05c7390d2322161581e851a281cf48a`.

## Inherited upstream work

This repository inherits code, design, and documentation from:

- **sokonanoda** — https://github.com/intgrah/sokonanoda (Apache-2.0)
- **nanoda_lib** — https://github.com/ammkrn/nanoda_lib
- **sonanoda** — https://github.com/datokrat/sonanoda
- **still-nanoda** — https://github.com/SchrodingerZhu/still-nanoda

Original sokonanoda authorship and license terms apply to unmodified portions.

## Ported mathgraph work (wide framed environments)

Exact environment pruning past 64 loose bound variables ("wide framed
environments") was ported commit-by-commit from
[mathgraph-lean-kernel](https://github.com/metalogiclabs/mathgraph-lean-kernel)
(Metalogic Labs, Apache-2.0). Original authorship on those commits is
preserved in git history (Heath Sanchez, Metalogic Labs).

Local changes on top of the port:

- Outlined the over-64-loose-variable path of `key_env` into a cold function
  (candidate commit `f6299d7`).
- Every rejection names the declaration being checked when the panic fired.
- `SOKO_TRACE=<ms>` optional tracing for slow declarations.

## License

Apache-2.0, consistent with sokonanoda and mathgraph-lean-kernel.

See `LICENSE` and per-file copyright headers where present.
