#!/bin/sh
# Uruchamia testy biblioteki i wszystkie przykłady.
# Użycie: ./uruchom.sh [ścieżka/do/recurloop]
set -eu
cd "$(dirname "$0")"
RECURLOOP="${1:-${RECURLOOP:-recurloop}}"

run() {
    echo "== $1"
    "$RECURLOOP" --file "$1"
    echo
}

run testy.rl
for example in przyklady/*.rl; do
    run "$example"
done
(cd ibm && run symuluj.rl)
echo "Wszystko zaliczone."
