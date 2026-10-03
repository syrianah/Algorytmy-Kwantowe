# Quantum: obwody kwantowe w RecurLoop

Biblioteki [RecurLoop](https://github.com/RecurLoop/RecurLoop), które dodają do
języka składnię obwodów kwantowych. Bramki, pomiary i bloki `circuit` to nowe
frazy języka zdefiniowane w samych bibliotekach, bez zmian w kompilatorze.

Ten sam obwód ma dwa backendy, wybierane przez dołączoną bibliotekę:

- **`quantum.rl`** symuluje obwód. Każdy obwód kompiluje się do natywnej
  funkcji liczącej wektor stanu.
- **`qasm.rl`** kompiluje obwód do OpenQASM 3, który można uruchomić na
  komputerze kwantowym IBM. Instrukcja jest w [`ibm/README.md`](ibm/README.md).

Napisane w tym języku teleportacja, kodowanie supergęste, gra CHSH i QFT
zadziałały na prawdziwych procesorach IBM. Wyniki są w
[`ibm/README.md`](ibm/README.md#wyniki-na-prawdziwym-sprzęcie).

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
| `qasm.rl` | Kompilator tych samych obwodów do OpenQASM 3 |
| `qft.rl` | Kwantowa transformata Fouriera i jej odwrotność, dla obu backendów |
| `ibm/` | Wszystkie protokoły na prawdziwym komputerze kwantowym IBM |
| `testy.rl` | Testy wszystkich bramek, pomiaru i wierności |
| `przyklady/bell.rl` | Stan Bella i statystyka pomiarów |
| `przyklady/chsh.rl` | Gra CHSH ze splątaniem i bez, wartość S i klasyczna granica |
| `przyklady/qft.rl` | QFT liczby, wykrywanie okresu i odczyt liczby zapisanej w fazach |
| `przyklady/superdense.rl` | Kodowanie supergęste: cztery wiadomości krok po kroku i 10 000 przebiegów |
| `przyklady/teleportacja.rl` | Pełny protokół teleportacji krok po kroku i 10 000 losowych przebiegów |
| `uruchom.sh` | Uruchamia testy i przykłady |
| `benchmark/` | Ten sam symulator w Pythonie, NumPy i Rust oraz porównanie wydajności, wyniki w `benchmark/README.md` |

## Język obwodów

### Definicje

| Składnia | Znaczenie |
|---|---|
| `circuit nazwa { ... }` | Obwód jako funkcja natywna `nazwa() -> i64` z własnym rejestrem |
| `circuit nazwa(a:i64, kat:f64) { ... }` | Obwód z parametrami |
| `experiment nazwa { ... }` | Funkcja natywna bez rejestru, na przykład do statystyk |
| `experiment nazwa(n:i64) { ... }` | To samo z parametrami |
| `qubit nazwa` | Nowy kubit w stanie \|0> |
| `qubits r[n]` | Rejestr n kubitów, kolejne kubity to `r[0]`, `r[1]`, ... W QASM `qubit[n] r;` |
| `seed 42` | Stałe ziarno losowości, domyślnie ziarno z zegara |

### Bramki

| Składnia | Bramka |
|---|---|
| `H q`, `X q`, `Y q`, `Z q` | Hadamard i bramki Pauliego |
| `S q`, `T q` | Fazy pi/2 i pi/4 |
| `P(kat) q` | Faza diag(1, e^(i kat)) |
| `RX(kat) q`, `RY(kat) q`, `RZ(kat) q` | Obroty wokół osi sfery Blocha |
| `CNOT c, t`, `CZ c, t` | Bramki kontrolowane |
| `CP(kat) c, t` | Kontrolowana faza: e^(i kat), gdy oba kubity są w stanie 1 |
| `SWAP a, b` | Zamiana kubitów |
| `TOFFOLI c1, c2, t` | Podwójnie kontrolowane NOT |
| `barrier a, b` | Bez działania w symulacji. Na sprzęcie zabrania kompilatorowi upraszczać obwód ponad tym miejscem |

### Pomiar i przygotowanie

| Składnia | Znaczenie |
|---|---|
| `measure q -> m` | Pomiar z losowaniem według reguły Borna i redukcją stanu |
| `measure all r -> x` | Pomiar całego rejestru do liczby, `r[0]` to najmłodszy bit |
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
| `when bit { ... }` | Blok wykonywany, gdy zmierzony bit wynosi 1. W QASM działa na sprzęcie |
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
| CHSH zawsze mierzy 01 i obraca kubity o połowę potrzebnego kąta | Prawdziwy pomiar i kąty dające 85,4% wygranych, S = 2,83 |
| Superdense coding wybiera rzutnik pomiaru na podstawie znanej wiadomości | Bob mierzy oba kubity zwykłym pomiarem i dopiero wtedy poznaje wiadomość |

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

1. Algorytmy Deutscha-Jozsy i Grovera.
2. Estymacja fazy i algorytm Shora dla małych liczb, na bazie `qft.rl`.
3. Bramki na całych rejestrach, na przykład `H all r`.
4. Eksport bibliotek do obrazów `quantum.rli` i `qasm.rli` ładowanych przez
   `--library`.
