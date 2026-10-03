// =============================================================================
// Bell state: the simplest example of entanglement
//
// Run from the RecurLoop directory:
//   recurloop --file examples/bell.rl
// =============================================================================

include "../quantum.rl"

circuit bell(verbose:i64) {
    qubit a
    qubit b
    H a
    CNOT a, b
    if verbose == 1 {
        say "Bell state (|00> + |11>) / sqrt(2):"
        show state
        say "A single qubit of an entangled pair has no definite direction on the Bloch sphere:"
        show bloch a
        show bloch b
    }
    measure a -> ma
    measure b -> mb
    // The results are random, but always equal for both qubits
    check ma == mb
    return ma
}

experiment bell_counts {
    var ones = 0
    var i = 0
    while i < 10000 {
        ones += bell(0)
        i += 1
    }
    say ""
    printf("10000 pair measurements: 11 came up %lld times, 00 %lld times, never 01 or 10.\n", ones, 10000 - ones)
    return 0
}

bell(1)
bell_counts()
