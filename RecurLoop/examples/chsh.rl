// =============================================================================
// The CHSH game: entanglement beats the classical bound
//
// A referee gives Alice a random bit x and Bob a random bit y. Alice and Bob
// cannot communicate. Each answers with one bit, a and b. They win when
// a XOR b = x AND y, i.e. the answers must differ only when both questions
// are 1.
//
// Every classical strategy, even with shared random bits, wins at most 75% of
// the games. Alice and Bob sharing an entangled pair win cos^2(pi/8), about
// 85.4% of the games. This corresponds to the value
// S = 8 * (fraction won) - 4: classically S <= 2, quantum S = 2 sqrt(2).
//
// Run from the RecurLoop directory:
//   recurloop --file examples/chsh.rl
// =============================================================================

include "../quantum.rl"

// One round of the game for questions x and y. Returns 1 for a win, 0 for a loss.
// entangled = 0 measures Alice's qubit right after the pair is created. This
// destroys the entanglement and leaves only a classical correlation: both
// qubits are either |0> or |1>.
circuit chsh(x:i64, y:i64, entangled:i64) {
    qubit alice
    qubit bob
    H alice
    CNOT alice, bob
    if entangled == 0 {
        measure alice -> classical
    }
    barrier alice, bob

    // Alice measures at angle 0 or pi/2, Bob at angle pi/4 or -pi/4.
    // Measuring at angle k in the X-Z plane of the Bloch sphere is a
    // rotation RY(-k) followed by an ordinary measurement.
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

// Plays each of the four question pairs in turn, the same number of rounds
// each. Prints the win rate for every question pair, the average and S.
experiment game(entangled:i64, rounds:i64) {
    var total_wins = 0
    var questions = 0
    while questions < 4 {
        var x = questions / 2
        var y = questions % 2
        var wins = 0
        var i = 0
        while i < rounds {
            wins += chsh(x, y, entangled)
            i += 1
        }
        printf("  x = %lld, y = %lld: won %5.1f%%\n", x, y, 100.0 * cast(f64, wins) / cast(f64, rounds))
        total_wins += wins
        questions += 1
    }
    var fraction = cast(f64, total_wins) / cast(f64, 4 * rounds)
    var s = 8.0 * fraction - 4.0
    printf("  average won %.1f%%, S = %.3f\n", 100.0 * fraction, s)
    if entangled == 1 {
        // 2 sqrt(2) = 2.828; with 40000 rounds the standard deviation of S is about 0.014
        check s > 2.75
        check s < 2.91
    }
    if entangled == 0 {
        // Without entanglement S = sqrt(2) = 1.414, always below the classical bound 2
        check s < 2.0
    }
    return 0
}

experiment demo {
    say "With entanglement:"
    game(1, 10000)
    say ""
    say "Without entanglement, Alice's qubit measured right after the pair is created:"
    game(0, 10000)
    say ""
    say "The classical bound is 75% won, i.e. S = 2."
    return 0
}

demo()
