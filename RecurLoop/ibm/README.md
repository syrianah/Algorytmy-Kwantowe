# Teleportacja i kodowanie supergęste na komputerze kwantowym IBM

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
`--zestaw superdense` wybiera tylko jedną grupę.

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

## Konto i limity

Darmowy plan IBM Quantum daje ograniczony czas na prawdziwych procesorach
w każdym miesiącu. Ten zestaw zużywa go niewiele: trzy krótkie obwody po
4000 powtórzeń. Liczbę powtórzeń zmienia flaga `--strzaly`.
