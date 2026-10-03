"""Uruchamia obwody na prawdziwym komputerze kwantowym IBM.

Domyślnie tylko łączy się z kontem, wybiera procesor i kompiluje obwody,
nic nie wysyłając. Zadanie trafia do kolejki dopiero z flagą --wyslij,
bo czas na prawdziwym sprzęcie jest ograniczony.

Konto zapisuje się raz, poleceniem w Pythonie:
  from qiskit_ibm_runtime import QiskitRuntimeService
  QiskitRuntimeService.save_account(
      channel="ibm_quantum_platform", token="TWÓJ_KLUCZ_API", set_as_default=True)

Użycie, z katalogu ibm, po wygenerowaniu plików .qasm:
  python3 uruchom_ibm.py                     # sprawdzenie, nic nie wysyła
  python3 uruchom_ibm.py --wyslij            # wysyła do najmniej zajętego procesora
  python3 uruchom_ibm.py --procesor ibm_fez --wyslij
  python3 uruchom_ibm.py --zadanie ID        # pobiera wyniki wysłanego wcześniej zadania
"""

import argparse

from qiskit import transpile
from qiskit_ibm_runtime import QiskitRuntimeService, SamplerV2

from wspolne import OBWODY, podsumuj, wczytaj


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--procesor", help="nazwa procesora, domyślnie najmniej zajęty")
    parser.add_argument("--strzaly", type=int, default=4000, help="liczba powtórzeń każdego obwodu")
    parser.add_argument("--wyslij", action="store_true", help="naprawdę wyślij zadanie do kolejki IBM")
    parser.add_argument("--zadanie", help="pobierz wyniki zadania o podanym ID")
    args = parser.parse_args()

    serwis = QiskitRuntimeService()

    if args.zadanie:
        zadanie = serwis.job(args.zadanie)
        print(f"Zadanie {zadanie.job_id()} na {zadanie.backend().name}, stan: {zadanie.status()}")
        pokaz_wyniki(zadanie.result(), OBWODY, args.strzaly)
        return

    obwody = [wczytaj(nazwa) for nazwa in OBWODY]
    if args.procesor:
        procesor = serwis.backend(args.procesor)
    else:
        procesor = serwis.least_busy(operational=True, simulator=False, dynamic_circuits=True)
    print(f"Procesor: {procesor.name}, {procesor.num_qubits} kubitów, oczekujące zadania: {procesor.status().pending_jobs}")

    skompilowane = [transpile(o, procesor, optimization_level=3, seed_transpiler=11) for o in obwody]
    for o in skompilowane:
        bramki_2q = sum(n for g, n in o.count_ops().items() if g in ("ecr", "cz", "cx"))
        print(f"  {o.name:24s} bramki 2q: {bramki_2q:3d}, głębokość: {o.depth():3d}")

    if not args.wyslij:
        print("\nTo było tylko sprawdzenie. Dodaj --wyslij, żeby wysłać zadanie do kolejki.")
        return

    zadanie = SamplerV2(mode=procesor).run(skompilowane, shots=args.strzaly)
    print(f"\nWysłano zadanie {zadanie.job_id()}. Czekam na wynik, co może potrwać.")
    print(f"Wyniki można też pobrać później: python3 uruchom_ibm.py --zadanie {zadanie.job_id()}")
    pokaz_wyniki(zadanie.result(), OBWODY, args.strzaly)


def pokaz_wyniki(wynik, nazwy, strzaly):
    print()
    for nazwa, w in zip(nazwy, wynik):
        print(f"  {nazwa:24s} sukces: {podsumuj(nazwa, w.data, strzaly) * 100:5.1f}%")
    print("\nUdana teleportacja daje 100% na idealnym sprzęcie, a całkowicie losowy wynik 50%.")


if __name__ == "__main__":
    main()
