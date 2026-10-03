// =============================================================================
// Quantum Fourier transform (QFT)
//
// The QFT is the quantum version of the discrete Fourier transform. It is
// the heart of Shor's algorithm and of quantum phase estimation. This example
// shows:
//   1. The QFT of a single number: only phases, all probabilities equal.
//   2. The QFT of a periodic state: period 4 turns into peaks every 16 / 4 = 4.
//   3. Reading a number stored in phases with the inverse QFT, as in phase
//      estimation.
//
// Run from the RecurLoop directory:
//   recurloop --file examples/qft.rl
// =============================================================================

include "../quantum.rl"
include "../qft.rl"

// QFT |5> on 3 qubits. The amplitude of |y> is e^(2 pi i 5 y / 8) / sqrt(8):
// the magnitudes are equal and the number 5 lives only in the phases.
circuit number_transform {
    qubits r[3]
    set_number(qs, r, 3, 5)
    say "The state |5> on a 3-qubit register (r[0] is the lowest bit, printed first):"
    show state
    qft(qs, r, 3)
    say "After the QFT all 8 outcomes have probability 1/8 and the number 5 sits in the phases:"
    show state
    return 0
}

// A periodic state: an equal superposition of 1, 5, 9, 13, i.e. every 4.
// The QFT turns period 4 into peaks at multiples of 16 / 4 = 4.
// This is how Shor's algorithm finds the period of a function.
circuit period(verbose:i64) {
    qubits r[4]
    X r[0]
    H r[2]
    H r[3]
    if verbose == 1 {
        say ""
        say "Periodic state |1> + |5> + |9> + |13>, period 4:"
        show state
    }
    qft(qs, r, 4)
    if verbose == 1 {
        say "After the QFT only 0, 4, 8 and 12 remain, the multiples of 16 / 4:"
        show state
    }
    measure all r -> result
    check result % 4 == 0
    return result
}

// A QFT followed by an inverse QFT must give back the same number.
circuit round_trip(x:i64) {
    qubits r[4]
    set_number(qs, r, 4, x)
    qft(qs, r, 4)
    inverse_qft(qs, r, 4)
    measure all r -> result
    check result == x
    return result
}

// The number k stored only in the qubits' phases, without entanglement. The
// inverse QFT turns the phases into a number that an ordinary measurement reads.
circuit phase_readout(k:i64) {
    qubits r[4]
    fourier_encode(qs, r, 4, k)
    inverse_qft(qs, r, 4)
    measure all r -> result
    check result == k
    return result
}

experiment all_tests {
    var x = 0
    while x < 16 {
        round_trip(x)
        phase_readout(x)
        x += 1
    }
    say ""
    say "For all 16 numbers: QFT then inverse QFT gives the number back, and phase readout gives k."

    var counts:i64* = cast(i64*, malloc(16 * 8))
    var i = 0
    while i < 16 {
        counts[i] = 0
        i += 1
    }
    var trials = 8000
    i = 0
    while i < trials {
        var w = period(0)
        counts[w] += 1
        i += 1
    }
    printf("Measuring the QFT of the periodic state, %lld trials:\n", trials)
    i = 0
    while i < 16 {
        if counts[i] > 0 {
            printf("  result %2lld: %lld times\n", i, counts[i])
        }
        check counts[i] == 0 || counts[i] > 1800
        i += 1
    }
    free(cast(u8*, counts))
    return 0
}

number_transform()
period(1)
all_tests()
