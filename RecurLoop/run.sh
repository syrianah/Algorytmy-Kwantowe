#!/bin/sh
# Runs the library tests and all examples.
# Usage: ./run.sh [path/to/recurloop]
set -eu
cd "$(dirname "$0")"
RECURLOOP="${1:-${RECURLOOP:-recurloop}}"

run() {
    echo "== $1"
    "$RECURLOOP" --file "$1"
    echo
}

run tests.rl
for example in examples/*.rl; do
    run "$example"
done
(cd ibm && run simulate.rl)
echo "All passed."
