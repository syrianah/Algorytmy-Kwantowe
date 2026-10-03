# Algorytmy kwantowe

Symulacje algorytmów i protokołów kwantowych. Główną częścią repo jest
język obwodów kwantowych zbudowany w
[RecurLoop](https://github.com/RecurLoop/RecurLoop), w którym bramki,
pomiary i bloki `circuit` są nowymi konstrukcjami języka. Obwody można
symulować albo skompilować do OpenQASM 3 i uruchomić na komputerze
kwantowym IBM.

Wyniki na prawdziwych procesorach IBM, 3 października 2026, po 4000
przebiegów każdego obwodu. Ostatnia kolumna to wynik losowy albo najlepszy
możliwy bez splątania. Szczegóły są w
[`RecurLoop/ibm/README.md`](RecurLoop/ibm/README.md#wyniki-na-prawdziwym-sprzęcie).

| Algorytm | Procesor | Wynik | Bez kwantowej przewagi |
|---|---|---:|---:|
| Teleportacja | `ibm_kingston` | 94,5% | 50% |
| Kodowanie supergęste | `ibm_fez` | 96,8% | 25% |
| Gra CHSH | `ibm_fez` | S = 2,70 | S ≤ 2 |
| QFT, odczyt liczby z faz | `ibm_fez` | 90,5% | 12,5% |

Tak wygląda teleportacja w tym języku:

```rl
circuit teleportacja {
    qubit psi
    qubit alicja
    qubit bob
    prepare psi random
    H alicja
    CNOT alicja, bob
    CNOT psi, alicja
    H psi
    measure psi -> m1
    measure alicja -> m2
    if m2 == 1 {
        X bob
    }
    if m1 == 1 {
        Z bob
    }
    expect bob == psi
}
```

## Struktura

| Katalog | Zawartość |
|---|---|
| [`RecurLoop`](RecurLoop) | Biblioteka `quantum.rl`, testy i przykłady: stan Bella, teleportacja |
| [`RecurLoop/ibm`](RecurLoop/ibm) | Kompilacja do OpenQASM 3 i uruchomienie na komputerze kwantowym IBM |
| [`RecurLoop/benchmark`](RecurLoop/benchmark) | Porównanie wydajności: Python, NumPy, Rust i RecurLoop |
| [`materialy`](materialy) | Egzamin, listy zadań i schematy protokołów |
| [`archiwum`](archiwum) | Pierwsze implementacje w Pythonie, Rust i Qiskit |

## Szybki start

```bash
git clone https://github.com/RecurLoop/RecurLoop.git
cd RecurLoop && make && cd ..

cd Algorytmy-Kwantowe/RecurLoop
./uruchom.sh ../../RecurLoop/build/Release/bin/recurloop
```

Szczegóły języka obwodów są w [`RecurLoop/README.md`](RecurLoop/README.md).
