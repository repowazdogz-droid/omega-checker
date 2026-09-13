# 192-test verdict gate artifacts

Tarball: `lean-arena-tests.tar.gz` (last-modified 2026-09-11 23:27 UTC).

| Artifact | Lines | Role |
|---|---:|---|
| `candidate-verdicts.tsv` | 192 | Exit codes from candidate at semantic commit `f6299d7` |
| `oracle-verdicts.tsv` | 192 | Exit codes from official kernel v4.34.0-rc2 |
| `stderr/` | 384 files | Per-test stderr: 192 candidate + 192 oracle |

Oracle and candidate agree on all 192 scored tests (118 accept, 73 reject, 1
corner case with no prescribed label). Regenerate with `scripts/gate.sh` from
repo root; these files are the frozen release copy.
