// Symuluje obwody z obwody.rl biblioteką quantum.rl i sprawdza, że każda
// teleportacja daje Bobowi właściwy stan, a kodowanie supergęste
// przekazuje Bobowi dokładnie wysłane bity, a gra CHSH jest wygrywana
// z prawdopodobieństwem bliskim cos^2(pi/8).
// Uruchomienie z katalogu ibm:
//   recurloop --file symuluj.rl

include "../quantum.rl"
include "obwody.rl"

experiment symulacja {
    var wygrane_00 = 0
    var wygrane_01 = 0
    var wygrane_10 = 0
    var wygrane_11 = 0
    var i = 0
    while i < 10000 {
        teleportacja()
        teleportacja_odroczona()
        kontrola()
        check superdense_00() == 0
        check superdense_01() == 1
        check superdense_10() == 2
        check superdense_11() == 3
        wygrane_00 += chsh_00()
        wygrane_01 += chsh_01()
        wygrane_10 += chsh_10()
        wygrane_11 += chsh_11()
        i += 1
    }
    say "Symulacja: po 10000 przebiegów każdego obwodu, wszystkie sprawdzenia expect spełnione."
    printf("Gra CHSH, wygrane na 10000: %lld %lld %lld %lld (teoria: 8536)\n", wygrane_00, wygrane_01, wygrane_10, wygrane_11)
    // 8536 +- 6 odchyleń standardowych (35)
    check wygrane_00 > 8325
    check wygrane_00 < 8745
    check wygrane_01 > 8325
    check wygrane_01 < 8745
    check wygrane_10 > 8325
    check wygrane_10 < 8745
    check wygrane_11 > 8325
    check wygrane_11 < 8745
    return 0
}

symulacja()
