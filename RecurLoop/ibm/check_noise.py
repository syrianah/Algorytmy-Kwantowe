"""Runs the circuits on noise models of IBM processors, without an account or a queue.

The models come with qiskit-ibm-runtime and reproduce the gate, measurement
and decoherence errors from calibrations of real processors.

Usage, from the ibm directory, after generating the .qasm files:
  python3 check_noise.py                # all circuits, takes over 10 minutes
  python3 check_noise.py --set grover   # only Grover's search
"""

import argparse
import warnings

from qiskit import transpile
from qiskit_ibm_runtime import SamplerV2
from qiskit_ibm_runtime.fake_provider import FakeBrisbane, FakeFez, FakeTorino

from common import CHSH, SETS, chsh_s, load, score

warnings.filterwarnings("ignore")
SHOTS = 4000


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--set", choices=SETS, default="all", help="which circuits to check")
    args = parser.parse_args()

    print(f"{'processor':16s} {'circuit':24s} {'success':>8s} {'2q gates':>10s} {'depth':>10s}")
    for backend in (FakeBrisbane(), FakeTorino(), FakeFez()):
        fractions = {}
        for name in SETS[args.set]:
            circuit = load(name)
            if "if_else" in circuit.count_ops() and "if_else" not in backend.target.operation_names:
                print(f"{backend.name:16s} {name:24s}   processor does not support dynamic circuits")
                continue
            compiled = transpile(circuit, backend, optimization_level=3, seed_transpiler=11)
            result = SamplerV2(mode=backend).run([compiled], shots=SHOTS).result()[0]
            success = score(name, result.data, SHOTS)
            fractions[name] = success
            gates_2q = sum(n for g, n in compiled.count_ops().items() if g in ("ecr", "cz", "cx"))
            print(f"{backend.name:16s} {name:24s} {success * 100:7.1f}% {gates_2q:10d} {compiled.depth():10d}")
        if all(n in fractions for n in CHSH):
            print(f"{backend.name:16s} {'CHSH: S':24s} {chsh_s([fractions[n] for n in CHSH]):8.3f}")


if __name__ == "__main__":
    main()
