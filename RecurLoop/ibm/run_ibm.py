"""Runs the circuits on a real IBM quantum computer.

By default it only connects to the account, picks a processor and compiles
the circuits without submitting anything. A job is queued only with the
--submit flag, because time on real hardware is limited.

The API key is read from the IBM_QUANTUM_TOKEN environment variable and the
optional instance from IBM_QUANTUM_INSTANCE. Without these variables an
account saved earlier with this Python snippet is used:
  from qiskit_ibm_runtime import QiskitRuntimeService
  QiskitRuntimeService.save_account(
      channel="ibm_quantum_platform", token="YOUR_API_KEY", set_as_default=True)

Usage, from the ibm directory, after generating the .qasm files:
  python3 run_ibm.py                          # dry run, submits nothing
  python3 run_ibm.py --submit                 # submits to the least busy processor
  python3 run_ibm.py --backend ibm_fez --submit
  python3 run_ibm.py --set superdense --submit   # superdense coding only
  python3 run_ibm.py --set chsh --submit         # CHSH game only
  python3 run_ibm.py --set qft --submit          # Fourier transform only
  python3 run_ibm.py --job ID                 # fetches the results of an earlier job
                                              # (with the same --set as when submitted)
"""

import argparse
import os
from collections import Counter

from qiskit import transpile
from qiskit_ibm_runtime import QiskitRuntimeService, SamplerV2

from common import CHSH, CIRCUITS, QFT, SUPERDENSE, TELEPORTATION, bob_reads, chsh_s, load, score

SETS = {"all": CIRCUITS, "teleportation": TELEPORTATION, "superdense": SUPERDENSE, "chsh": CHSH, "qft": QFT}


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--backend", help="processor name, by default the least busy one")
    parser.add_argument("--shots", type=int, default=4000, help="number of runs of each circuit")
    parser.add_argument("--submit", action="store_true", help="really submit the job to the IBM queue")
    parser.add_argument("--job", help="fetch the results of the job with this ID")
    parser.add_argument("--set", choices=SETS, default="all", help="which circuits to run")
    args = parser.parse_args()

    service = connect()

    names = SETS[args.set]
    if args.job:
        job = service.job(args.job)
        print(f"Job {job.job_id()} on {job.backend().name}, status: {job.status()}")
        show_results(job.result(), names, args.shots)
        return

    circuits = [load(name) for name in names]
    if args.backend:
        backend = service.backend(args.backend)
    else:
        backend = service.least_busy(operational=True, simulator=False, dynamic_circuits=True)
    print(f"Processor: {backend.name}, {backend.num_qubits} qubits, pending jobs: {backend.status().pending_jobs}")

    compiled = [transpile(c, backend, optimization_level=3, seed_transpiler=11) for c in circuits]
    for c in compiled:
        gates_2q = sum(n for g, n in c.count_ops().items() if g in ("ecr", "cz", "cx"))
        print(f"  {c.name:24s} 2q gates: {gates_2q:3d}, depth: {c.depth():3d}")

    if not args.submit:
        print("\nThis was only a dry run. Add --submit to queue the job.")
        return

    job = SamplerV2(mode=backend).run(compiled, shots=args.shots)
    print(f"\nSubmitted job {job.job_id()}. Waiting for the result, which may take a while.")
    print(f"The results can also be fetched later: python3 run_ibm.py --job {job.job_id()}")
    show_results(job.result(), names, args.shots)


def connect():
    """Connects to IBM Quantum with the key from the environment or a saved account."""
    token = os.environ.get("IBM_QUANTUM_TOKEN")
    if token:
        return QiskitRuntimeService(
            channel="ibm_quantum_platform",
            token=token,
            instance=os.environ.get("IBM_QUANTUM_INSTANCE") or None,
        )
    return QiskitRuntimeService()


def show_results(result, names, shots):
    print()
    fractions = {}
    for name, r in zip(names, result):
        fractions[name] = score(name, r.data, shots)
        line = f"  {name:24s} success: {fractions[name] * 100:5.1f}%"
        if name.startswith("superdense_"):
            reads = Counter(bob_reads(r.data))
            line += "   Bob read: " + ", ".join(f"{k} {reads[k]}" for k in ("00", "01", "10", "11"))
        print(line)
    if all(n in fractions for n in CHSH):
        print(f"\n  CHSH: S = {chsh_s([fractions[n] for n in CHSH]):.3f}"
              " (classically at most 2, ideally 2.828)")
    print("\nOn ideal hardware teleportation, superdense coding and the QFT give 100%, the CHSH game 85.4%.")
    print("A random result is 50% for teleportation, 25% for superdense coding, 50% for CHSH")
    print("and 12.5% for the QFT.")


if __name__ == "__main__":
    main()
