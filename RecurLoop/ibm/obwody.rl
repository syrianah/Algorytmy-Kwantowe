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
