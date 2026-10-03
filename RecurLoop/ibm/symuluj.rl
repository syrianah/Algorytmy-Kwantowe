// Symuluje obwody z obwody.rl biblioteką quantum.rl i sprawdza, że każda
// teleportacja daje Bobowi właściwy stan.
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
        i += 1
    }
    say "Symulacja: po 10000 przebiegów każdego obwodu, wszystkie sprawdzenia expect spełnione."
    return 0
}

symulacja()
