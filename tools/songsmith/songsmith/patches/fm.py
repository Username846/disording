"""Phase-modulation (DX-style) FM synthesis with 2–6 operators."""

from __future__ import annotations

import math

import numpy as np

from .. import dsp
from ..dsp import SR
from . import register


def fm(
    freq: float,
    dur: float,
    vel: float,
    rng: np.random.Generator,
    *,
    tail: float = 0.8,
    ops: list[dict] = (),
    algo: str = "stack",
    vel_index: float = 0.6,
) -> np.ndarray:
    """``ops``: list of {ratio, index (modulators) or level (carriers), env: [a,d,s,r], detune}.

    ``algo``: ``stack`` (op1 → op0, op2 → op1 …; op0 is the carrier), ``pairs``
    (op1→op0 + op3→op2 + …; even ops are carriers), ``parallel`` (all carriers).
    """
    gate = dsp.samples(dur)
    n = gate + dsp.samples(tail)
    t = np.arange(n) / SR

    def osc(op: dict, mod: np.ndarray | None) -> np.ndarray:
        f = freq * op.get("ratio", 1.0) + op.get("detune", 0.0)
        a, d, s, r = op.get("env", (0.005, 0.5, 0.5, 0.3))
        env = dsp.adsr(n, a, d, s, r, gate)
        phase = 2 * math.pi * f * t + rng.uniform(0, 2 * math.pi)
        if mod is not None:
            phase = phase + mod
        return np.sin(phase) * env

    def amount(op: dict) -> float:
        return op.get("index", 1.0) * (1 - vel_index + vel_index * vel)

    out = np.zeros(n)
    if algo == "stack":
        mod = None
        for op in reversed(ops[1:]):
            mod = amount(op) * osc(op, mod)
        out = ops[0].get("level", 1.0) * osc(ops[0], mod)
    elif algo == "pairs":
        for i in range(0, len(ops), 2):
            mod = amount(ops[i + 1]) * osc(ops[i + 1], None) if i + 1 < len(ops) else None
            out += ops[i].get("level", 1.0) * osc(ops[i], mod)
    else:
        for op in ops:
            out += op.get("level", 1.0) * osc(op, None)
    out *= vel
    return dsp.fade_tail(out, 0.02)


register(
    "fm.epiano",
    fm,
    octave=4,
    tail=1.2,
    algo="pairs",
    ops=[
        {"ratio": 1.0, "level": 1.0, "env": [0.002, 1.8, 0.0, 0.5]},
        {"ratio": 1.0, "index": 1.6, "env": [0.002, 1.2, 0.1, 0.4]},
        {"ratio": 1.0, "level": 0.35, "detune": 0.6, "env": [0.002, 0.9, 0.0, 0.3]},
        {"ratio": 14.0, "index": 0.9, "env": [0.001, 0.12, 0.0, 0.1]},
    ],
)
register(
    "fm.bell",
    fm,
    octave=5,
    tail=2.0,
    algo="stack",
    ops=[
        {"ratio": 1.0, "level": 1.0, "env": [0.001, 2.5, 0.0, 1.5]},
        {"ratio": 3.5, "index": 2.0, "env": [0.001, 1.5, 0.0, 1.0]},
    ],
)
register(
    "fm.brass",
    fm,
    octave=4,
    tail=0.25,
    algo="stack",
    ops=[
        {"ratio": 1.0, "level": 1.0, "env": [0.04, 0.2, 0.8, 0.15]},
        {"ratio": 1.0, "index": 2.2, "env": [0.06, 0.3, 0.6, 0.15]},
    ],
)
