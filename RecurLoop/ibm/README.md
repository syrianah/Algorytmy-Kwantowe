# Protokoły i algorytmy kwantowe na komputerze kwantowym IBM

Te same obwody napisane w naszym języku można symulować albo skompilować do
OpenQASM 3 i uruchomić na prawdziwym procesorze IBM. Backend wybiera się
przez dołączoną bibliotekę: `quantum.rl` symuluje, a `qasm.rl` kompiluje.

| Plik | Zawartość |
|---|---|
| `obwody.rl` | Obwody w naszym języku, bez wyboru backendu |
| `symuluj.rl` | Symulacja obwodów biblioteką `quantum.rl` |
| `generuj_qasm.rl` | Kompilacja obwodów do plików `.qasm` biblioteką `qasm.rl` |
| `*.qasm` | Wygenerowane programy OpenQASM 3 |
| `sprawdz_szum.py` | Uruchomienie na modelach szumu procesorów IBM, bez konta |
| `uruchom_ibm.py` | Uruchomienie na prawdziwym procesorze IBM |
| `wymagania.txt` | Pakiety Pythona |

## Obwody

- **`teleportacja`** to obwód dynamiczny. Alicja mierzy dwa kubity w trakcie
  obwodu, a procesor od razu stosuje korekty X i Z na kubicie Boba.
- **`teleportacja_odroczona`** daje ten sam wynik bez pomiarów w trakcie
  obwodu. Korekty są sterowane kwantowo przez CNOT i CZ, a pomiary są na
  końcu. Działa na każdym procesorze.
- **`kontrola`** to tylko przygotowanie i odwrócenie stanu na jednym kubicie.
  Pokazuje, ile błędów wnosi sam sprzęt bez teleportacji.
- **`superdense_00`, `superdense_01`, `superdense_10`, `superdense_11`** to
  kodowanie supergęste. Alicja wysyła Bobowi dwa bity, przekazując mu jeden
  kubit ze wspólnej pary splątanej. Każdy obwód wysyła inną wiadomość, a
  bity Boba trafiają do rejestrów `odczyt1` i `odczyt2`.
- **`chsh_00`, `chsh_01`, `chsh_10`, `chsh_11`** to gra CHSH. Alicja dostaje
  pytanie x, Bob pytanie y, i wygrywają, gdy ich odpowiedzi a i b spełniają
  a XOR b = x AND y. Obwód `chsh_XY` gra z pytaniami x = X i y = Y.
  Klasycznie da się wygrać najwyżej 75% gier, a z parą splątaną 85,4%.
  Ze średniej wygranych w czterech obwodach liczona jest wartość
  S = 8 * średnia - 4. Klasycznie S <= 2, kwantowo do 2 sqrt(2) = 2,83.
- **`qft_0` do `qft_7`** to kwantowa transformata Fouriera z biblioteki
  `../qft.rl`, w roli jaką pełni w estymacji fazy. Liczba K jest zapisana
  wyłącznie w fazach trzech kubitów, bez splątania. QFT odwrotna zamienia
  fazy na liczbę, a pomiar rejestru `wynik` powinien dać K. Zgadując,
  trafiałoby się w 12,5% przebiegów.

Na sprzęcie nie da się odczytać stanu Boba wprost. Dlatego `expect bob == psi`
odwraca na kubicie Boba przygotowanie stanu psi i mierzy go do bitu
`expect_bob`. Udana teleportacja daje zawsze 0. Gdyby stan Boba był
całkowicie przypadkowy, wynik 0 wypadałby tylko w połowie przebiegów.

W kodowaniu supergęstym sukces oznacza, że Bob odczytał dokładnie wysłane
bity. Zgadując, trafiałby w 25% przebiegów. Wynik każdego z tych obwodów jest
znany z góry, więc kompilator Qiskit mógłby usunąć z nich splątanie i
zostawić same bramki X przed pomiarem. Zapobiegają temu `barrier alicja, bob`
między przygotowaniem pary, kodowaniem u Alicji i dekodowaniem u Boba.

## Krok po kroku

**1. Wygeneruj pliki QASM.** Gotowe pliki są już w repo. Ziarno losowości
jest stałe, więc ponowne generowanie daje te same pliki.

```bash
recurloop --file generuj_qasm.rl
```

**2. Zainstaluj pakiety Pythona.**

```bash
pip install -r wymagania.txt
```

**3. Sprawdź na modelach szumu.** Nie wymaga konta.

```bash
python3 sprawdz_szum.py
```

