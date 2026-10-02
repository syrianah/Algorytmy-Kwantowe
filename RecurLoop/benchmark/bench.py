"""Benchmark symulatora wektora stanu w Pythonie.

Dwie implementacje:
  pure   - ten sam algorytm co quantum.rl i bench.rs, czysty Python
  numpy  - wektoryzacja NumPy: stan jako tensor (2, 2, ..., 2), bramka
           jako tensordot po osi kubitu

Użycie:
  python3 bench.py (pure|numpy) teleport N
  python3 bench.py (pure|numpy) layers QUBITS DEPTH
"""

import math
import random
import sys
import time


# ---------------------------------------------------------------------------
# Czysty Python
# ---------------------------------------------------------------------------

class PureState:
    def __init__(self):
        self.n = 0
        self.size = 1
        self.re = [1.0]
        self.im = [0.0]
        self.theta = []
        self.phi = []

    def alloc(self):
        self.re.extend([0.0] * self.size)
        self.im.extend([0.0] * self.size)
        self.size *= 2
        self.theta.append(0.0)
        self.phi.append(0.0)
        self.n += 1
        return self.n - 1

    def apply(self, c1, c2, t, u):
        ar, ai, br, bi, cr, ci, dr, di = u
        mt = 1 << t
        m1 = 1 << c1 if c1 >= 0 else 0
        m2 = 1 << c2 if c2 >= 0 else 0
        re, im = self.re, self.im
        for i in range(self.size):
            if i & mt or (m1 and not i & m1) or (m2 and not i & m2):
                continue
            j = i + mt
            xr, xi, yr, yi = re[i], im[i], re[j], im[j]
            re[i] = ar * xr - ai * xi + br * yr - bi * yi
            im[i] = ar * xi + ai * xr + br * yi + bi * yr
            re[j] = cr * xr - ci * xi + dr * yr - di * yi
            im[j] = cr * xi + ci * xr + dr * yi + di * yr

    def h(self, t):
        k = 1.0 / math.sqrt(2.0)
        self.apply(-1, -1, t, (k, 0.0, k, 0.0, k, 0.0, -k, 0.0))

    def x(self, c1, t):
        self.apply(c1, -1, t, (0.0, 0.0, 1.0, 0.0, 1.0, 0.0, 0.0, 0.0))

    def z(self, t):
        self.apply(-1, -1, t, (1.0, 0.0, 0.0, 0.0, 0.0, 0.0, -1.0, 0.0))

    def phase(self, t, a):
        self.apply(-1, -1, t, (1.0, 0.0, 0.0, 0.0, 0.0, 0.0, math.cos(a), math.sin(a)))

    def ry(self, t, a):
        c, s = math.cos(a / 2.0), math.sin(a / 2.0)
        self.apply(-1, -1, t, (c, 0.0, -s, 0.0, s, 0.0, c, 0.0))

    def prob_one(self, t):
        m = 1 << t
        re, im = self.re, self.im
        return sum(re[i] * re[i] + im[i] * im[i] for i in range(self.size) if i & m)

    def measure(self, t, rng):
        p1 = self.prob_one(t)
        outcome = 1 if rng.random() < p1 else 0
        p = p1 if outcome else 1.0 - p1
        norm = 1.0 / math.sqrt(p)
        m = 1 << t
        for i in range(self.size):
            if (1 if i & m else 0) == outcome:
                self.re[i] *= norm
                self.im[i] *= norm
            else:
                self.re[i] = 0.0
                self.im[i] = 0.0
        return outcome

    def amplitude(self, i):
        return self.re[i], self.im[i]

    def norm(self):
        return sum(r * r + i * i for r, i in zip(self.re, self.im))


# ---------------------------------------------------------------------------
# NumPy
# ---------------------------------------------------------------------------

