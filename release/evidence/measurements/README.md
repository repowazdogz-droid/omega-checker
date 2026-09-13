# Preserved ARM measurements

Source: macOS `/usr/bin/time -l` on Apple Silicon (M4 Max), 2026-09-12.
Method: `instructions retired` field from stderr captures.

**Important:** No raw stderr artifact links the Mathlib run to candidate commit
`f6299d7`. The preserved omega-checker Mathlib file reports
933,795,598,537 instructions retired. Any other Mathlib instruction totals
previously written in prose (including 912 G) are **not** backed by files here
and must not be cited.

## Files

| File | Instructions retired | Peak RSS (bytes) |
|---|---:|---:|
| `sokonanoda-mathlib.stderr` | 900,157,551,455 | 8,611,201,024 |
| `omega-checker-mathlib.stderr` | 933,795,598,537 | 8,590,704,640 |
| `mathgraph-mathlib.stderr` | 970,290,083,154 | (see file) |
| `official-mathlib.stderr` | 12,118,869,062,178 | (see file) |
| `omega-checker-con-leche.stderr` | 182,748,787,318 | 6,313,213,952 |
| `omega-checker-con-leche-86cd20a.stderr` | 177,334,258,364 | (see file) |
| `sokonanoda-con-leche-86cd20a.stderr` | 587,542,981,013 | (see file) |
| `extra-init.ndjson.stderr` | 54,179,772,119 | (see file) |
| `extra-std.ndjson.stderr` | 88,143,240,191 | (see file) |

These counts are **OBSERVED ARM** only. They are not comparable to Arena x86
instruction counts without remeasurement on the Arena runner.
