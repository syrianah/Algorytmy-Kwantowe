#!/bin/sh
# Porównanie wydajności: czysty Python, NumPy, Rust i RecurLoop.
# Każda konfiguracja jest uruchamiana POWTORZENIA razy, raportowany jest
# najlepszy czas obliczeń mierzony wewnątrz programu.
#
# Użycie: ./uruchom_benchmark.sh [ścieżka/do/recurloop]
set -eu
cd "$(dirname "$0")"
RECURLOOP="${1:-${RECURLOOP:-recurloop}}"
POWTORZENIA="${POWTORZENIA:-3}"
BUILD="${TMPDIR:-/tmp}/quantum-bench"
mkdir -p "$BUILD"
LOG="$BUILD/wyniki.log"
: > "$LOG"

echo "Kompilacja Rust..."
rustc -C opt-level=3 -C target-cpu=native bench.rs -o "$BUILD/bench_rs"

# Uruchamia polecenie, dopisuje linie wyników z etykietą implementacji.
run() {
    label="$1"
    shift
    "$@" | sed "s/^/$label /" >> "$LOG"
}

i=0
while [ "$i" -lt "$POWTORZENIA" ]; do
    i=$((i + 1))
    echo "Powtórzenie $i z $POWTORZENIA..."
    for variant in div bit; do
        run "rust-$variant" "$BUILD/bench_rs" "$variant" teleport 100000
        run "rust-$variant" "$BUILD/bench_rs" "$variant" layers 16 5
        run "rust-$variant" "$BUILD/bench_rs" "$variant" layers 20 5
    done
    start=$(date +%s%N)
    run recurloop "$RECURLOOP" --file bench.rl
    end=$(date +%s%N)
    echo "recurloop proces czas_ms=$(( (end - start) / 1000000 ))" >> "$LOG"
    run python-pure python3 bench.py pure teleport 100000
    run python-pure python3 bench.py pure layers 16 5
    run python-pure python3 bench.py pure layers 20 5
    run numpy python3 bench.py numpy teleport 100000
    run numpy python3 bench.py numpy layers 16 5
    run numpy python3 bench.py numpy layers 20 5
done

echo
echo "Sumy kontrolne (muszą być identyczne dla każdej implementacji):"
grep layers "$LOG" | sed 's/ czas_ms=.*//' | sort -u

echo
echo "Najlepszy czas obliczeń w ms:"
awk '
{
    impl = $1; test = $2
    if (test == "layers") { split($3, a, "="); test = "layers-" a[2] }
    for (f = 1; f <= NF; f++) if ($f ~ /^czas_ms=/) { split($f, c, "="); t = c[2] + 0 }
    key = impl SUBSEP test
    if (!(key in best) || t < best[key]) best[key] = t
    impls[impl] = 1; tests[test] = 1
}
END {
    printf "%-12s %12s %12s %12s %12s\n", "", "teleport", "layers-16", "layers-20", "proces"
    n = split("python-pure numpy rust-div rust-bit recurloop", order, " ")
    for (k = 1; k <= n; k++) {
        impl = order[k]
        printf "%-12s", impl
        m = split("teleport layers-16 layers-20 proces", cols, " ")
        for (j = 1; j <= m; j++) {
            key = impl SUBSEP cols[j]
            if (key in best) printf " %12.1f", best[key]; else printf " %12s", "-"
        }
        printf "\n"
    }
}' "$LOG"
echo
echo "Pełny log: $LOG"