**4. Zapisz klucz API.** Klucz znajdziesz na stronie konta IBM Quantum
Platform. Zapisuje się go raz, lokalnie na komputerze. Nigdy nie wpisuj go
do plików w repo.

```python
from qiskit_ibm_runtime import QiskitRuntimeService
QiskitRuntimeService.save_account(
    channel="ibm_quantum_platform", token="TWÓJ_KLUCZ_API", set_as_default=True)
```

Zamiast zapisywać konto, można ustawić zmienną środowiskową
`IBM_QUANTUM_TOKEN` z kluczem i opcjonalnie `IBM_QUANTUM_INSTANCE`.

**5. Sprawdź połączenie.** Bez flagi `--wyslij` skrypt tylko wybiera procesor
i kompiluje obwody, niczego nie wysyłając.

```bash
python3 uruchom_ibm.py
```

**6. Wyślij zadanie.**

```bash
python3 uruchom_ibm.py --wyslij
```

Domyślnie wysyłane są wszystkie obwody. Flaga `--zestaw teleportacja` albo
`--zestaw superdense`, `--zestaw chsh` albo `--zestaw qft` wybiera tylko
jedną grupę.

Skrypt wypisze identyfikator zadania i poczeka na wynik. Kolejka może trwać
od minut do godzin. Wyniki można też pobrać później:

```bash
python3 uruchom_ibm.py --zadanie ID_ZADANIA
```

## Czego się spodziewać

Wyniki na modelach szumu, po 4000 przebiegów każdego obwodu:

| Procesor | teleportacja | teleportacja_odroczona | kontrola |
|---|---:|---:|---:|
| Brisbane | 94,8% | 96,4% | 99,5% |
| Torino | 96,9% | 97,9% | 99,8% |
| Fez | 98,6% | 98,7% | 100,0% |

Kodowanie supergęste na tych samych modelach, sukces dla wiadomości:

| Procesor | 00 | 01 | 10 | 11 |
|---|---:|---:|---:|---:|
| Brisbane | 96,3% | 95,2% | 96,8% | 95,2% |
| Torino | 97,9% | 97,2% | 97,9% | 97,2% |
| Fez | 99,3% | 98,4% | 98,7% | 97,9% |

Gra CHSH na tych samych modelach, wygrane dla pytań x y i wartość S:

| Procesor | 00 | 01 | 10 | 11 | S |
|---|---:|---:|---:|---:|---:|
| Brisbane | 83,9% | 84,0% | 82,2% | 83,4% | 2,670 |
| Torino | 84,1% | 84,8% | 83,2% | 84,4% | 2,729 |
| Fez | 84,8% | 83,8% | 84,5% | 84,7% | 2,754 |

QFT na tych samych modelach, odsetek przebiegów z odczytaną liczbą K:

| Procesor | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | Średnio |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Brisbane | 91,1% | 90,7% | 90,4% | 91,8% | 91,5% | 90,3% | 90,7% | 92,1% | 91,1% |
| Torino | 94,0% | 93,6% | 94,0% | 93,0% | 93,5% | 91,9% | 93,7% | 92,9% | 93,3% |
| Fez | 97,2% | 95,9% | 95,5% | 95,0% | 96,2% | 95,6% | 95,7% | 94,0% | 95,6% |

Obwody QFT po kompilacji mają po 9 bramek dwukubitowych, więcej niż
pozostałe, stąd niższe wyniki.

Na prawdziwym sprzęcie wyniki będą prawdopodobnie trochę niższe:

- **Modele pochodzą ze starszych kalibracji.** Aktualne parametry procesora
  mogą być lepsze albo gorsze.
- **Model prawdopodobnie nie oddaje w pełni czasu oczekiwania na pomiar
  w obwodzie dynamicznym.** Na sprzęcie kubit Boba czeka, aż procesor zmierzy kubity Alicji i podejmie
  decyzję. W tym czasie traci spójność, więc obwód `teleportacja` może
  wypaść gorzej niż `teleportacja_odroczona`.
- **Wynik zależy od wylosowanego stanu psi.** Niektóre stany są bardziej
  wrażliwe na konkretne błędy sprzętu.

Każdy wynik wyraźnie powyżej 50% pokazuje, że teleportacja działa. Różnica
między `kontrola` a obwodami teleportacji to koszt samego protokołu.

## Wyniki na prawdziwym sprzęcie

Podsumowanie. Ostatnia kolumna to wynik losowy albo najlepszy możliwy bez
splątania. Wszystkie zadania razem zajęły 28 sekund czasu procesora.

