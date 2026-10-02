// =============================================================================
// Teleportacja kwantowa
//
// Alicja ma kubit psi w nieznanym stanie i chce przesłać go Bobowi. Dzielą
// parę splątaną. Alicja wykonuje pomiar w bazie Bella na psi i swojej połowie
// pary, po czym wysyła Bobowi dwa klasyczne bity. Bob na ich podstawie
// stosuje korekty X i Z i otrzymuje dokładnie stan psi.
//
// Uruchomienie z katalogu RecurLoop:
//   recurloop --file przyklady/teleportacja.rl
// =============================================================================

include "../quantum.rl"

// verbose = 1 wypisuje stan po każdym kroku.
// Zwraca kod wyniku pomiaru Alicji: 2 * m_psi + m_alicja.
circuit teleportacja(verbose:i64) {
    qubit psi
    qubit alicja
    qubit bob

    // Losowy stan do wysłania, jednostajnie na sferze Blocha
    prepare psi random
    if verbose == 1 {
        say "Krok 0. Stan do teleportacji:"
        show bloch psi
    }

    // Krok 1. Para splątana (stan Bella) między Alicją i Bobem
    H alicja
    CNOT alicja, bob
    if verbose == 1 {
        say ""
        say "Krok 1. Alicja i Bob dzielą parę splątaną:"
        show state
    }

    // Krok 2. Alicja splata psi ze swoją połową pary
    CNOT psi, alicja
    H psi
    if verbose == 1 {
        say ""
        say "Krok 2. Po CNOT i H u Alicji:"
        show state
    }

    // Krok 3. Alicja mierzy oba swoje kubity
    measure psi -> m1
    measure alicja -> m2
    if verbose == 1 {
        say ""
        printf("Krok 3. Alicja zmierzyła psi = %lld, alicja = %lld i wysyła te bity Bobowi.\n", m1, m2)
        show state
    }

    // Krok 4. Bob stosuje korekty zależne od otrzymanych bitów
    if m2 == 1 {
        X bob
    }
    if m1 == 1 {
        Z bob
    }
    if verbose == 1 {
        say ""
        say "Krok 4. Po korektach stan Boba jest równy oryginałowi:"
        show bloch bob
    }

    // Sprawdzenie: wierność stanu Boba względem oryginalnego psi musi wynosić 1
    expect bob == psi
    return m1 * 2 + m2
}

// Wiele niezależnych teleportacji losowych stanów. Każda kończy się
// sprawdzeniem `expect`, a wyniki pomiarów Alicji powinny mieć rozkład
// jednostajny: każda z czterech kombinacji z prawdopodobieństwem 1/4.
experiment statystyka {
    var proby = 10000
    var c00 = 0
    var c01 = 0
    var c10 = 0
    var c11 = 0
    var i = 0
    while i < proby {
        var wynik = teleportacja(0)
        if wynik == 0 { c00 += 1 }
        if wynik == 1 { c01 += 1 }
        if wynik == 2 { c10 += 1 }
        if wynik == 3 { c11 += 1 }
        i += 1
    }
    say ""
    printf("Statystyka: %lld teleportacji losowych stanów, wszystkie z wiernością 1.\n", proby)
    printf("  wyniki Alicji 00: %lld\n", c00)
    printf("  wyniki Alicji 01: %lld\n", c01)
    printf("  wyniki Alicji 10: %lld\n", c10)
    printf("  wyniki Alicji 11: %lld\n", c11)
    check c00 > 2200
    check c01 > 2200
    check c10 > 2200
    check c11 > 2200
    return 0
}

teleportacja(1)
statystyka()
