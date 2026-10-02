// =============================================================================
// Stan Bella: najprostszy przykład splątania
//
// Uruchomienie z katalogu RecurLoop:
//   recurloop --file przyklady/bell.rl
// =============================================================================

include "../quantum.rl"

circuit bell(verbose:i64) {
    qubit a
    qubit b
    H a
    CNOT a, b
    if verbose == 1 {
        say "Stan Bella (|00> + |11>) / sqrt(2):"
        show state
        say "Pojedynczy kubit splątanej pary nie ma określonego kierunku na sferze Blocha:"
        show bloch a
        show bloch b
    }
    measure a -> ma
    measure b -> mb
    // Wyniki są losowe, ale zawsze takie same dla obu kubitów
    check ma == mb
    return ma
}

experiment pomiary {
    var jedynki = 0
    var i = 0
    while i < 10000 {
        jedynki += bell(0)
        i += 1
    }
    say ""
    printf("10000 pomiarów pary: wynik 11 wypadł %lld razy, wynik 00 %lld razy, nigdy 01 ani 10.\n", jedynki, 10000 - jedynki)
    return 0
}

bell(1)
pomiary()