| Algorytm | Procesor | Wynik | Bez kwantowej przewagi |
|---|---|---:|---:|
| Teleportacja | `ibm_kingston` | 94,5% | 50% |
| Kodowanie supergęste | `ibm_fez` | 96,8% | 25% |
| Gra CHSH | `ibm_fez` | S = 2,70 | S ≤ 2 |
| QFT, odczyt liczby z faz | `ibm_fez` | 90,5% | 12,5% |

### Teleportacja

3 października 2026 obwody uruchomiono na procesorze `ibm_kingston`
(156 kubitów), po 4000 przebiegów każdego obwodu. Zadanie
`db04selj371s73dnt1p0` zajęło 5 sekund czasu procesora.

| Obwód | Sukces na `ibm_kingston` |
|---|---:|
| teleportacja | 94,5% |
| teleportacja_odroczona | 96,4% |
| kontrola | 98,9% |

Wyniki obwodu `teleportacja` w podziale na pomiary Alicji:

| m1 m2 | Liczba przebiegów | Korekta na kubicie Boba | Sukces |
|---|---:|---|---:|
| 00 | 1023 | brak | 92,5% |
| 01 | 1019 | X | 95,2% |
| 10 | 1042 | Z | 94,5% |
| 11 | 916 | X i Z | 95,7% |

Co z tego wynika:

- **Teleportacja działa na prawdziwym sprzęcie.** Stan psi trafia do Boba
  w około 95% przypadków. Odchylenie standardowe przy 4000 przebiegach to
  około 0,4 punktu procentowego.
- **Korekty sterowane pomiarem działają.** Każdy z czterech wyników Alicji
  pojawia się w około 25% przebiegów i we wszystkich czterech przypadkach Bob
  dostaje poprawny stan. Bez korekt X i Z trzy z czterech gałęzi dałyby wynik
  bliski losowemu.
- **Obwód dynamiczny wypada gorzej od odroczonego** o około 2 punkty, mimo
  że ma mniej bramek dwukubitowych (2 wobec 7). To koszt czekania kubitu Boba
  na pomiar i decyzję procesora, o którym mowa wyżej.
- **Około 1,1% błędów to sam odczyt.** Tyle wynosi błąd obwodu `kontrola`,
  w którym kompilator usunął przygotowanie i odwrócenie stanu jako wzajemnie
  się znoszące, więc został sam pomiar.
- **Wynik jest najbliżej modelu Brisbane**, czyli bliżej najsłabszego
  z modeli szumu, choć Kingston jest procesorem nowszej generacji.

### Kodowanie supergęste

Tego samego dnia cztery obwody kodowania supergęstego uruchomiono na
procesorze `ibm_fez` (156 kubitów), po 4000 przebiegów każdego. Zadanie
`db0533lj371s73dntdm0` zajęło 6 sekund czasu procesora.

| Wysłana wiadomość | Bob odczytał 00 | 01 | 10 | 11 | Sukces | Model Fez |
|---|---:|---:|---:|---:|---:|---:|
| 00 | **3861** | 63 | 58 | 18 | 96,5% | 99,3% |
| 01 | 40 | **3918** | 10 | 32 | 98,0% | 98,4% |
| 10 | 76 | 15 | **3822** | 87 | 95,5% | 98,7% |
| 11 | 10 | 58 | 53 | **3879** | 97,0% | 97,9% |

Co z tego wynika:

- **Jeden kubit przenosi dwa bity.** Bob odczytuje właściwą wiadomość
  średnio w 96,8% przebiegów. Zgadując, trafiałby w 25%.
- **Błędy dotyczą zwykle jednego bitu.** Odczyt różniący się od wiadomości
  na obu bitach naraz zdarza się od 10 do 18 razy na 4000 przebiegów. To
  pasuje do niezależnych błędów bramek i odczytu na każdym kubicie.
- **Sprzęt wypadł o 0,4 do 3,2 punktu gorzej od modelu Fez.** Model pochodzi
  ze starszej kalibracji, a parametry procesora zmieniają się z dnia na dzień.
- **Bariery są konieczne.** Bez `barrier alicja, bob` kompilator zamieniłby
  każdy z tych obwodów w bramki X przed pomiarem. Wynik byłby wtedy prawie
  idealny, ale bez splątania, więc nie świadczyłby o niczym.

### Gra CHSH

Tego samego dnia cztery obwody gry CHSH uruchomiono na procesorze `ibm_fez`,
po 4000 przebiegów każdego. Zadanie `db05ba492g1c7399tjb0` zajęło 6 sekund
czasu procesora.