class NumpyState:
    def __init__(self):
        import numpy as np
        self.np = np
        self.n = 0
        # Oś k tensora to kubit n-1-k, więc kubit q to bit q indeksu płaskiego
        self.psi = np.ones((), dtype=np.complex128)
        self.theta = []
        self.phi = []

    def axis(self, q):
        return self.n - 1 - q

    def alloc(self):
        np = self.np
        self.psi = np.multiply.outer(np.array([1.0, 0.0], dtype=np.complex128), self.psi)
        self.theta.append(0.0)
        self.phi.append(0.0)
        self.n += 1
        return self.n - 1

    def gate(self, c, t, u):
        np = self.np
        u = np.asarray(u, dtype=np.complex128)
        ax = self.axis(t)
        if c < 0:
            out = np.tensordot(u, self.psi, axes=([1], [ax]))
            self.psi = np.moveaxis(out, 0, ax)
            return
        cax = self.axis(c)
        index = [slice(None)] * self.n
        index[cax] = 1
        sub = self.psi[tuple(index)]
        sub_ax = ax - 1 if ax > cax else ax
        out = np.moveaxis(np.tensordot(u, sub, axes=([1], [sub_ax])), 0, sub_ax)
        self.psi[tuple(index)] = out

    def h(self, t):
        k = 1.0 / math.sqrt(2.0)
        self.gate(-1, t, [[k, k], [k, -k]])

    def x(self, c1, t):
        self.gate(c1, t, [[0, 1], [1, 0]])

    def z(self, t):
        self.gate(-1, t, [[1, 0], [0, -1]])

    def phase(self, t, a):
        self.gate(-1, t, [[1, 0], [0, complex(math.cos(a), math.sin(a))]])

    def ry(self, t, a):
        c, s = math.cos(a / 2.0), math.sin(a / 2.0)
        self.gate(-1, t, [[c, -s], [s, c]])

    def prob_one(self, t):
        np = self.np
        index = [slice(None)] * self.n
        index[self.axis(t)] = 1
        return float(np.sum(np.abs(self.psi[tuple(index)]) ** 2))

    def measure(self, t, rng):
        p1 = self.prob_one(t)
        outcome = 1 if rng.random() < p1 else 0
        p = p1 if outcome else 1.0 - p1
        keep = [slice(None)] * self.n
        drop = [slice(None)] * self.n
        keep[self.axis(t)] = outcome
        drop[self.axis(t)] = 1 - outcome
        self.psi[tuple(keep)] /= math.sqrt(p)
        self.psi[tuple(drop)] = 0.0
        return outcome

    def amplitude(self, i):
        a = self.psi.reshape(-1)[i]
        return a.real, a.imag

    def norm(self):
        np = self.np
        return float(np.sum(np.abs(self.psi) ** 2))


# ---------------------------------------------------------------------------
# Wspólne testy
# ---------------------------------------------------------------------------

def prepare_random(s, t, rng):
    theta = math.acos(1.0 - 2.0 * rng.random())
    phi = 2.0 * math.pi * rng.random()
    s.ry(t, theta)
    s.phase(t, phi)
    s.theta[t] = theta
    s.phi[t] = phi


def fidelity(s, t, r):
    theta, phi = s.theta[r], s.phi[r]
    s.phase(t, -phi)
    s.ry(t, -theta)
    f = 1.0 - s.prob_one(t)
    s.ry(t, theta)
    s.phase(t, phi)
    return f


def teleport(make, rng):
    s = make()
    psi = s.alloc()
    alice = s.alloc()
    bob = s.alloc()
    prepare_random(s, psi, rng)
    s.h(alice)
    s.x(alice, bob)
    s.x(psi, alice)
    s.h(psi)
    m1 = s.measure(psi, rng)
    m2 = s.measure(alice, rng)
    if m2 == 1:
        s.x(-1, bob)
    if m1 == 1:
        s.z(bob)
    f = fidelity(s, bob, psi)
    if abs(1.0 - f) >= 1e-9:
        raise RuntimeError(f"teleportacja nieudana, wierność {f}")
    return m1 * 2 + m2


def layers(make, n, depth):
    s = make()
    for _ in range(n):
        s.alloc()
    for _ in range(depth):
        for q in range(n):
            s.h(q)
            s.ry(q, 0.1 + 0.05 * q)
        for q in range(n - 1):
            s.x(q, q + 1)
    ar, ai = s.amplitude(2 ** n - 1)
    return s.norm(), s.prob_one(0), ar, ai


def main():
    impl, test = sys.argv[1], sys.argv[2]
    make = PureState if impl == "pure" else NumpyState
    start = time.perf_counter()
    if test == "teleport":
        n = int(sys.argv[3])
        rng = random.Random(12345)
        counts = [0, 0, 0, 0]
        for _ in range(n):
            counts[teleport(make, rng)] += 1
        ms = (time.perf_counter() - start) * 1000.0
        print(f"teleport n={n} wyniki={counts} czas_ms={ms:.1f}")
    else:
        q, d = int(sys.argv[3]), int(sys.argv[4])
        norm, p0, ar, ai = layers(make, q, d)
        ms = (time.perf_counter() - start) * 1000.0
        print(f"layers q={q} d={d} norma={norm:.12f} p0={p0:.12f} amp=({ar:.12e}, {ai:.12e}) czas_ms={ms:.1f}")


if __name__ == "__main__":
    main()
