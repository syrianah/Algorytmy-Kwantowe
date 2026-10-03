// =============================================================================
// Grover's search algorithm
//
// The oracle hides one marked number k and only flips the sign of |k>. Grover's
// algorithm finds k with fewer oracle calls than any classical search. This
// example shows:
//   1. Two qubits step by step: one iteration finds k with certainty.
//   2. Three qubits: the success probability after 0 to 5 iterations. It rises
//      to 94.5% after two iterations and falls again after more, because every
//      iteration is a rotation and too many rotate past the answer.
//
// Run from the RecurLoop directory:
//   recurloop --file examples/grover.rl
// =============================================================================

include "../quantum.rl"
include "../grover.rl"

// Search among 4 numbers, printing the state after every step.
circuit search_steps(k:i64) {
    qubits r[2]
    H r[0]
    H r[1]
    printf("Marked number %lld. Equal superposition of 0, 1, 2, 3\n", k)
    say "(r[0] is the lowest bit and is printed first, so |01> is the number 2):"
    show state
    oracle(qs, r, 2, k)
    say "The oracle flips only the sign of the marked number; probabilities stay 1/4:"
    show state
    diffusion(qs, r, 2)
    say "The diffusion reflects every amplitude about the average: only k is left."
    say "(The overall minus sign is a global phase and cannot be measured.)"
    show state
    measure all r -> found
    check found == k
    return found
}

// Search among 4 numbers with one iteration.
circuit search2(k:i64) {
    qubits r[2]
    grover(qs, r, 2, k, 1)
    measure all r -> found
    return found
}

// Search among 8 numbers with the given number of iterations.
circuit search3(k:i64, iterations:i64) {
    qubits r[3]
    grover(qs, r, 3, k, iterations)
    measure all r -> found
    return found
}

experiment all_tests {
    var k = 0
    while k < 4 {
        var i = 0
        while i < 1000 {
            check search2(k) == k
            i += 1
        }
        k += 1
    }
    say ""
    say "Four numbers, one iteration: every marked number found 1000 times out of 1000."

    // sin(theta) = 1 / sqrt(8); success after t iterations is sin^2((2t + 1) theta)
    var theta = acos(sqrt(7.0 / 8.0))
    var trials = 4000
    say ""
    printf("Eight numbers, marked number 5, %lld trials per row:\n", trials)
    say "  iterations   found   theory"
    var t = 0
    while t < 6 {
        var hits = 0
        var i = 0
        while i < trials {
            if search3(5, t) == 5 {
                hits += 1
            }
            i += 1
        }
        var fraction = cast(f64, hits) / cast(f64, trials)
        var amplitude = sin(cast(f64, 2 * t + 1) * theta)
        var theory = amplitude * amplitude
        printf("  %10lld   %5.1f%%   %5.1f%%\n", t, 100.0 * fraction, 100.0 * theory)
        // 6 standard deviations of a fraction from 4000 trials are at most 0.048
        check fabs(fraction - theory) < 0.048
        t += 1
    }
    say "Two iterations are best; classically a single guess is right 12.5% of the time."
    return 0
}

search_steps(2)
all_tests()
