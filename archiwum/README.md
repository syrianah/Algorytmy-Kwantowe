# Archiwum

Pierwsze implementacje z początków nauki programowania. Zostają tu jako
historia i punkt odniesienia. Aktualny symulator jest w katalogu
[`RecurLoop`](../RecurLoop).

| Katalog | Zawartość |
|---|---|
| `python-implementacja` | Symulator w Pythonie z własną klasą liczb zespolonych: teleportacja, superdense coding, CHSH |
| `rust-symulator` | Symulator w Rust oparty na `ndarray`: teleportacja |
| `qiskit` | Eksperymenty z CHSH w Qiskit |

## Znane problemy

- **Bramki jako pełne macierze.** Obie implementacje budują macierz bramki
  iloczynem Kroneckera, więc pamięć rośnie jak 4^n zamiast 2^n.
- **Teleportacja z zaszytym wynikiem pomiaru.** Obie wersje zawsze biorą
  wynik 01 i zawsze stosują korektę X. Prawdziwy protokół losuje jeden
  z czterech wyników i dobiera korekty X oraz Z.
- **`Qubit::new` w Rust niczego nie sprawdza.** Warunek
  `0.999999998 <= check || check <= 1.00000001` jest zawsze prawdziwy,
  a norma liczona jest jako |a|^4 + |b|^4 zamiast |a|^2 + |b|^2.
- **Losowy kubit często jest błędny.** `randomQ` w Pythonie w około 27%
  prób daje stan bez normy 1 albo kończy się wyjątkiem. `Qubit::random`
  w Rust ma ten sam algorytm i czasem kończy program panikiem, co zauważa
  już komentarz w kodzie.
- **CHSH w Pythonie zawsze odpowiada 01.** `chsh.py` przed wyborem wyniku
  rzutuje stan na `M01`, więc pomiar zawsze daje 01. Alicja i Bob wygrywają
  wtedy około 25% gier, mniej niż najlepsza strategia klasyczna (75%).
- **Kąty CHSH są o połowę za małe.** Obie wersje obracają kubity bramką RY
  o 0 i pi/4 u Alicji oraz o pi/8 i -pi/8 u Boba. Takie kąty pasują do
  polaryzacji fotonów, ale RY obraca kubit na sferze Blocha o pełny kąt.
  Nawet z poprawnym pomiarem dają około 79,9% wygranych zamiast 85,4%.
- **Qiskit w starym API.** `BasicAer` i `execute` zostały usunięte
  w Qiskit 1.0, więc te skrypty wymagają starszej wersji Qiskit.

## Uruchomienie

```bash
cd python-implementacja && pip install numpy && python3 teleportation.py
cd rust-symulator && cargo run --release
```
