# Quantum: obwody kwantowe w RecurLoop

Biblioteka [RecurLoop](https://github.com/RecurLoop/RecurLoop), która dodaje do
języka składnię obwodów kwantowych i symulator wektora stanu. Bramki, pomiary
i bloki `circuit` to nowe frazy języka zdefiniowane w samej bibliotece, bez
zmian w kompilatorze. Każdy obwód kompiluje się do natywnej funkcji.

```rl
include "quantum.rl"

circuit bell(verbose:i64) {
    qubit a
    qubit b
    H a
    CNOT a, b
    measure a -> ma
    measure b -> mb
    check ma == mb
    return ma
}

bell(0)
```

## Uruchomienie

Potrzebny jest zbudowany RecurLoop dla Linuksa x86-64:

```bash
git clone https://github.com/RecurLoop/RecurLoop.git
cd RecurLoop && make
```

Testy i wszystkie przykłady:

```bash
./uruchom.sh /sciezka/do/RecurLoop/build/Release/bin/recurloop
```

Pojedynczy przykład:

```bash
recurloop --file przyklady/teleportacja.rl
```

## Pliki

| Plik | Zawartość |
|---|---|
| `quantum.rl` | Silnik symulatora i składnia języka obwodów |
| `testy.rl` | Testy wszystkich bramek, pomiaru i wierności |
| `przyklady/bell.rl` | Stan Bella i statystyka pomiarów |
| `przyklady/teleportacja.rl` | Pełny protokół teleportacji krok po kroku i 10 000 losowych przebiegów |
| `uruchom.sh` | Uruchamia testy i przykłady |

## Język obwodów

### Definicje

| Składnia | Znaczenie |
|---|---|
| `circuit nazwa { ... }` | Obwód jako funkcja natywna `nazwa() -> i64` z własnym rejestrem |
| `circuit nazwa(a:i64, kat:f64) { ... }` | Obwód z parametrami |
| `experiment nazwa { ... }` | Funkcja natywna bez rejestru, na przykład do statystyk |
| `qubit nazwa` | Nowy kubit w stanie \|0> |
| `seed 42` | Stałe ziarno losowości, domyślnie ziarno z zegara |

### Bramki

| Składnia | Bramka |
|---|---|
| `H q`, `X q`, `Y q`, `Z q` | Hadamard i bramki Pauliego |
| `S q`, `T q` | Fazy pi/2 i pi/4 |
| `P(kat) q` | Faza diag(1, e^(i kat)) |
| `RX(kat) q`, `RY(kat) q`, `RZ(kat) q` | Obroty wokół osi sfery Blocha |
| `CNOT c, t`, `CZ c, t` | Bramki kontrolowane |
| `SWAP a, b` | Zamiana kubitów |
| `TOFFOLI c1, c2, t` | Podwójnie kontrolowane NOT |

### Pomiar i przygotowanie

| Składnia | Znaczenie |
|---|---|
| `measure q -> m` | Pomiar z losowaniem według reguły Borna i redukcją stanu |
| `probability q -> p` | Prawdopodobieństwo wyniku 1 bez pomiaru |
| `reset q` | Sprowadzenie kubitu do \|0> |
| `prepare q random` | Losowy stan jednostajnie na sferze Blocha |
| `prepare q (theta, phi)` | Stan cos(theta/2)\|0> + e^(i phi) sin(theta/2)\|1> |
| `fidelity q, ref -> f` | Wierność q względem stanu, w jakim przygotowano ref |

### Wyświetlanie i sprawdzenia

| Składnia | Znaczenie |
|---|---|
| `show state` | Niezerowe amplitudy, kubity w kolejności deklaracji od lewej |
| `show bloch q` | Wektor Blocha kubitu z macierzy gęstości zredukowanej |
| `say "tekst"` | Wypisanie tekstu |
| `check warunek` | Kończy program kodem 1, jeśli warunek jest fałszywy |
| `expect q == ref` | Sprawdza, że wierność q względem ref wynosi 1 |

W treści obwodu działa zwykły kod RecurLoop: `if`, `while`, `var`, `return`,
`printf` oraz funkcje `pi()` i `approx(a, b)`.

## Jak działa symulator

Rejestr n kubitów to wektor 2^n amplitud zespolonych. Kubit o indeksie k
odpowiada bitowi k indeksu amplitudy. Bramka jednokubitowa zmienia tylko pary
amplitud różniące się bitem k, więc nie trzeba budować macierzy 2^n na 2^n
iloczynem Kroneckera. Kubity kontrolne ograniczają zmianę do par, w których
bity kontrolne są równe 1.

Pomiar liczy prawdopodobieństwo wyniku, losuje wynik, zeruje niezgodną gałąź
i normalizuje resztę. Wierność względem przygotowanego stanu liczona jest
przez odwrócenie przygotowania na badanym kubicie i odczyt prawdopodobieństwa
wyniku 0, po czym stan jest przywracany.

## Co poprawia względem starych symulatorów

| Problem w `Symulator` i `Implementacja` | Tutaj |
|---|---|
| Bramki jako pełne macierze z iloczynu Kroneckera | Zmiana tylko par amplitud, pamięć 2^n zamiast 4^n |
| Teleportacja zawsze zakłada wynik pomiaru 01 i korektę X | Losowy pomiar i korekty X oraz Z zależne od wyniku |
| Brak sprawdzenia, że Bob dostał właściwy stan | `expect bob == psi` po każdej teleportacji |
| Warunek z `\|\|` w `Qubit::new` jest zawsze prawdziwy | Stany powstają tylko przez unitarne bramki |

## Ograniczenia RecurLoop znalezione przy pisaniu biblioteki

RecurLoop jest projektem badawczym. Te rzeczy mają obejścia w bibliotece,
ale warto je zgłosić autorowi języka:

1. **Brak operatorów bitowych.** `&`, `|`, `^`, `<<`, `>>` nie działają
   w funkcjach. Bit k liczby x liczony jest jako `x / 2^k % 2`.
2. **Zagnieżdżony blok w funkcji jest pomijany.** Instrukcje w `{ ... }`
   wewnątrz `fn` nie wykonują się i nie ma błędu. Dlatego treść obwodu jest
   wstawiana jako ciało `if 1 == 1 { ... }`.
   ```rl
   fn f() -> i64 {
       var m = 1
       {
           m = 2
       }
       return m
   }
   print f()   // wypisuje 1
   ```
3. **Pętla `while` na poziomie skryptu ma koszt kwadratowy.** Pusta pętla
   z 1000 obrotów trwa około 3 s, z 4000 obrotów około 24 s. Ta sama pętla
   w `fn` jest natychmiastowa, stąd `experiment`.
4. **Wywołania natywne ze skryptu obsługują tylko liczby całkowite.**
   Nie da się przekazać ani odebrać `f64`, więc kąty podaje się w obwodach.
5. **Słowo kluczowe `syntax` dopasowuje się wewnątrz nazw kwalifikowanych.**
   W funkcji `Quantum:measure(...)` jest rozpoznawane jako instrukcja
   `measure`. Funkcje biblioteki mają więc nazwy niezaczynające się od słów
   kluczowych.
6. **Wywołanie `Ns:f(...)` nie działa jako samodzielna instrukcja na poziomie
   skryptu**, choć działa w wyrażeniu. Obejściem jest alias `let f = <Ns:f>`.
7. **Przechwycenie `<t:expr>` łapie `}` z tej samej linii.** Zapis
   `if m == 1 { X bob }` daje błąd, trzeba pisać bramkę w osobnej linii.
8. **`assert` nie działa w funkcjach**, stąd własne `check`.
9. **Wzorzec `syntax` nie może być pusty**, więc jest `show state` zamiast
   samego `show`. To świadoma decyzja w kodzie RecurLoop.

## Plany

1. Superdense coding i nierówność CHSH, do porównania z wersjami w Pythonie.
2. Algorytmy Deutscha-Jozsy i Grovera.
3. Kwantowa transformata Fouriera.
4. Rejestry kubitów, na przykład `qubits r[4]`, i bramki na całych rejestrach.
5. Eksport biblioteki do obrazu `quantum.rli` ładowanego przez `--library`.
