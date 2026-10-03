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
