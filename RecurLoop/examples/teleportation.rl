// =============================================================================
// Quantum teleportation
//
// Alice has a qubit psi in an unknown state and wants to send it to Bob. They
// share an entangled pair. Alice measures psi and her half of the pair in the
// Bell basis and sends Bob two classical bits. Using them, Bob applies X and Z
// corrections and ends up with exactly the state psi.
//
// Run from the RecurLoop directory:
//   recurloop --file examples/teleportation.rl
// =============================================================================

include "../quantum.rl"

// verbose = 1 prints the state after every step.
// Returns the code of Alice's measurement: 2 * m_psi + m_alice.
circuit teleportation(verbose:i64) {
    qubit psi
    qubit alice
    qubit bob

    // A random state to send, uniform on the Bloch sphere
    prepare psi random
    if verbose == 1 {
        say "Step 0. The state to teleport:"
        show bloch psi
    }

    // Step 1. An entangled pair (Bell state) shared by Alice and Bob
    H alice
    CNOT alice, bob
    if verbose == 1 {
        say ""
        say "Step 1. Alice and Bob share an entangled pair:"
        show state
    }

    // Step 2. Alice entangles psi with her half of the pair
    CNOT psi, alice
    H psi
    if verbose == 1 {
        say ""
        say "Step 2. After Alice's CNOT and H:"
        show state
    }

    // Step 3. Alice measures both of her qubits
    measure psi -> m1
    measure alice -> m2
    if verbose == 1 {
        say ""
        printf("Step 3. Alice measured psi = %lld, alice = %lld and sends these bits to Bob.\n", m1, m2)
        show state
    }

    // Step 4. Bob applies the corrections that depend on the received bits
    if m2 == 1 {
        X bob
    }
    if m1 == 1 {
        Z bob
    }
    if verbose == 1 {
        say ""
        say "Step 4. After the corrections Bob's state equals the original:"
        show bloch bob
    }

    // Check: the fidelity of Bob's state with respect to the original psi must be 1
    expect bob == psi
    return m1 * 2 + m2
}

// Many independent teleportations of random states. Each ends with an
// `expect` check, and Alice's measurement results should be uniform: each of
// the four combinations with probability 1/4.
experiment statistics {
    var trials = 10000
    var c00 = 0
    var c01 = 0
    var c10 = 0
    var c11 = 0
    var i = 0
    while i < trials {
        var outcome = teleportation(0)
        if outcome == 0 { c00 += 1 }
        if outcome == 1 { c01 += 1 }
        if outcome == 2 { c10 += 1 }
        if outcome == 3 { c11 += 1 }
        i += 1
    }
    say ""
    printf("Statistics: %lld teleportations of random states, all with fidelity 1.\n", trials)
    printf("  Alice's results 00: %lld\n", c00)
    printf("  Alice's results 01: %lld\n", c01)
    printf("  Alice's results 10: %lld\n", c10)
    printf("  Alice's results 11: %lld\n", c11)
    check c00 > 2200
    check c01 > 2200
    check c10 > 2200
    check c11 > 2200
    return 0
}

teleportation(1)
statistics()
