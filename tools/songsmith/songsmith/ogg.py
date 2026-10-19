"""OGG Vorbis encoding with byte-for-byte determinism.

libsndfile picks a random Ogg stream serial number, so two encodes of the same audio
differ. We rewrite every page's serial to a constant and recompute its CRC.
"""

from __future__ import annotations

import io

import numpy as np
import soundfile as sf
from numba import njit

from . import SAMPLE_RATE

SERIAL = 0x44495344  # "DISD"


@njit(cache=True)
def _crc_table() -> np.ndarray:
    table = np.zeros(256, dtype=np.uint32)
    for i in range(256):
        r = np.uint32(i) << np.uint32(24)
        for _ in range(8):
            if r & np.uint32(0x80000000):
                r = (r << np.uint32(1)) ^ np.uint32(0x04C11DB7)
            else:
                r = r << np.uint32(1)
        table[i] = r & np.uint32(0xFFFFFFFF)
    return table


@njit(cache=True)
def _ogg_crc(data: np.ndarray, table: np.ndarray) -> np.uint32:
    crc = np.uint32(0)
    for b in data:
        crc = ((crc << np.uint32(8)) & np.uint32(0xFFFFFFFF)) ^ table[((crc >> np.uint32(24)) ^ np.uint32(b)) & np.uint32(0xFF)]
    return crc


def normalize_serial(data: bytes, serial: int = SERIAL) -> bytes:
    buf = bytearray(data)
    table = _crc_table()
    pos = 0
    while pos + 27 <= len(buf):
        if buf[pos : pos + 4] != b"OggS":
            raise ValueError(f"Bad Ogg page at {pos}")
        nseg = buf[pos + 26]
        body = sum(buf[pos + 27 : pos + 27 + nseg])
        end = pos + 27 + nseg + body
        buf[pos + 14 : pos + 18] = serial.to_bytes(4, "little")
        buf[pos + 22 : pos + 26] = b"\0\0\0\0"
        crc = int(_ogg_crc(np.frombuffer(bytes(buf[pos:end]), dtype=np.uint8), table))
        buf[pos + 22 : pos + 26] = crc.to_bytes(4, "little")
        pos = end
    return bytes(buf)


def encode(audio: np.ndarray, quality: float = 0.62, sample_rate: int = SAMPLE_RATE) -> bytes:
    """``audio``: shape (channels, n) or (n,). ``quality`` is libsndfile's
    compression_level (0 = best/largest … 1 = smallest)."""
    data = np.asarray(audio, dtype=np.float32)
    if data.ndim == 2:
        data = data.T
    data = np.clip(data, -1.0, 1.0)
    channels = 1 if data.ndim == 1 else data.shape[1]
    out = io.BytesIO()
    # libsndfile's Vorbis encoder crashes on very large single writes: feed it in blocks.
    with sf.SoundFile(out, "w", sample_rate, channels, subtype="VORBIS", format="OGG", compression_level=quality) as handle:
        for start in range(0, data.shape[0], 1 << 16):
            handle.write(data[start : start + (1 << 16)])
    return normalize_serial(out.getvalue())


def decode(data: bytes) -> tuple[np.ndarray, int]:
    audio, sr = sf.read(io.BytesIO(data), dtype="float64", always_2d=True)
    return audio.T, sr
