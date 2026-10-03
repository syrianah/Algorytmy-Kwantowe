"""Uruchamia obwody na modelach szumu procesorów IBM, bez konta i bez kolejki.

Modele pochodzą z pakietu qiskit-ibm-runtime i odwzorowują błędy bramek,
pomiaru i dekoherencji z kalibracji prawdziwych procesorów.

Użycie, z katalogu ibm, po wygenerowaniu plików .qasm:
  python3 sprawdz_szum.py
"""

import warnings

from qiskit import transpile
from qiskit_ibm_runtime import SamplerV2
from qiskit_ibm_runtime.fake_provider import FakeBrisbane, FakeFez, FakeTorino

from wspolne import CHSH, OBWODY, podsumuj, wartosc_s, wczytaj

warnings.filterwarnings("ignore")
STRZALY = 4000


def main():
    print(f"{'procesor':16s} {'obwód':24s} {'sukces':>8s} {'bramki 2q':>10s} {'głębokość':>10s}")
    for procesor in (FakeBrisbane(), FakeTorino(), FakeFez()):
        sukcesy = {}
        for nazwa in OBWODY:
            obwod = wczytaj(nazwa)
            if "if_else" in obwod.count_ops() and "if_else" not in procesor.target.operation_names:
                print(f"{procesor.name:16s} {nazwa:24s}   procesor nie obsługuje obwodów dynamicznych")
                continue
            skompilowany = transpile(obwod, procesor, optimization_level=3, seed_transpiler=11)
            wynik = SamplerV2(mode=procesor).run([skompilowany], shots=STRZALY).result()[0]
            sukces = podsumuj(nazwa, wynik.data, STRZALY)
            sukcesy[nazwa] = sukces
            bramki_2q = sum(n for g, n in skompilowany.count_ops().items() if g in ("ecr", "cz", "cx"))
            print(f"{procesor.name:16s} {nazwa:24s} {sukces * 100:7.1f}% {bramki_2q:10d} {skompilowany.depth():10d}")
        print(f"{procesor.name:16s} {'CHSH: S':24s} {wartosc_s([sukcesy[n] for n in CHSH]):8.3f}")


if __name__ == "__main__":
    main()
