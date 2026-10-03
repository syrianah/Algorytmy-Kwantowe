"""Funkcje wspólne dla sprawdz_szum.py i uruchom_ibm.py."""

from pathlib import Path

from qiskit import qasm3

KATALOG = Path(__file__).resolve().parent
TELEPORTACJA = ["teleportacja", "teleportacja_odroczona", "kontrola"]
SUPERDENSE = ["superdense_00", "superdense_01", "superdense_10", "superdense_11"]
CHSH = ["chsh_00", "chsh_01", "chsh_10", "chsh_11"]
QFT = [f"qft_{k}" for k in range(8)]
OBWODY = TELEPORTACJA + SUPERDENSE + CHSH + QFT


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
    if nazwa.startswith("chsh_"):
        return podsumuj_chsh(nazwa, dane, strzaly)
    if nazwa.startswith("qft_"):
        return podsumuj_qft(nazwa, dane, strzaly)
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


def podsumuj_chsh(nazwa, dane, strzaly):
    """Zwraca odsetek wygranych rund gry CHSH.

    Pytania są zapisane w nazwie obwodu: chsh_10 to x = 1, y = 0. Runda jest
    wygrana, gdy a XOR b = x AND y.
    """
    x, y = (int(c) for c in nazwa.removeprefix("chsh_"))
    wygrane = sum(
        (int(a) ^ int(b)) == (x & y)
        for a, b in zip(dane.a.get_bitstrings(), dane.b.get_bitstrings())
    )
    return wygrane / strzaly


def wartosc_s(sukcesy):
    """Wartość S nierówności CHSH ze średniej wygranych w czterech obwodach.

    Dla każdej pary pytań korelacja to E = 2 * wygrane - 1, z przeciwnym znakiem
    dla x = y = 1. S = E00 + E01 + E10 - E11 = 8 * średnia_wygranych - 4.
    Klasycznie S <= 2, mechanika kwantowa pozwala na S = 2 sqrt(2) = 2,83.
    """
    return 8 * sum(sukcesy) / len(sukcesy) - 4


def odczyty_rejestru(dane):
    """Zwraca listę liczb odczytanych z rejestru wynik, bit k to kubit r[k]."""
    return [int(bity, 2) for bity in dane.wynik.get_bitstrings()]


def podsumuj_qft(nazwa, dane, strzaly):
    """Zwraca odsetek przebiegów, w których QFT odwrotna oddała zapisaną liczbę.

    Liczba jest w nazwie obwodu: qft_5 zapisuje w fazach 5. Zgadując jedną
    z ośmiu liczb, trafiałoby się w 12,5% przebiegów.
    """
    k = int(nazwa.removeprefix("qft_"))
    return odczyty_rejestru(dane).count(k) / strzaly
