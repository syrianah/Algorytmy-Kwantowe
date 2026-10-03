// Symuluje obwody z obwody.rl biblioteką quantum.rl i sprawdza, że każda
// teleportacja daje Bobowi właściwy stan, a kodowanie supergęste
// przekazuje Bobowi dokładnie wysłane bity.
// Uruchomienie z katalogu ibm:
//   recurloop --file symuluj.rl

include "../quantum.rl"
include "obwody.rl"

experiment symulacja {
    var i = 0
    while i < 10000 {
        teleportacja()
        teleportacja_odroczona()
        kontrola()
        check superdense_00() == 0
        check superdense_01() == 1
        check superdense_10() == 2
        check superdense_11() == 3
        i += 1
    }
    say "Symulacja: po 10000 przebiegów każdego obwodu, wszystkie sprawdzenia expect spełnione."
    return 0
}

symulacja()
