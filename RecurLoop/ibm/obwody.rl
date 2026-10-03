// =============================================================================
// Obwody do uruchomienia na komputerze kwantowym IBM
//
// Ten plik nie wybiera backendu. Dołączają go:
//   symuluj.rl        z biblioteką quantum.rl, czyli symulacja
//   generuj_qasm.rl   z biblioteką qasm.rl, czyli pliki OpenQASM 3
// =============================================================================

// Teleportacja z korektami wykonywanymi w trakcie obwodu (obwód dynamiczny).
// Bob stosuje X i Z zależnie od bitów zmierzonych przez Alicję.
circuit teleportacja {
    qubit psi
    qubit alicja
    qubit bob
    prepare psi random
    H alicja
    CNOT alicja, bob
    CNOT psi, alicja
    H psi
    measure psi -> m1
    measure alicja -> m2
    when m2 {
        X bob
    }
    when m1 {
        Z bob
    }
    expect bob == psi
    return 0
}

// Teleportacja z odroczonym pomiarem: korekty sterowane kwantowo, przez CNOT
// i CZ, zamiast warunków na zmierzonych bitach. Daje ten sam stan Boba i działa
// na każdym procesorze, także bez obsługi obwodów dynamicznych.
circuit teleportacja_odroczona {
    qubit psi
    qubit alicja
    qubit bob
    prepare psi random
    H alicja
    CNOT alicja, bob
    CNOT psi, alicja
    H psi
    CNOT alicja, bob
    CZ psi, bob
    expect bob == psi
    measure psi -> m1
    measure alicja -> m2
    return 0
}

// Obwód kontrolny bez teleportacji: przygotowanie i odwrócenie stanu na
// jednym kubicie. Pokazuje, ile błędów wnosi sam pomiar i pojedyncze bramki.
circuit kontrola {
    qubit psi
    prepare psi random
    expect psi == psi
    return 0
}

// Kodowanie supergęste: Alicja wysyła Bobowi dwa bity b1 b2, przekazując mu
// tylko jeden kubit ze wspólnej pary splątanej. Ta funkcja to wspólna treść
// obwodu, a obwody superdense_XY poniżej wysyłają konkretne wiadomości XY.
// Na sprzęcie bramki X i Z pojawiają się w pliku QASM tylko wtedy, gdy
// wiadomość ich wymaga, bo warunki na b1 i b2 są sprawdzane podczas kompilacji.
//
// Bariery oddzielają etapy protokołu: przygotowanie pary, kodowanie u Alicji
// i dekodowanie u Boba. Bez nich kompilator Qiskit, znając wynik z góry,
// usunąłby splątanie i zostawił tylko bramki X przed pomiarem.
fn superdense(qs:i64, b1:i64, b2:i64) -> i64 {
    qubit alicja
    qubit bob
    H alicja
    CNOT alicja, bob
    barrier alicja, bob
    if b2 == 1 {
        X alicja
    }
    if b1 == 1 {
        Z alicja
    }
    barrier alicja, bob
    CNOT alicja, bob
    H alicja
    measure alicja -> odczyt1
    measure bob -> odczyt2
    return odczyt1 * 2 + odczyt2
}

circuit superdense_00 {
    return superdense(qs, 0, 0)
}

circuit superdense_01 {
    return superdense(qs, 0, 1)
}

circuit superdense_10 {
    return superdense(qs, 1, 0)
}

circuit superdense_11 {
    return superdense(qs, 1, 1)
}

// Gra CHSH: Alicja dostaje pytanie x, Bob pytanie y, a wygrywają, gdy
// a XOR b = x AND y. Klasycznie da się wygrać najwyżej 75% gier, a z parą
// splątaną około 85,4%. Obwody chsh_XY grają z pytaniami x = X i y = Y.
// Funkcja zwraca 1 przy wygranej, 0 przy przegranej.
fn chsh(qs:i64, x:i64, y:i64) -> i64 {
    qubit alicja
    qubit bob
    H alicja
    CNOT alicja, bob
    barrier alicja, bob
    var kat_alicji = cast(f64, x) * pi() / 2.0
    var kat_boba = pi() / 4.0 - cast(f64, y) * pi() / 2.0
    RY(0.0 - kat_alicji) alicja
    RY(0.0 - kat_boba) bob
    measure alicja -> a
    measure bob -> b
    if (a + b) % 2 == x * y {
        return 1
    }
    return 0
}

circuit chsh_00 {
    return chsh(qs, 0, 0)
}

circuit chsh_01 {
    return chsh(qs, 0, 1)
}

circuit chsh_10 {
    return chsh(qs, 1, 0)
}

circuit chsh_11 {
    return chsh(qs, 1, 1)
}

// Kwantowa transformata Fouriera, jądro estymacji fazy: liczba k od 0 do 7
// jest zapisana tylko w fazach trzech kubitów, a QFT odwrotna zamienia ją
// na wynik pomiaru. Obwody qft_K odczytują liczbę K. Wymaga qft.rl.
fn odczyt_fazy(qs:i64, k:i64) -> i64 {
    qubits r[3]
    koduj_fourier(qs, r, 3, k)
    qft_odwrotna(qs, r, 3)
    measure all r -> wynik
    return wynik
}

circuit qft_0 {
    return odczyt_fazy(qs, 0)
}

circuit qft_1 {
    return odczyt_fazy(qs, 1)
}

circuit qft_2 {
    return odczyt_fazy(qs, 2)
}

circuit qft_3 {
    return odczyt_fazy(qs, 3)
}

circuit qft_4 {
    return odczyt_fazy(qs, 4)
}

circuit qft_5 {
    return odczyt_fazy(qs, 5)
}

circuit qft_6 {
    return odczyt_fazy(qs, 6)
}

circuit qft_7 {
    return odczyt_fazy(qs, 7)
}
