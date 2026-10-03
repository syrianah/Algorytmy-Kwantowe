// =============================================================================
// Gra CHSH: splątanie łamie klasyczną granicę
//
// Sędzia daje Alicji losowy bit x, a Bobowi losowy bit y. Alicja i Bob nie
// mogą się porozumiewać. Każde odpowiada jednym bitem, a i b. Wygrywają, gdy
// a XOR b = x AND y, czyli odpowiedzi mają być różne tylko wtedy, gdy oba
// pytania to 1.
//
// Każda strategia klasyczna, nawet ze wspólnymi losowymi bitami, wygrywa
// najwyżej w 75% gier. Alicja i Bob dzielący parę splątaną wygrywają
// w cos^2(pi/8), czyli około 85,4% gier. Odpowiada to wartości
// S = 8 * (procent wygranych) - 4: klasycznie S <= 2, kwantowo S = 2 sqrt(2).
//
// Uruchomienie z katalogu RecurLoop:
//   recurloop --file przyklady/chsh.rl
// =============================================================================

include "../quantum.rl"

// Jedna runda gry dla pytań x i y. Zwraca 1 przy wygranej, 0 przy przegranej.
// splatanie = 0 mierzy kubit Alicji zaraz po utworzeniu pary. To niszczy
// splątanie i zostawia tylko klasyczną korelację: oba kubity są albo |0>,
// albo |1>.
circuit chsh(x:i64, y:i64, splatanie:i64) {
    qubit alicja
    qubit bob
    H alicja
    CNOT alicja, bob
    if splatanie == 0 {
        measure alicja -> klasyczny
    }
    barrier alicja, bob

    // Alicja mierzy pod kątem 0 albo pi/2, Bob pod kątem pi/4 albo -pi/4.
    // Pomiar pod kątem k na płaszczyźnie X-Z sfery Blocha to obrót RY(-k)
    // i zwykły pomiar.
    var kat_alicji = cast(f64, x) * pi() / 2.0
    var kat_boba = pi() / 4.0 - cast(f64, y) * pi() / 2.0
    RY(0.0 - kat_alicji) alicja
    RY(0.0 - kat_boba) bob
    measure alicja -> a
    measure bob -> b

    if (a + b) % 2 == x * y {
        return 1
    }
    return 0
}

// Gra po kolei z każdą z czterech par pytań, po tyle samo rund. Wypisuje
// odsetek wygranych dla każdej pary pytań, średnią i wartość S.
experiment gra(splatanie:i64, rundy:i64) {
    var wygrane_razem = 0
    var pytania = 0
    while pytania < 4 {
        var x = pytania / 2
        var y = pytania % 2
        var wygrane = 0
        var i = 0
        while i < rundy {
            wygrane += chsh(x, y, splatanie)
            i += 1
        }
        printf("  x = %lld, y = %lld: wygrane %5.1f%%\n", x, y, 100.0 * cast(f64, wygrane) / cast(f64, rundy))
        wygrane_razem += wygrane
        pytania += 1
    }
    var procent = cast(f64, wygrane_razem) / cast(f64, 4 * rundy)
    var s = 8.0 * procent - 4.0
    printf("  średnio wygrane %.1f%%, S = %.3f\n", 100.0 * procent, s)
    if splatanie == 1 {
        // 2 sqrt(2) = 2.828, przy 40000 rundach odchylenie S to około 0.014
        check s > 2.75
        check s < 2.91
    }
    if splatanie == 0 {
        // Bez splątania S = sqrt(2) = 1.414, zawsze poniżej klasycznej granicy 2
        check s < 2.0
    }
    return 0
}

experiment pokaz {
    say "Ze splątaniem:"
    gra(1, 10000)
    say ""
    say "Bez splątania, kubit Alicji zmierzony zaraz po utworzeniu pary:"
    gra(0, 10000)
    say ""
    say "Klasyczna granica to 75% wygranych, czyli S = 2."
    return 0
}

pokaz()
