// Simulates the circuits from circuits.rl with the quantum.rl library and
// checks that every teleportation gives Bob the right state, superdense coding
// delivers exactly the bits sent, the CHSH game is won with probability close
// to cos^2(pi/8), the inverse QFT reads back the number stored in phases, and
// Grover's search finds the marked number with the expected probability.
// Run from the ibm directory:
//   recurloop --file simulate.rl

include "../quantum.rl"
include "../qft.rl"
include "../grover.rl"
include "circuits.rl"

experiment simulation {
    var wins_00 = 0
    var wins_01 = 0
    var wins_10 = 0
    var wins_11 = 0
    var grover3_hits = 0
    var i = 0
    while i < 10000 {
        teleportation()
        teleportation_deferred()
        control()
        check superdense_00() == 0
        check superdense_01() == 1
        check superdense_10() == 2
        check superdense_11() == 3
        wins_00 += chsh_00()
        wins_01 += chsh_01()
        wins_10 += chsh_10()
        wins_11 += chsh_11()
        check qft_0() == 0
        check qft_1() == 1
        check qft_2() == 2
        check qft_3() == 3
        check qft_4() == 4
        check qft_5() == 5
        check qft_6() == 6
        check qft_7() == 7
        check grover2_0() == 0
        check grover2_1() == 1
        check grover2_2() == 2
        check grover2_3() == 3
        if grover3_0() == 0 { grover3_hits += 1 }
        if grover3_1() == 1 { grover3_hits += 1 }
        if grover3_2() == 2 { grover3_hits += 1 }
        if grover3_3() == 3 { grover3_hits += 1 }
        if grover3_4() == 4 { grover3_hits += 1 }
        if grover3_5() == 5 { grover3_hits += 1 }
        if grover3_6() == 6 { grover3_hits += 1 }
        if grover3_7() == 7 { grover3_hits += 1 }
        i += 1
    }
    say "Simulation: 10000 runs of every circuit, all checks passed."
    printf("CHSH game, wins out of 10000: %lld %lld %lld %lld (theory: 8536)\n", wins_00, wins_01, wins_10, wins_11)
    // 8536 +- 6 standard deviations (35)
    check wins_00 > 8325
    check wins_00 < 8745
    check wins_01 > 8325
    check wins_01 < 8745
    check wins_10 > 8325
    check wins_10 < 8745
    check wins_11 > 8325
    check wins_11 < 8745
    printf("Grover on 3 qubits, marked number found in %lld of 80000 runs (theory: 75625)\n", grover3_hits)
    // 75625 +- 6 standard deviations (390)
    check grover3_hits > 75235
    check grover3_hits < 76015
    return 0
}

simulation()
