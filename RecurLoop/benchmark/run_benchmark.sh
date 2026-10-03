#!/bin/sh
# Performance comparison: pure Python, NumPy, Rust and RecurLoop.
# Every configuration runs REPEATS times; the best compute time measured
# inside the program is reported.
#
# Usage: ./run_benchmark.sh [path/to/recurloop]
set -eu
cd "$(dirname "$0")"
RECURLOOP="${1:-${RECURLOOP:-recurloop}}"
REPEATS="${REPEATS:-3}"
BUILD="${TMPDIR:-/tmp}/quantum-bench"
mkdir -p "$BUILD"
LOG="$BUILD/results.log"
: > "$LOG"

echo "Building Rust..."
rustc -C opt-level=3 -C target-cpu=native bench.rs -o "$BUILD/bench_rs"

# Runs a command and appends its result lines labelled with the implementation.
run() {
    label="$1"
    shift
    "$@" | sed "s/^/$label /" >> "$LOG"
}

i=0
while [ "$i" -lt "$REPEATS" ]; do
    i=$((i + 1))
    echo "Repeat $i of $REPEATS..."
    for variant in div bit; do
        run "rust-$variant" "$BUILD/bench_rs" "$variant" teleport 100000
        run "rust-$variant" "$BUILD/bench_rs" "$variant" layers 16 5
        run "rust-$variant" "$BUILD/bench_rs" "$variant" layers 20 5
    done
    start=$(date +%s%N)
    run recurloop "$RECURLOOP" --file bench.rl
    end=$(date +%s%N)
    echo "recurloop process time_ms=$(( (end - start) / 1000000 ))" >> "$LOG"
    run python-pure python3 bench.py pure teleport 100000
    run python-pure python3 bench.py pure layers 16 5
    run python-pure python3 bench.py pure layers 20 5
    run numpy python3 bench.py numpy teleport 100000
    run numpy python3 bench.py numpy layers 16 5
    run numpy python3 bench.py numpy layers 20 5
done

echo
echo "Checksums (must be identical for every implementation):"
grep layers "$LOG" | sed 's/ time_ms=.*//' | sort -u

echo
echo "Best compute time in ms:"
awk '
{
    impl = $1; test = $2
    if (test == "layers") { split($3, a, "="); test = "layers-" a[2] }
    for (f = 1; f <= NF; f++) if ($f ~ /^time_ms=/) { split($f, c, "="); t = c[2] + 0 }
    key = impl SUBSEP test
    if (!(key in best) || t < best[key]) best[key] = t
    impls[impl] = 1; tests[test] = 1
}
END {
    printf "%-12s %12s %12s %12s %12s\n", "", "teleport", "layers-16", "layers-20", "process"
    n = split("python-pure numpy rust-div rust-bit recurloop", order, " ")
    for (k = 1; k <= n; k++) {
        impl = order[k]
        printf "%-12s", impl
        m = split("teleport layers-16 layers-20 process", cols, " ")
        for (j = 1; j <= m; j++) {
            key = impl SUBSEP cols[j]
            if (key in best) printf " %12.1f", best[key]; else printf " %12s", "-"
        }
        printf "\n"
    }
}' "$LOG"
echo
echo "Full log: $LOG"
