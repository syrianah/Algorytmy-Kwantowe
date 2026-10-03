// =============================================================================
// Kwantowa transformata Fouriera (QFT)
//
// QFT to kwantowa wersja dyskretnej transformaty Fouriera. Jest sercem
// algorytmu Shora i kwantowej estymacji fazy. Ten przykład pokazuje:
//   1. QFT pojedynczej liczby: same fazy, wszystkie prawdopodobieństwa równe.
//   2. QFT stanu okresowego: z okresu 4 robią się szczyty co 16 / 4 = 4.
//   3. Odczyt liczby zapisanej w fazach przez QFT odwrotną, jak w estymacji fazy.
//
// Uruchomienie z katalogu RecurLoop:
//   recurloop --file przyklady/qft.rl
// =============================================================================

include "../quantum.rl"
include "../qft.rl"

// QFT |5> na 3 kubitach. Amplituda |y> to e^(2 pi i 5 y / 8) / sqrt(8):
// moduły są równe, a liczba 5 jest zapisana tylko w fazach.
circuit transformata_liczby {
    qubits r[3]
    ustaw_liczbe(qs, r, 3, 5)
    say "Stan |5> na rejestrze 3 kubitów (r[0] to najmłodszy bit, pisany pierwszy):"
    show state
    qft(qs, r, 3)
    say "Po QFT wszystkie 8 wyników ma prawdopodobieństwo 1/8, a liczba 5 siedzi w fazach:"
    show state
    return 0
}

// Stan okresowy: równa superpozycja liczb 1, 5, 9, 13, czyli co 4.
// QFT zamienia okres 4 na szczyty w wielokrotnościach 16 / 4 = 4.
// Tak algorytm Shora znajduje okres funkcji.
circuit okres(verbose:i64) {
    qubits r[4]
    X r[0]
    H r[2]
    H r[3]
    if verbose == 1 {
        say ""
        say "Stan okresowy |1> + |5> + |9> + |13>, okres 4:"
        show state
    }
    qft(qs, r, 4)
    if verbose == 1 {
        say "Po QFT zostają tylko wyniki 0, 4, 8 i 12, wielokrotności 16 / 4:"
        show state
    }
    measure all r -> wynik
    check wynik % 4 == 0
    return wynik
}

// QFT, a potem QFT odwrotna, muszą oddać tę samą liczbę.
circuit tam_i_z_powrotem(x:i64) {
    qubits r[4]
    ustaw_liczbe(qs, r, 4, x)
    qft(qs, r, 4)
    qft_odwrotna(qs, r, 4)
    measure all r -> wynik
    check wynik == x
    return wynik
}

// Liczba k zapisana tylko w fazach kubitów, bez splątania. QFT odwrotna
// zamienia fazy na liczbę, którą odczytuje zwykły pomiar.
circuit odczyt_fazy(k:i64) {
    qubits r[4]
    koduj_fourier(qs, r, 4, k)
    qft_odwrotna(qs, r, 4)
    measure all r -> wynik
    check wynik == k
    return wynik
}

experiment testy {
    var x = 0
    while x < 16 {
        tam_i_z_powrotem(x)
        odczyt_fazy(x)
        x += 1
    }
    say ""
    say "Dla wszystkich 16 liczb: QFT i QFT odwrotna oddają liczbę, a odczyt fazy daje k."

    var licznik:i64* = cast(i64*, malloc(16 * 8))
    var i = 0
    while i < 16 {
        licznik[i] = 0
        i += 1
    }
    var proby = 8000
    i = 0
    while i < proby {
        var w = okres(0)
        licznik[w] += 1
        i += 1
    }
    printf("Pomiar po QFT stanu okresowego, %lld prób:\n", proby)
    i = 0
    while i < 16 {
        if licznik[i] > 0 {
            printf("  wynik %2lld: %lld razy\n", i, licznik[i])
        }
        check licznik[i] == 0 || licznik[i] > 1800
        i += 1
    }
    free(cast(u8*, licznik))
    return 0
}

transformata_liczby()
okres(1)
testy()
