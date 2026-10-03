// Testy bramek i pomiarów biblioteki quantum.rl.
// Uruchomienie z katalogu RecurLoop:
//   recurloop --file testy.rl
// Każdy obwód kończy program kodem 1, jeśli któreś sprawdzenie zawiedzie.

include "quantum.rl"

seed 12345

// X zamienia |0> na |1>
circuit test_x {
    qubit q
    X q
    measure q -> m
    check m == 1
}

// H H = I
circuit test_hh {
    qubit q
    H q
    H q
    probability q -> p
    check approx(p, 0.0) == 1
}

// H tworzy równą superpozycję
circuit test_h {
    qubit q
    H q
    probability q -> p
    check approx(p, 0.5) == 1
}

// H Z H = X
circuit test_hzh {
    qubit q
    H q
    Z q
    H q
    probability q -> p
    check approx(p, 1.0) == 1
}

// S S = Z oraz T^4 = Z, sprawdzane przez H _ H
circuit test_phase {
    qubit a
    qubit b
    H a
    S a
    S a
    H a
    H b
    T b
    T b
    T b
    T b
    H b
    probability a -> pa
    probability b -> pb
    check approx(pa, 1.0) == 1
    check approx(pb, 1.0) == 1
}

// RX(pi) i RY(pi) odwracają |0> na |1>, RZ nie zmienia prawdopodobieństw
circuit test_rotations {
    qubit a
    qubit b
    qubit c
    RX(pi()) a
    RY(pi()) b
    RZ(pi() / 3.0) c
    probability a -> pa
    probability b -> pb
    probability c -> pc
    check approx(pa, 1.0) == 1
    check approx(pb, 1.0) == 1
    check approx(pc, 0.0) == 1
}

// Y Y = I na przygotowanym stanie, Y|0> = i|1>
circuit test_y {
    qubit q
    qubit r
    prepare q (1.1, 0.7)
    Y q
    Y q
    expect q == q
    Y r
    probability r -> p
    check approx(p, 1.0) == 1
}

// Tablica prawdy CNOT
circuit test_cnot {
    qubit a
    qubit b
    CNOT a, b
    probability b -> p0
    check approx(p0, 0.0) == 1
    X a
    CNOT a, b
    probability b -> p1
    check approx(p1, 1.0) == 1
}

// SWAP przenosi przygotowany stan na drugi kubit
circuit test_swap {
    qubit a
    qubit b
    prepare a (2.0, 1.3)
    SWAP a, b
    expect b == a
    probability a -> p
    check approx(p, 0.0) == 1
}

// TOFFOLI działa tylko przy obu kontrolach równych 1
circuit test_toffoli {
    qubit a
    qubit b
    qubit c
    X a
    TOFFOLI a, b, c
    probability c -> p0
    check approx(p0, 0.0) == 1
    X b
    TOFFOLI a, b, c
    probability c -> p1
    check approx(p1, 1.0) == 1
}

// H b, CZ, H b działa jak CNOT
circuit test_cz {
    qubit a
    qubit b
    X a
    H b
    CZ a, b
    H b
    probability b -> p
    check approx(p, 1.0) == 1
}

// CP(pi) z kontrolą w stanie 1 działa jak CZ, a z kontrolą 0 nic nie robi
circuit test_cp {
    qubit a
    qubit b
    qubit c
    X a
    H b
    CP(pi()) a, b
    CP(pi()) c, b
    H b
    probability b -> p
    check approx(p, 1.0) == 1
}

// Rejestr: kubity r[0], r[1], ... i pomiar całego rejestru do liczby
circuit test_register {
    qubit a
    qubits r[4]
    X a
    X r[1]
    X r[3]
    barrier r[0], r[3]
    measure all r -> x
    check x == 10
    measure a -> m
    check m == 1
}

// Reset sprowadza kubit do |0>
circuit test_reset {
    qubit q
    H q
    reset q
    probability q -> p
    check approx(p, 0.0) == 1
}

// Wierność stanów ortogonalnych wynosi 0, a stanu |+> względem |0> 1/2
circuit test_fidelity {
    qubit a
    qubit b
    qubit c
    prepare a (0.0, 0.0)
    X b
    H c
    fidelity b, a -> f0
    fidelity c, a -> f1
    check approx(f0, 0.0) == 1
    check approx(f1, 0.5) == 1
}

// `when` wykonuje blok tylko, gdy zmierzony bit wynosi 1
circuit test_when {
    qubit a
    qubit b
    qubit c
    X a
    measure a -> ma
    measure b -> mb
    when ma {
        X c
    }
    when mb {
        X c
    }
    probability c -> p
    check approx(p, 1.0) == 1
}

// Stan Bella: wyniki obu pomiarów są zawsze równe. Zwraca wynik pomiaru.
circuit bell_pair {
    qubit a
    qubit b
    H a
    CNOT a, b
    measure a -> ma
    measure b -> mb
    check ma == mb
    return ma
}

test_x()
test_hh()
test_h()
test_hzh()
test_phase()
test_rotations()
test_y()
test_cnot()
test_swap()
test_toffoli()
test_cz()
test_cp()
test_register()
test_reset()
test_fidelity()
test_when()

// Przy 1000 próbach wynik 1 powinien wypaść około 500 razy
experiment bell_statistics {
    var ones = 0
    var trial = 0
    while trial < 1000 {
        ones += bell_pair()
        trial += 1
    }
    check ones > 430
    check ones < 570
    return ones
}

const ones = bell_statistics()
print "Wszystkie testy zaliczone. Para Bella: " + str(ones) + " jedynek na 1000 prób."
