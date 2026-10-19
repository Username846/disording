"""Songsmith: Disording's offline music, singing-voice and SFX renderer.

Everything the game hears is rendered here ahead of time into small per-day bundles
(see PLAN.md §6). Rendering is deterministic: the same spec always produces the same
bytes.
"""

SONGSMITH_VERSION = "1.0.0"
SAMPLE_RATE = 44100
