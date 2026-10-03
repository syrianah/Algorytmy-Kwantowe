"""Funkcje wspólne dla sprawdz_szum.py i uruchom_ibm.py."""

from pathlib import Path

from qiskit import qasm3

KATALOG = Path(__file__).resolve().parent
TELEPORTACJA = ["teleportacja", "teleportacja_odroczona", "kontrola"]
SUPERDENSE = ["superdense_00", "superdense_01", "superdense_10", "superdense_11"]
OBWODY = TELEPORTACJA + SUPERDENSE


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
    """Zwraca odsetek udanych przebiegów obwodu."""
    if nazwa.startswith("superdense_"):
        return podsumuj_superdense(nazwa, dane, strzaly)
    return podsumuj_expect(nazwa, dane, strzaly)


def podsumuj_expect(nazwa, dane, strzaly):
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


def odczyty_boba(dane):
    """Zwraca listę dwubitowych wiadomości odczytanych przez Boba, np. "10"."""
    return [a + b for a, b in zip(dane.odczyt1.get_bitstrings(), dane.odczyt2.get_bitstrings())]


def podsumuj_superdense(nazwa, dane, strzaly):
    """Zwraca odsetek przebiegów, w których Bob odczytał wysłaną wiadomość.

    Wiadomość jest zapisana w nazwie obwodu: superdense_10 wysyła bity 1 i 0.
    Bez splątania Bob trafiałby losowo w jedną z czterech wiadomości, czyli w 25%.
    """
    wiadomosc = nazwa.removeprefix("superdense_")
    return odczyty_boba(dane).count(wiadomosc) / strzaly
