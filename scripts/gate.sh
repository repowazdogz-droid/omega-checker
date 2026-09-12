#!/usr/bin/env bash
# gate.sh — verdict gate for the Arena tarball.
# Runs every good/*.ndjson and bad/*.ndjson through the candidate checker and
# compares (a) against the tarball label and (b) against the official Lean
# kernel checker (v4.34.0-rc2), whose verdicts are cached once per tarball.
# Exit non-zero on ANY mismatch against the label, ANY disagreement with the
# oracle, or ANY decline (exit 2) or error (exit >2 / timeout) anywhere.
# Corner-case tests (good/corner-cases) have no prescribed outcome: they are
# reported, and fail the gate only on decline/error.
#
# Usage: scripts/gate.sh [candidate-binary] [extra.ndjson:expected ...]
#   env: TESTS (tarball dir), OFFICIAL (oracle binary), CONFIG (json), JOBS, TIMEOUT
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CAND="${1:-$ROOT/target/release/sokonanoda}"; shift || true
TESTS="${TESTS:-$HOME/lean-arena/tests}"
OFFICIAL="${OFFICIAL:-$HOME/lean-arena/arena/checkers/official/.lake/build/bin/kernel}"
CONFIG="${CONFIG:-$HOME/lean-arena/config.json}"
JOBS="${JOBS:-8}"
TIMEOUT="${TIMEOUT:-900}"
OUT="${OUT:-$HOME/lean-arena/gate-out}"
ORACLE="$TESTS/.oracle-verdicts.tsv"
mkdir -p "$OUT/stderr"
[ -x "$CAND" ] || { echo "candidate not executable: $CAND"; exit 3; }
[ -x "$OFFICIAL" ] || { echo "official oracle not executable: $OFFICIAL"; exit 3; }
[ -f "$CONFIG" ] || { echo "missing config: $CONFIG"; exit 3; }

list_tests() { (cd "$TESTS" && find good bad -name '*.ndjson' | sort); }

# --- oracle cache -----------------------------------------------------------
if [ ! -s "$ORACLE" ]; then
  echo "building oracle cache with $OFFICIAL ..."
  list_tests | xargs -P "$JOBS" -I{} sh -c '
    f="$1"; t0=$(date +%s)
    timeout '"$TIMEOUT"' "'"$OFFICIAL"'" "'"$TESTS"'/$f" >/dev/null 2>"'"$OUT"'/stderr/oracle-$(echo "$f" | tr / _).txt"
    rc=$?; printf "%s\t%s\t%s\n" "$f" "$rc" "$(( $(date +%s) - t0 ))"' _ {} > "$ORACLE.tmp"
  sort "$ORACLE.tmp" > "$ORACLE"; rm -f "$ORACLE.tmp"
  echo "oracle cache: $(wc -l < "$ORACLE") verdicts"
fi

# --- candidate --------------------------------------------------------------
CANDV="$OUT/candidate-verdicts.tsv"
list_tests | xargs -P "$JOBS" -I{} sh -c '
  f="$1"; t0=$(date +%s)
  timeout '"$TIMEOUT"' "'"$CAND"'" "'"$CONFIG"'" < "'"$TESTS"'/$f" >/dev/null 2>"'"$OUT"'/stderr/$(echo "$f" | tr / _).txt"
  rc=$?; printf "%s\t%s\t%s\n" "$f" "$rc" "$(( $(date +%s) - t0 ))"' _ {} > "$CANDV.tmp"
sort "$CANDV.tmp" > "$CANDV"; rm -f "$CANDV.tmp"

# --- extras (big exports not in the tarball), given as path:accept|reject -----
for spec in "$@"; do
  f="${spec%%:*}"; exp="${spec##*:}"
  t0=$(date +%s)
  timeout "$TIMEOUT" "$CAND" "$CONFIG" < "$f" >/dev/null 2>"$OUT/stderr/extra-$(basename "$f").txt"; rc=$?
  want=0; [ "$exp" = reject ] && want=1
  printf "EXTRA\t%s\t%s\t%ss\n" "$(basename "$f")" "$rc" "$(( $(date +%s) - t0 ))"
  [ "$rc" = "$want" ] || echo "EXTRA MISMATCH: $f expected $exp got exit $rc"
  [ "$rc" = "$want" ] || echo "$f" >> "$OUT/extra-fail"
done

# --- compare ----------------------------------------------------------------
python3 - "$ORACLE" "$CANDV" "$OUT" <<'PY'
import sys
oracle=dict((l.split('\t')[0], int(l.split('\t')[1])) for l in open(sys.argv[1]).read().splitlines() if l)
cand={}; times={}
for l in open(sys.argv[2]).read().splitlines():
    if not l: continue
    f,rc,t=l.split('\t'); cand[f]=int(rc); times[f]=int(t)
def verdict(rc): return 'accept' if rc==0 else 'reject' if rc==1 else 'decline' if rc==2 else f'error({rc})'
fails=[]; n_good=n_bad=n_corner=0; ok_good=ok_bad=0; corner={}
oracle_vs_label=[]
for f in sorted(cand):
    label='accept' if f.startswith('good/') else 'reject'
    corner_case=f.startswith('good/corner-cases/')
    v=verdict(cand[f]); ov=verdict(oracle.get(f,-9))
    if corner_case:
        n_corner+=1; corner[f]=(v,ov)
        if v in ('decline',) or v.startswith('error'): fails.append(f'{f}: corner-case {v}')
        continue
    if label=='accept': n_good+=1
    else: n_bad+=1
    if ov!=label: oracle_vs_label.append(f'{f}: oracle={ov} label={label}')
    if v==label:
        if label=='accept': ok_good+=1
        else: ok_bad+=1
    else:
        fails.append(f'{f}: candidate={v} label={label} oracle={ov}')
    if v!=ov and v==label:
        fails.append(f'{f}: candidate={v} oracle={ov} (label={label})')
print(f'scored accept: {ok_good}/{n_good}   scored reject: {ok_bad}/{n_bad}   corner-cases run: {n_corner}')
from collections import Counter
print('corner-case verdicts (candidate vs oracle):', Counter(corner.values()))
slow=sorted(times.items(), key=lambda x:-x[1])[:5]
print('slowest:', ', '.join(f'{f}={t}s' for f,t in slow))
if oracle_vs_label:
    print('ORACLE DISAGREES WITH TARBALL LABEL:'); print('\n'.join('  '+x for x in oracle_vs_label))
if fails:
    print('GATE FAIL:'); print('\n'.join('  '+x for x in fails)); sys.exit(1)
print('GATE PASS')
PY
rc=$?
[ -f "$OUT/extra-fail" ] && { echo "GATE FAIL (extras)"; rm -f "$OUT/extra-fail"; exit 1; }
exit $rc
