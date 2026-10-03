"""Funkcje wspólne dla sprawdz_szum.py i uruchom_ibm.py."""

from pathlib import Path

from qiskit import qasm3

KATALOG = Path(__file__).resolve().parent
OBWODY = ["teleportacja", "teleportacja_odroczona", "kontrola"]


def wczytaj(nazwa):
    """Wczytuje plik nazwa.qasm wygenerowany przez generuj_qasm.rl."""
    sciezka = KATALOG / f"{nazwa}.qasm"
    if not sciezka.exists():
        raise SystemExit(
            f"Brak pliku {sciezka.name}. Najpierw uruchom w tym katalogu:\n"
            "  recurloop --file generuj_qasm.rl"
        )
    obwod = qasm3.loads(sciezka.read_text())
    obwod.name = nazwa
    return obwod


def podsumuj(nazwa, dane, strzaly):
    """Zwraca odsetek przebiegów, w których bit expect wynosi 0.

    Bit expect jest wynikiem pomiaru po odwróceniu przygotowania stanu psi.
    Udana teleportacja daje zawsze 0. Całkowicie losowy stan Boba dałby 0
    tylko w połowie przypadków.
    """
    rejestry = [r for r in dir(dane) if r.startswith("expect_")]
    if len(rejestry) != 1:
        raise RuntimeError(f"{nazwa}: oczekiwano jednego rejestru expect_, są {rejestry}")
    wyniki = getattr(dane, rejestry[0]).get_counts()
    return wyniki.get("0", 0) / strzaly
