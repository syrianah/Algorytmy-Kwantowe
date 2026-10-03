// =============================================================================
// Superdense coding
//
// The reverse of teleportation. Alice and Bob share an entangled pair. Alice
// wants to send Bob two classical bits but can hand him only one qubit. She
// encodes the bits with X and Z gates on her half of the pair and sends that
// qubit to Bob. Holding both qubits, Bob reads the two bits with a Bell-basis
// measurement.
//
// Run from the RecurLoop directory:
//   recurloop --file examples/superdense.rl
// =============================================================================

include "../quantum.rl"

// Sends the message b1 b2 and returns what Bob read: 2 * decoded1 + decoded2.
// verbose = 1 prints the state after every step.
circuit superdense(b1:i64, b2:i64, verbose:i64) {
    qubit alice
    qubit bob

    // Step 1. Entangled pair (|00> + |11>) / sqrt(2)
    H alice
    CNOT alice, bob
    barrier alice, bob

    // Step 2. Alice encodes two bits on her qubit:
    //   00 -> nothing, 01 -> X, 10 -> Z, 11 -> X and Z
    // Each of the four messages gives a different Bell state.
    if b2 == 1 {
        X alice
    }
    if b1 == 1 {
        Z alice
    }
    if verbose == 1 {
        printf("\nMessage %lld%lld. State after Alice's encoding:\n", b1, b2)
        show state
    }

    // Step 3. Alice sends her qubit. Bob undoes the entanglement: CNOT and H
    // turn the four Bell states into the four basis states |b1 b2>.
    barrier alice, bob
    CNOT alice, bob
    H alice
    if verbose == 1 {
        say "After Bob's decoding the state is a basis state, so the measurement is certain:"
        show state
    }

    measure alice -> decoded1
    measure bob -> decoded2
    check decoded1 == b1
    check decoded2 == b2
    return decoded1 * 2 + decoded2
}

// Every message sent many times. Bob's measurement is not random:
// for every message it gives exactly the bits that were sent.
experiment statistics {
    say ""
    say "Statistics:"
    var trials = 2500
    var message = 0
    while message < 4 {
        var hits = 0
        var i = 0
        while i < trials {
            if superdense(message / 2, message % 2, 0) == message {
                hits += 1
            }
            i += 1
        }
        printf("  message %lld%lld: decoded correctly %lld of %lld times\n", message / 2, message % 2, hits, trials)
        check hits == trials
        message += 1
    }
    return 0
}

superdense(0, 0, 1)
superdense(0, 1, 1)
superdense(1, 0, 1)
superdense(1, 1, 1)
statistics()
