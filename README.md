# Algorytmy kwantowe

Symulacje algorytmów i protokołów kwantowych. Główną częścią repo jest
biblioteka obwodów kwantowych w języku
[RecurLoop](https://github.com/RecurLoop/RecurLoop), w której bramki,
pomiary i bloki `circuit` są nowymi konstrukcjami języka.

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
