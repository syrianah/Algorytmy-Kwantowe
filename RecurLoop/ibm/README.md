# Teleportacja na komputerze kwantowym IBM

Te same obwody napisane w naszym języku można symulować albo skompilować do
OpenQASM 3 i uruchomić na prawdziwym procesorze IBM. Backend wybiera się
przez dołączoną bibliotekę: `quantum.rl` symuluje, a `qasm.rl` kompiluje.

| Plik | Zawartość |
|---|---|
| `obwody.rl` | Trzy obwody w naszym języku, bez wyboru backendu |
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

Na sprzęcie nie da się odczytać stanu Boba wprost. Dlatego `expect bob == psi`
odwraca na kubicie Boba przygotowanie stanu psi i mierzy go do bitu
`expect_bob`. Udana teleportacja daje zawsze 0. Gdyby stan Boba był
całkowicie przypadkowy, wynik 0 wypadałby tylko w połowie przebiegów.

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

**5. Sprawdź połączenie.** Bez flagi `--wyslij` skrypt tylko wybiera procesor
i kompiluje obwody, niczego nie wysyłając.

```bash
python3 uruchom_ibm.py
```

**6. Wyślij zadanie.**

```bash
python3 uruchom_ibm.py --wyslij
```

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

## Konto i limity

Darmowy plan IBM Quantum daje ograniczony czas na prawdziwych procesorach
w każdym miesiącu. Ten zestaw zużywa go niewiele: trzy krótkie obwody po
4000 powtórzeń. Liczbę powtórzeń zmienia flaga `--strzaly`.
