# RELEASE_MANIFEST — omega-checker

**Status:** Pre-publish (repository not yet on GitHub). **Do not publish.**

## Commits

| Role | SHA | Notes |
|---|---|---|
| **semantic_candidate** | `f6299d79a05c7390d2322161581e851a281cf48a` | Checker semantics frozen here (`phase1-candidate` tag) |
| **release_commit** | `5b2113cbab32754ce01f42d33ae5abc7dc175a85` | Full release bundle (evidence + manifest); no `src/` changes after semantic candidate |
| evidence_bundle | `7ed4ff48dd92a96718056af47f671a8e3dde1bde` | First packaging commit (subset of release_commit) |

## Repository URL (pre-publish)

Intended public fork: `https://github.com/wazdogz/omega-checker` (branch `omega`).

Before Arena submission:

1. Push branch `omega` to that URL (or update `arena-checker.yaml` and this manifest).
2. Set `arena-checker.yaml` → `rev` to `release_commit` below.
3. Copy `arena-checker.yaml` into the Arena repo `checkers/` tree.

## Artifact inventory (key files)

Full tree under `release/evidence/` — 399 files at release commit.

| Artifact | SHA-256 |
|---|---|
| `release/evidence/gate/candidate-verdicts.tsv` | `639955ccef80f707bbed9510fb1071b6aa7f27a660e2d58727078c0c10ec900e` |
| `release/evidence/gate/oracle-verdicts.tsv` | `7df72b59cc51dceb8610440be0c53aa48a805bf0a7e9c592f65fd9cff4ebcf81` |
| `release/evidence/measurements/sokonanoda-mathlib.stderr` | `af196480d4d656a51decf496037ec9728c03cba0045351c5879c90ae31698367` |
| `release/evidence/measurements/omega-checker-mathlib.stderr` | `0fd02f27d083b0073813a95628585d3a4a2d293f20799df5de5687f0c801f962` |
| `release/evidence/measurements/mathgraph-mathlib.stderr` | `92bc1ac20a53160c123caa73b5b0acf5648d06bbe381b8b2dcd10fb230a0a9ca` |
| `NOTICE.md` | `4c0b31963b5f1300bf1d92d5f9ac96ee1c34e6516bf4649b2276a9ad64754c1c` |
| `REPORT.md` | `7b40c2d32331d6547b2191fcde01024f8d28df7417f7e6a862bd8c31cdf6e33e` |

Gate bundle: 192 candidate verdicts + 192 oracle verdicts + 384 stderr captures.

## Exact supported claims

1. **Verdict agreement (local, frozen):** Candidate at semantic commit `f6299d7`
   matches official kernel v4.34.0-rc2 on all 192 tarball tests (118 accept,
   73 reject, 1 unscored corner case). Evidence: `release/evidence/gate/`.
2. **Extra exports (local):** Accepts con-leche (both revs), init, std, both
   magma perf exports, and mathlib — as documented in `REPORT.md`.
3. **OBSERVED ARM instruction counts** with raw stderr files in
   `release/evidence/measurements/` (Mathlib, con-leche, init, std, comparators).
4. **Root-cause account** for Arena con-leche reject at sokonanoda `7b51784`
   (memory / OOM inference from Arena table + local reproduction).
5. **Attribution** per `NOTICE.md` (sokonanoda lineage + mathgraph wide-frame port).

## Exact unverified claims

1. **912 G Mathlib ARM** for candidate `f6299d7` — **withdrawn** (no raw artifact).
2. **Phase 2 mutation Mathlib totals** (897 G, 910.5 G, 910.6 G) — prose only,
   no preserved stderr.
3. **Candidate-commit-linked Mathlib ARM total** — preserved omega-checker Mathlib
   file (933,795,598,537 instr) does not record build commit.
4. **cedar and cslib** — not run locally; Arena verdicts for baseline sokonanoda
   only, not this fork.
5. **Arena x86 Mathlib ranking** — no runner measurement for this fork; published
   sokonanoda (~791 G) and mathgraph (~834 G) figures are **PROJECTED x86 / Arena**,
   not OBSERVED ARM.
6. **ARM→x86 ratio projection** (e.g. 791 × ratio) — removed; not supported without
   runner remeasurement.
7. **Soundness** — not claimed.

## Performance labelling rule

Public-facing statements must distinguish:

- **OBSERVED ARM** — `/usr/bin/time -l` on M4 Max, files under `release/evidence/measurements/`
- **PROJECTED x86 / Arena** — Arena results table or extrapolation; not locally observed
