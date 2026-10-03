// =============================================================================
// Kodowanie supergęste (superdense coding)
//
// Odwrotność teleportacji. Alicja i Bob dzielą parę splątaną. Alicja chce
// wysłać Bobowi dwa klasyczne bity, ale może przekazać mu tylko jeden kubit.
// Koduje bity bramkami X i Z na swojej połowie pary i wysyła ten kubit Bobowi.
// Bob, mając oba kubity, odczytuje dwa bity pomiarem w bazie Bella.
//
// Uruchomienie z katalogu RecurLoop:
//   recurloop --file przyklady/superdense.rl
// =============================================================================

include "../quantum.rl"

// Wysyła wiadomość b1 b2 i zwraca to, co odczytał Bob: 2 * odczyt1 + odczyt2.
// verbose = 1 wypisuje stan po każdym kroku.
circuit superdense(b1:i64, b2:i64, verbose:i64) {
    qubit alicja
    qubit bob

    // Krok 1. Para splątana (|00> + |11>) / sqrt(2)
    H alicja
    CNOT alicja, bob
    barrier alicja, bob

    // Krok 2. Alicja koduje dwa bity na swoim kubicie:
    //   00 -> nic, 01 -> X, 10 -> Z, 11 -> X i Z
    // Każda z czterech wiadomości daje inny stan Bella.
    if b2 == 1 {
        X alicja
    }
    if b1 == 1 {
        Z alicja
    }
    if verbose == 1 {
        printf("\nWiadomość %lld%lld. Stan po kodowaniu u Alicji:\n", b1, b2)
        show state
    }

    // Krok 3. Alicja wysyła swój kubit. Bob odwraca splątanie: CNOT i H
    // zamieniają cztery stany Bella na cztery stany bazowe |b1 b2>.
    barrier alicja, bob
    CNOT alicja, bob
    H alicja
    if verbose == 1 {
        say "Po dekodowaniu u Boba stan jest bazowy, więc pomiar jest pewny:"
        show state
    }

    measure alicja -> odczyt1
    measure bob -> odczyt2
    check odczyt1 == b1
    check odczyt2 == b2
    return odczyt1 * 2 + odczyt2
}

// Każda wiadomość wysłana wiele razy. Pomiar Boba nie jest losowy:
// dla każdej wiadomości daje dokładnie wysłane bity.
experiment statystyka {
    say ""
    say "Statystyka:"
    var proby = 2500
    var wiadomosc = 0
    while wiadomosc < 4 {
        var trafienia = 0
        var i = 0
        while i < proby {
            if superdense(wiadomosc / 2, wiadomosc % 2, 0) == wiadomosc {
                trafienia += 1
            }
            i += 1
        }
        printf("  wiadomość %lld%lld: odczytana poprawnie %lld z %lld razy\n", wiadomosc / 2, wiadomosc % 2, trafienia, proby)
        check trafienia == proby
        wiadomosc += 1
    }
    return 0
}

superdense(0, 0, 1)
superdense(0, 1, 1)
superdense(1, 0, 1)
superdense(1, 1, 1)
statystyka()