| Pytania x y | Wygrane na `ibm_fez` | Model Fez | Ideał |
|---|---:|---:|---:|
| 00 | 84,3% | 84,8% | 85,4% |
| 01 | 84,4% | 83,8% | 85,4% |
| 10 | 83,9% | 84,5% | 85,4% |
| 11 | 82,6% | 84,7% | 85,4% |
| **S** | **2,704** | 2,754 | 2,828 |

Co z tego wynika:

- **Nierówność Bella jest złamana.** S = 2,704 ± 0,023, czyli o 0,70 ponad
  klasyczną granicę 2. To ponad 30 odchyleń standardowych, więc wynik nie
  jest przypadkiem statystycznym.
- **Alicja i Bob wygrali średnio 83,8% gier.** Żadna strategia klasyczna
  nie daje więcej niż 75%, nawet gdy gracze przed grą uzgodnią wspólne
  losowe bity.
- **Wynik jest bliski ideału mimo szumu.** Szum obniżył S z 2,828 do 2,704,
  czyli o około 4%. Obwód ma tylko jedną bramkę dwukubitową.
- **To samo zastrzeżenie co przy każdym takim teście na jednym chipie.**
  Kubity Alicji i Boba leżą obok siebie, a pytania są wpisane w obwód przed
  uruchomieniem. Pomiar nie zamyka więc luki lokalności tak jak
  eksperymenty z odległymi detektorami, ale pokazuje korelacje, których
  nie da się uzyskać z klasycznych bitów.

### Kwantowa transformata Fouriera

Tego samego dnia osiem obwodów QFT uruchomiono na procesorze `ibm_fez`, po
4000 przebiegów każdego. Zadanie `db05kfc92g1c7399ttag` zajęło 11 sekund
czasu procesora.

| Zapisana liczba K | Odczytano K | Model Fez | Błąd jednego bitu | Większy błąd |
|---|---:|---:|---:|---:|
| 0 (000) | 94,7% | 97,2% | 116 | 98 |
| 1 (001) | 92,0% | 95,9% | 188 | 131 |
| 2 (010) | 90,3% | 95,5% | 236 | 153 |
| 3 (011) | 88,0% | 95,0% | 265 | 213 |
| 4 (100) | 92,6% | 96,2% | 211 | 86 |
| 5 (101) | 90,8% | 95,6% | 254 | 115 |
| 6 (110) | 88,9% | 95,7% | 302 | 140 |
| 7 (111) | 86,5% | 94,0% | 357 | 185 |
| **Średnio** | **90,5%** | 95,6% | | |

Dwie ostatnie kolumny to liczba przebiegów na 4000, w których odczyt różnił
się od K na jednym bicie albo na więcej niż jednym.

Co z tego wynika:

- **QFT odwrotna odczytuje liczbę z faz w 90,5% przebiegów.** Zgadując jedną
  z ośmiu liczb, trafiałoby się w 12,5%. Każdy z ośmiu obwodów daje
  poprawną liczbę wielokrotnie częściej niż jakąkolwiek inną.
- **Im więcej jedynek w K, tym gorzej.** Średnio 94,7% dla liczby bez
  jedynek, 91,6% dla liczb z jedną, 89,2% z dwiema i 86,5% z trzema, czyli
  mniej więcej 2,7 punktu na każdą jedynkę. Przy K = 7 każdy błąd jednego
  bitu to zamiana 1 na 0 (357 przypadków), a przy K = 0 zamiana 0 na 1 (116).
  Kubit w stanie |1> częściej spada do |0> podczas pomiaru niż odwrotnie, bo
  stan |1> ma wyższą energię i rozpada się z czasem T1.
- **Sprzęt wypadł o około 5 punktów gorzej od modelu Fez.** To największa
  różnica ze wszystkich obwodów. Obwody QFT mają najwięcej bramek
  dwukubitowych (9) i są najgłębsze, więc różnica między starą kalibracją
  w modelu a dzisiejszym stanem procesora kumuluje się najbardziej.

## Konto i limity

Darmowy plan IBM Quantum daje ograniczony czas na prawdziwych procesorach
w każdym miesiącu, w planie Open 10 minut. Ten zestaw zużywa go niewiele:
wszystkie 23 obwody po 4000 powtórzeń zajęły razem 28 sekund (5 sekund
teleportacja, po 6 kodowanie supergęste i CHSH, 11 QFT). Liczbę powtórzeń
zmienia flaga `--strzaly`, a flaga `--zestaw` pozwala wysłać tylko jedną
grupę obwodów.
