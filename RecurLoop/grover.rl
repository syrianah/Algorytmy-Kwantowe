// =============================================================================
// Grover's search algorithm
//
// Among N = 2^n numbers exactly one, the marked number k, is the answer. The
// oracle recognises it but tells nothing else: it only flips the sign of |k>.
// A classical search needs N / 2 oracle calls on average; Grover's algorithm
// needs about (pi / 4) sqrt(N).
//
// Starting from the equal superposition of all numbers, every iteration is the
// oracle followed by the diffusion (reflection about the average). Each
// iteration rotates the state by the angle 2 theta towards |k>, where
// sin(theta) = 1 / sqrt(N). After t iterations the marked number is measured
// with probability sin^2((2t + 1) theta):
//   n = 2, N = 4: one iteration gives exactly 100%
//   n = 3, N = 8: 12.5%, 78.1%, 94.5%, 33.0% after 0, 1, 2, 3 iterations
//
// Registers of 2 or 3 qubits are supported, because the sign flip of |11...1>
// is a CZ or CCZ gate. The functions use only circuit-language words, so they
// work with both backends. Include this file after quantum.rl or after qasm.rl.
// =============================================================================

// Flips the sign of the state in which every qubit of the register is 1.
fn flip_all_ones(qs:i64, r:i64*, n:i64) -> i64 {
    if n == 2 {
        CZ r[0], r[1]
    }
    if n == 3 {
        CCZ r[0], r[1], r[2]
    }
    return 0
}

// X on the qubits whose bit of k is 0. Applied before and after
// flip_all_ones, it moves the sign flip from |11...1> to |k>.
fn flip_zero_bits(qs:i64, r:i64*, n:i64, k:i64) -> i64 {
    var rest = k
    var j = 0
    while j < n {
        if rest % 2 == 0 {
            X r[j]
        }
        rest = rest / 2
        j += 1
    }
    return 0
}

// The oracle: |x> -> -|x> for x = k, every other number unchanged.
fn oracle(qs:i64, r:i64*, n:i64, k:i64) -> i64 {
    flip_zero_bits(qs, r, n, k)
    flip_all_ones(qs, r, n)
    flip_zero_bits(qs, r, n, k)
    return 0
}

// The diffusion: reflection about the equal superposition. It is the sign flip
// of |00...0> sandwiched between H gates; up to an overall sign this is
// 2 |s><s| - 1, which maps every amplitude a to 2 * average - a.
fn diffusion(qs:i64, r:i64*, n:i64) -> i64 {
    var j = 0
    while j < n {
        H r[j]
        X r[j]
        j += 1
    }
    flip_all_ones(qs, r, n)
    j = 0
    while j < n {
        X r[j]
        H r[j]
        j += 1
    }
    return 0
}

// The whole search for the marked number k with the given number of iterations.
fn grover(qs:i64, r:i64*, n:i64, k:i64, iterations:i64) -> i64 {
    var j = 0
    while j < n {
        H r[j]
        j += 1
    }
    var t = 0
    while t < iterations {
        oracle(qs, r, n, k)
        diffusion(qs, r, n)
        t += 1
    }
    return 0
}
