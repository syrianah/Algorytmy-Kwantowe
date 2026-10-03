// Simulates the circuits from circuits.rl with the quantum.rl library and
// checks that every teleportation gives Bob the right state, superdense coding
// delivers exactly the bits sent, the CHSH game is won with probability close
// to cos^2(pi/8), and the inverse QFT reads back the number stored in phases.
// Run from the ibm directory:
//   recurloop --file simulate.rl

include "../quantum.rl"
include "../qft.rl"
include "circuits.rl"

experiment simulation {
    var wins_00 = 0
    var wins_01 = 0
    var wins_10 = 0
    var wins_11 = 0
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
    return 0
}

simulation()
