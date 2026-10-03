// =============================================================================
// Kwantowa transformata Fouriera
//
// Na rejestrze r o n kubitach, z r[0] jako najmniej znaczącym bitem:
//   QFT |x> = 1/sqrt(N) * suma po y z e^(2 pi i x y / N) |y>,   N = 2^n
//
// Funkcje używają tylko słów języka obwodów, więc działają z oboma
// backendami. Dołącz ten plik po quantum.rl albo po qasm.rl.
// =============================================================================

// Ustawia rejestr na liczbę x: kubit r[k] dostaje bit k liczby x.
fn ustaw_liczbe(qs:i64, r:i64*, n:i64, x:i64) -> i64 {
    var reszta = x
    var k = 0
    while k < n {
        if reszta % 2 == 1 {
            X r[k]
        }
        reszta = reszta / 2
        k += 1
    }
    return 0
}

// QFT: od najstarszego kubitu H i obroty fazy sterowane młodszymi kubitami,
// na końcu odwrócenie kolejności kubitów.
fn qft(qs:i64, r:i64*, n:i64) -> i64 {
    var j = n - 1
    while j >= 0 {
        H r[j]
        var kat = pi() / 2.0
        var m = j - 1
        while m >= 0 {
            CP(kat) r[m], r[j]
            kat = kat / 2.0
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

// QFT odwrotna: te same bramki w odwrotnej kolejności i z przeciwnymi kątami.
fn qft_odwrotna(qs:i64, r:i64*, n:i64) -> i64 {
    var i = 0
    while i < n / 2 {
        SWAP r[i], r[n - 1 - i]
        i += 1
    }
    var j = 0
    while j < n {
        // Obrót sterowany przez r[m] ma kąt -pi / 2^(j - m)
        var kat = pi()
        var t = 0
        while t < j {
            kat = kat / 2.0
            t += 1
        }
        kat = 0.0 - kat
        var m = 0
        while m < j {
            CP(kat) r[m], r[j]
            kat = kat * 2.0
            m += 1
        }
        H r[j]
        j += 1
    }
    return 0
}

// Przygotowuje QFT |k> bez splątania: każdy kubit osobno dostaje H i fazę.
// Kubit r[j] ma stan (|0> + e^(2 pi i k / 2^(n - j)) |1>) / sqrt(2).
// QFT odwrotna zamienia ten stan z powrotem na |k>. Na tym opiera się
// kwantowa estymacja fazy: liczba zapisana w fazach staje się wynikiem pomiaru.
fn koduj_fourier(qs:i64, r:i64*, n:i64, k:i64) -> i64 {
    var j = 0
    while j < n {
        var kat = 2.0 * pi() * cast(f64, k)
        var t = 0
        while t < n - j {
            kat = kat / 2.0
            t += 1
        }
        H r[j]
        P(kat) r[j]
        j += 1
    }
    return 0
}
