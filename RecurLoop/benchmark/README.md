# Porównanie wydajności: Python, NumPy, Rust i RecurLoop

Ten sam symulator wektora stanu napisany w czterech technologiach. Wszystkie
implementacje dają identyczne sumy kontrolne, więc liczą dokładnie to samo.

## Wyniki

Najlepszy z trzech czasów obliczeń w milisekundach, mierzony wewnątrz programu.
Mniej znaczy lepiej.

| Implementacja | Teleportacja ×100 000 | Warstwy, 16 kubitów | Warstwy, 20 kubitów |
|---|---:|---:|---:|
| Python, czysty | 2 392 | 2 386 | 64 649 |
| Python, NumPy | 22 118 | 184 | 1 633 |
| Rust, dzielenie i modulo | 65 | 40 | 904 |
| Rust, operatory bitowe | 57 | 23 | 500 |
| **RecurLoop** | **77** | **51** | **1 115** |

Ile razy wolniej od najszybszej wersji, czyli Rust z operatorami bitowymi:

| Implementacja | Teleportacja | Warstwy, 16 kubitów | Warstwy, 20 kubitów |
|---|---:|---:|---:|
| Python, czysty | 42× | 103× | 129× |
| Python, NumPy | 389× | 8,0× | 3,3× |
| Rust, dzielenie i modulo | 1,1× | 1,7× | 1,8× |
| **RecurLoop** | **1,3×** | **2,2×** | **2,2×** |

Proces RecurLoop trwał łącznie około 3,1 s. Około 1,9 s z tego to start
i kompilacja programu, a reszta to obliczenia z tabeli. Rust kompiluje się
wcześniej, osobnym poleceniem `rustc`.

## Wnioski

- **RecurLoop jest blisko Rust przy tym samym kodzie.** Jest tylko o 18 do 27%
  wolniejszy od Rust z tym samym obejściem przez dzielenie i modulo. Oba
  generują kod maszynowy przez LLVM.
- **Brak operatorów bitowych kosztuje prawie połowę wydajności.** W warstwach
  Rust z operatorami bitowymi jest 1,7 do 1,8 raza szybszy od wersji
  z dzieleniem.
  Po dodaniu `&` i `>>` do RecurLoop symulator powinien zbliżyć się do Rust.
- **Czysty Python jest 30 do 60 razy wolniejszy od RecurLoop.** Przy 20
  kubitach to ponad minuta wobec nieco ponad sekundy.
- **NumPy nie pomaga przy wielu małych operacjach.** W teleportacji, gdzie
  stan ma tylko 8 amplitud, narzut wywołań NumPy sprawia, że jest 9 razy
  wolniejszy od czystego Pythona i 290 razy wolniejszy od RecurLoop. Przy
  20 kubitach NumPy jest za to tylko 1,5 raza wolniejszy od RecurLoop.

## Co jest mierzone

**Teleportacja ×100 000.** Pełny protokół na 3 kubitach: losowy stan,
para splątana, pomiar Alicji, korekty Boba i sprawdzenie wierności. Dużo
małych operacji, więc liczy się narzut wywołań.

**Warstwy.** Rejestr 16 lub 20 kubitów i 5 warstw. Każda warstwa to bramki
H i RY na każdym kubicie, a potem łańcuch CNOT między sąsiadami. Przy 20
kubitach to milion amplitud, więc liczy się szybkość pętli po pamięci.

**Algorytm.** Wszystkie wersje poza NumPy przechodzą po wszystkich indeksach
amplitud, sprawdzają bity kubitu docelowego i kontrolnych, a potem zmieniają
parę amplitud. Wersja NumPy trzyma stan jako tensor 2×2×…×2 i aplikuje bramkę
przez `tensordot` po osi kubitu.

**Wariant z dzieleniem.** RecurLoop nie ma operatorów bitowych, więc bit k
liczby i liczony jest jako `i / 2^k % 2`. Rust jest zmierzony w obu
wariantach, żeby oddzielić koszt tego obejścia od jakości kompilatora.

## Zastrzeżenia

- Pomiary pochodzą z maszyny wirtualnej, gdzie powtórzenia różnią się
  o kilkanaście procent. Dlatego tabela podaje najlepszy z trzech czasów.
- Generatory liczb losowych są różne, więc rozkład wyników teleportacji
  różni się między językami. Sumy kontrolne warstw nie używają losowości.
- Wersja NumPy jest typowa, ale nie najszybsza możliwa. Ręcznie
  zoptymalizowany NumPy, na przykład z indeksowaniem po wycinkach zamiast
  `tensordot`, byłby szybszy przy dużych rejestrach.

## Środowisko

| | |
|---|---|
| Procesor | Intel Xeon @ 2,10 GHz, 4 rdzenie wirtualne |
| System | Linux x86-64 |
| Python | 3.11.15, NumPy 2.4.6 |
| Rust | rustc 1.97.0, `-C opt-level=3 -C target-cpu=native` |
| RecurLoop | commit `5534f94`, kompilacja Release z LLVM 22.1.8 |

## Uruchomienie

```bash
pip install numpy
./uruchom_benchmark.sh /sciezka/do/RecurLoop/build/Release/bin/recurloop
```

Liczbę powtórzeń zmienia zmienna `POWTORZENIA`, domyślnie 3. Całość trwa
około 5 minut, głównie przez czysty Python przy 20 kubitach.
