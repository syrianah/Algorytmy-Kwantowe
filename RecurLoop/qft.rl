// =============================================================================
// Quantum Fourier transform
//
// On a register r of n qubits, with r[0] as the least significant bit:
//   QFT |x> = 1/sqrt(N) * sum over y of e^(2 pi i x y / N) |y>,   N = 2^n
//
// The functions use only circuit-language words, so they work with both
// backends. Include this file after quantum.rl or after qasm.rl.
// =============================================================================

// Sets the register to the number x: qubit r[k] gets bit k of x.
fn set_number(qs:i64, r:i64*, n:i64, x:i64) -> i64 {
    var rest = x
    var k = 0
    while k < n {
        if rest % 2 == 1 {
            X r[k]
        }
        rest = rest / 2
        k += 1
    }
    return 0
}

// QFT: from the most significant qubit down, H followed by phase rotations
// controlled by the lower qubits, then the qubit order is reversed.
fn qft(qs:i64, r:i64*, n:i64) -> i64 {
    var j = n - 1
    while j >= 0 {
        H r[j]
        var angle = pi() / 2.0
        var m = j - 1
        while m >= 0 {
            CP(angle) r[m], r[j]
            angle = angle / 2.0
            m -= 1
        }
        j -= 1
    }
    var i = 0
    while i < n / 2 {
        SWAP r[i], r[n - 1 - i]
        i += 1
    }
    return 0
}

// Inverse QFT: the same gates in reverse order with negated angles.
fn inverse_qft(qs:i64, r:i64*, n:i64) -> i64 {
    var i = 0
    while i < n / 2 {
        SWAP r[i], r[n - 1 - i]
        i += 1
    }
    var j = 0
    while j < n {
        // The rotation controlled by r[m] has angle -pi / 2^(j - m)
        var angle = pi()
        var t = 0
        while t < j {
            angle = angle / 2.0
            t += 1
        }
        angle = 0.0 - angle
        var m = 0
        while m < j {
            CP(angle) r[m], r[j]
            angle = angle * 2.0
            m += 1
        }
        H r[j]
        j += 1
    }
    return 0
}

// Prepares QFT |k> without entanglement: each qubit gets its own H and phase.
// Qubit r[j] is in state (|0> + e^(2 pi i k / 2^(n - j)) |1>) / sqrt(2).
// The inverse QFT turns this state back into |k>. Quantum phase estimation
// relies on this: a number stored in phases becomes a measurement result.
fn fourier_encode(qs:i64, r:i64*, n:i64, k:i64) -> i64 {
    var j = 0
    while j < n {
        var angle = 2.0 * pi() * cast(f64, k)
        var t = 0
        while t < n - j {
            angle = angle / 2.0
            t += 1
        }
        H r[j]
        P(angle) r[j]
        j += 1
    }
    return 0
}
