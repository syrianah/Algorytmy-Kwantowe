// =============================================================================
// Circuits to run on an IBM quantum computer
//
// This file does not pick a backend. It is included by:
//   simulate.rl        with the quantum.rl library, i.e. simulation
//   generate_qasm.rl   with the qasm.rl library, i.e. OpenQASM 3 files
// Both also include ../qft.rl first.
// =============================================================================

// Teleportation with corrections applied mid-circuit (a dynamic circuit).
// Bob applies X and Z depending on the bits Alice measured.
circuit teleportation {
    qubit psi
    qubit alice
    qubit bob
    prepare psi random
    H alice
    CNOT alice, bob
    CNOT psi, alice
    H psi
    measure psi -> m1
    measure alice -> m2
    when m2 {
        X bob
    }
    when m1 {
        Z bob
    }
    expect bob == psi
    return 0
}

// Teleportation with deferred measurement: quantum-controlled corrections
// through CNOT and CZ instead of conditions on measured bits. It gives Bob
// the same state and runs on any processor, even without dynamic circuits.
circuit teleportation_deferred {
    qubit psi
    qubit alice
    qubit bob
    prepare psi random
    H alice
    CNOT alice, bob
    CNOT psi, alice
    H psi
    CNOT alice, bob
    CZ psi, bob
    expect bob == psi
    measure psi -> m1
    measure alice -> m2
    return 0
}

// A control circuit without teleportation: preparing and undoing a state on
// one qubit. It shows how many errors measurement and single gates add alone.
circuit control {
    qubit psi
    prepare psi random
    expect psi == psi
    return 0
}

// Superdense coding: Alice sends Bob two bits b1 b2 by handing him only one
// qubit of a shared entangled pair. This function is the shared circuit body;
// the superdense_XY circuits below send the specific messages XY. On hardware
// the X and Z gates appear in the QASM file only if the message needs them,
// because the conditions on b1 and b2 are evaluated at compile time.
//
// Barriers separate the protocol stages: preparing the pair, Alice's encoding
// and Bob's decoding. Without them the Qiskit compiler, knowing the result in
// advance, would remove the entanglement and leave only X gates before the
// measurement.
fn superdense(qs:i64, b1:i64, b2:i64) -> i64 {
    qubit alice
    qubit bob
    H alice
    CNOT alice, bob
    barrier alice, bob
    if b2 == 1 {
        X alice
    }
    if b1 == 1 {
        Z alice
    }
    barrier alice, bob
    CNOT alice, bob
    H alice
    measure alice -> decoded1
    measure bob -> decoded2
    return decoded1 * 2 + decoded2
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

// The CHSH game: Alice gets question x, Bob question y, and they win when
// a XOR b = x AND y. Classically at most 75% of games can be won; with an
// entangled pair about 85.4%. The chsh_XY circuits play with questions x = X
// and y = Y. The function returns 1 for a win and 0 for a loss.
fn chsh(qs:i64, x:i64, y:i64) -> i64 {
    qubit alice
    qubit bob
    H alice
    CNOT alice, bob
    barrier alice, bob
    var alice_angle = cast(f64, x) * pi() / 2.0
    var bob_angle = pi() / 4.0 - cast(f64, y) * pi() / 2.0
    RY(0.0 - alice_angle) alice
    RY(0.0 - bob_angle) bob
    measure alice -> a
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

// The quantum Fourier transform as the core of phase estimation: a number k
// from 0 to 7 is stored only in the phases of three qubits, and the inverse
// QFT turns it into a measurement result. The qft_K circuits read back K.
// Needs qft.rl.
fn phase_readout(qs:i64, k:i64) -> i64 {
    qubits r[3]
    fourier_encode(qs, r, 3, k)
    inverse_qft(qs, r, 3)
    measure all r -> result
    return result
}

circuit qft_0 {
    return phase_readout(qs, 0)
}

circuit qft_1 {
    return phase_readout(qs, 1)
}

circuit qft_2 {
    return phase_readout(qs, 2)
}

circuit qft_3 {
    return phase_readout(qs, 3)
}

circuit qft_4 {
    return phase_readout(qs, 4)
}

circuit qft_5 {
    return phase_readout(qs, 5)
}

circuit qft_6 {
    return phase_readout(qs, 6)
}

circuit qft_7 {
    return phase_readout(qs, 7)
}
