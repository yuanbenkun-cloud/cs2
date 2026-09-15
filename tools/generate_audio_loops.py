"""Generate original, seamless-ish 24 second music and ambience loops for 洞见.

The synthesis is intentionally restrained so dialogue remains intelligible.  No sampled
or third-party musical material is used; all tones/noise are generated numerically.
"""

from pathlib import Path
import json
import wave

import numpy as np


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "audio" / "generated"
SR = 22050
DURATION = 24.0
N = int(SR * DURATION)
T = np.arange(N, dtype=np.float64) / SR


def loop_frequency(freq: float) -> float:
    return round(freq * DURATION) / DURATION


def tone(freq: float, amp: float = 1.0, phase: float = 0.0) -> np.ndarray:
    return amp * np.sin(2.0 * np.pi * loop_frequency(freq) * T + phase)


def periodic_noise(seed: int, low_hz: float, high_hz: float, partials: int = 70) -> np.ndarray:
    rng = np.random.RandomState(seed)
    freqs = np.geomspace(max(low_hz, 0.2), high_hz, partials)
    result = np.zeros(N, dtype=np.float64)
    for freq in freqs:
        phase = rng.uniform(0.0, np.pi * 2.0)
        result += np.sin(2.0 * np.pi * loop_frequency(float(freq)) * T + phase) / np.sqrt(freq)
    peak = np.max(np.abs(result))
    return result / peak if peak > 0 else result


def add_pluck(track: np.ndarray, freq: float, start: float, amp: float, decay: float = 0.75) -> None:
    begin = int(start * SR)
    length = min(int(2.0 * SR), N - begin)
    if length <= 0:
        return
    x = np.arange(length, dtype=np.float64) / SR
    env = np.minimum(x / 0.012, 1.0) * np.exp(-x / decay)
    f = loop_frequency(freq)
    sound = np.sin(2 * np.pi * f * x) + 0.34 * np.sin(2 * np.pi * f * 2.01 * x)
    track[begin:begin + length] += sound * env * amp


def add_thump(track: np.ndarray, start: float, amp: float, decay: float = 0.24) -> None:
    begin = int(start * SR)
    length = min(int(0.8 * SR), N - begin)
    if length <= 0:
        return
    x = np.arange(length, dtype=np.float64) / SR
    freq = 62.0 - 24.0 * np.minimum(x / 0.25, 1.0)
    phase = 2 * np.pi * np.cumsum(freq) / SR
    track[begin:begin + length] += np.sin(phase) * np.exp(-x / decay) * amp


def add_chirp(track: np.ndarray, start: float, amp: float, base: float) -> None:
    begin = int(start * SR)
    length = min(int(0.32 * SR), N - begin)
    x = np.arange(length, dtype=np.float64) / SR
    freq = base + 1150.0 * np.sin(np.pi * np.minimum(x / 0.28, 1.0))
    phase = 2 * np.pi * np.cumsum(freq) / SR
    env = np.sin(np.pi * np.minimum(x / 0.32, 1.0)) ** 2
    track[begin:begin + length] += np.sin(phase) * env * amp


def stereo(left: np.ndarray, right: np.ndarray = None) -> np.ndarray:
    if right is None:
        right = left
    return np.stack([left, right], axis=1)


def master(track: np.ndarray, target: float = 0.82) -> np.ndarray:
    track = np.tanh(track * 0.92)
    peak = float(np.max(np.abs(track)))
    if peak > 0:
        track = track * (target / peak)
    # Tiny boundary fade prevents a click even if a later edit breaks periodicity.
    fade = int(0.018 * SR)
    ramp = np.linspace(0.0, 1.0, fade)
    track[:fade] *= ramp[:, None]
    track[-fade:] *= ramp[::-1, None]
    return track


def write_wav(name: str, track: np.ndarray) -> None:
    pcm = np.clip(master(track), -1.0, 1.0)
    pcm = (pcm * 32767.0).astype("<i2")
    with wave.open(str(OUT / name), "wb") as wav:
        wav.setnchannels(2)
        wav.setsampwidth(2)
        wav.setframerate(SR)
        wav.writeframes(pcm.tobytes())


def music_night() -> np.ndarray:
    left = tone(73.42, 0.22) + tone(110.0, 0.09, 0.7) + periodic_noise(1, 30, 220, 24) * 0.025
    right = tone(73.42, 0.20, 0.05) + tone(146.83, 0.07, 1.0) + periodic_noise(2, 30, 210, 24) * 0.025
    notes = [293.66, 349.23, 440.0, 523.25, 440.0, 349.23]
    for i, at in enumerate(np.arange(1.0, 23.0, 2.0)):
        add_pluck(left if i % 2 == 0 else right, notes[i % len(notes)], float(at), 0.19, 1.15)
    return stereo(left, right)


def music_forge() -> np.ndarray:
    left = tone(73.42, 0.26) + tone(110.0, 0.12) + periodic_noise(3, 55, 420, 36) * 0.035
    right = tone(73.42, 0.24, 0.06) + tone(146.83, 0.09, 0.4) + periodic_noise(4, 60, 460, 36) * 0.035
    for beat in np.arange(0.75, 23.6, 0.75):
        add_thump(left, float(beat), 0.14 if int(beat / 0.75) % 4 else 0.24)
        add_thump(right, float(beat) + 0.018, 0.13 if int(beat / 0.75) % 4 else 0.22)
    for i, at in enumerate(np.arange(2.25, 23.0, 3.0)):
        add_pluck(right if i % 2 else left, [293.66, 440.0, 587.33][i % 3], float(at), 0.13, 0.42)
    return stereo(left, right)


def music_old_town() -> np.ndarray:
    left = tone(98.0, 0.15) + tone(146.83, 0.08) + periodic_noise(5, 70, 900, 55) * 0.018
    right = tone(98.0, 0.14, 0.08) + tone(196.0, 0.06, 0.7) + periodic_noise(6, 80, 950, 55) * 0.018
    notes = [392.0, 440.0, 493.88, 587.33, 659.25, 587.33, 493.88, 440.0]
    for i, at in enumerate(np.arange(0.8, 23.0, 1.6)):
        add_pluck(left if i % 3 else right, notes[i % len(notes)], float(at), 0.15, 0.9)
    return stereo(left, right)


def music_shelter() -> np.ndarray:
    left = tone(41.20, 0.31) + tone(61.74, 0.12, 0.8) + periodic_noise(7, 18, 130, 34) * 0.06
    right = tone(41.20, 0.29, 0.03) + tone(82.41, 0.08, 1.1) + periodic_noise(8, 18, 140, 34) * 0.06
    for at in np.arange(1.2, 23.0, 2.18):
        add_thump(left, float(at), 0.24, 0.30)
        add_thump(right, float(at) + 0.19, 0.15, 0.24)
    return stereo(left, right)


def music_dawn() -> np.ndarray:
    left = tone(130.81, 0.12) + tone(196.0, 0.06) + periodic_noise(9, 100, 1200, 52) * 0.012
    right = tone(130.81, 0.11, 0.04) + tone(261.63, 0.05, 0.5) + periodic_noise(10, 100, 1300, 52) * 0.012
    notes = [261.63, 293.66, 329.63, 392.0, 440.0, 523.25]
    for i, at in enumerate(np.arange(0.7, 23.0, 1.2)):
        add_pluck(left if i % 2 == 0 else right, notes[i % len(notes)], float(at), 0.16, 1.15)
    return stereo(left, right)


def ambience_rain(seed: int, rumble: float) -> np.ndarray:
    rain_l = periodic_noise(seed, 500, 8500, 180) * 0.25 + periodic_noise(seed + 1, 25, 220, 42) * rumble
    rain_r = periodic_noise(seed + 2, 520, 9000, 180) * 0.25 + periodic_noise(seed + 3, 28, 240, 42) * rumble
    return stereo(rain_l, rain_r)


def ambience_forge() -> np.ndarray:
    rng = np.random.RandomState(22)
    left = periodic_noise(23, 35, 320, 50) * 0.16 + tone(55.0, 0.05)
    right = periodic_noise(24, 38, 350, 50) * 0.16 + tone(55.0, 0.045, 0.1)
    for at in np.arange(0.4, 23.5, 0.7):
        if rng.rand() < 0.62:
            begin = int(at * SR)
            length = min(int(0.08 * SR), N - begin)
            crackle = rng.randn(length) * np.exp(-np.arange(length) / (SR * 0.018)) * 0.20
            (left if rng.rand() < 0.5 else right)[begin:begin + length] += crackle
    return stereo(left, right)


def ambience_shelter() -> np.ndarray:
    left = periodic_noise(30, 16, 180, 55) * 0.22
    right = periodic_noise(31, 16, 190, 55) * 0.22
    siren_phase = 2 * np.pi * np.cumsum(335.0 + 85.0 * np.sin(2 * np.pi * T / DURATION * 2.0)) / SR
    siren = np.sin(siren_phase) * (0.045 + 0.02 * np.sin(2 * np.pi * T / DURATION))
    return stereo(left + siren, right + np.roll(siren, 190))


def ambience_dawn() -> np.ndarray:
    left = periodic_noise(40, 90, 1800, 90) * 0.07
    right = periodic_noise(41, 95, 1900, 90) * 0.07
    for i, at in enumerate([1.2, 3.0, 6.8, 9.1, 13.4, 16.2, 19.8, 22.1]):
        add_chirp(left if i % 2 == 0 else right, at, 0.12, 1450.0 + (i % 3) * 140.0)
    return stereo(left, right)


def add_fire_crackle(track: np.ndarray, seed: int, density: int = 90) -> None:
    """Add small, dry transient pops without using sampled material."""
    rng = np.random.RandomState(seed)
    for at in rng.uniform(0.12, DURATION - 0.18, density):
        begin = int(at * SR)
        length = min(int(rng.uniform(0.012, 0.065) * SR), N - begin)
        if length <= 0:
            continue
        x = np.arange(length, dtype=np.float64) / SR
        burst = rng.randn(length) * np.exp(-x / rng.uniform(0.006, 0.022))
        track[begin:begin + length] += burst * rng.uniform(0.035, 0.14)


def add_vendor_call(track: np.ndarray, start: float, duration: float, base: float, amp: float) -> None:
    """Formant-like distant human call, intentionally indistinct rather than spoken TTS."""
    begin = int(start * SR)
    length = min(int(duration * SR), N - begin)
    if length <= 0:
        return
    x = np.arange(length, dtype=np.float64) / SR
    glide = base * (1.0 + 0.10 * np.sin(np.pi * x / duration))
    phase = 2.0 * np.pi * np.cumsum(glide) / SR
    voice = np.zeros(length, dtype=np.float64)
    # A soft harmonic stack plus two slow "mouth shape" envelopes reads as a far-off hawker.
    for harmonic in range(1, 9):
        voice += np.sin(phase * harmonic) / (harmonic ** 1.22)
    mouth = 0.58 + 0.25 * np.sin(2.0 * np.pi * x / duration * 1.5 + 0.4)
    tremolo = 0.88 + 0.12 * np.sin(2.0 * np.pi * 5.1 * x)
    edge = np.minimum(x / 0.10, 1.0) * np.minimum((duration - x) / 0.20, 1.0)
    track[begin:begin + length] += voice * mouth * tremolo * np.clip(edge, 0.0, 1.0) * amp


def add_distant_boom(track: np.ndarray, start: float, amp: float) -> None:
    begin = int(start * SR)
    length = min(int(2.2 * SR), N - begin)
    if length <= 0:
        return
    x = np.arange(length, dtype=np.float64) / SR
    rng = np.random.RandomState(int(start * 1000) + 404)
    low = np.sin(2.0 * np.pi * (43.0 * x - 8.0 * x * x))
    debris = rng.randn(length) * np.exp(-x / 0.34)
    tail = np.sin(2.0 * np.pi * 27.0 * x) * np.exp(-x / 1.18)
    track[begin:begin + length] += (low * np.exp(-x / 0.42) + debris * 0.24 + tail * 0.38) * amp


def transition_kiln() -> np.ndarray:
    left = periodic_noise(62, 28, 510, 80) * 0.19 + tone(48.0, 0.055)
    right = periodic_noise(63, 31, 560, 80) * 0.18 + tone(48.0, 0.05, 0.13)
    # The two channels crackle independently so the kiln feels close and wide.
    add_fire_crackle(left, 64, 118)
    add_fire_crackle(right, 65, 105)
    for at in [4.8, 11.7, 18.9]:
        add_thump(left, at, 0.11, 0.30)
        add_thump(right, at + 0.08, 0.08, 0.28)
    return stereo(left, right)


def transition_cloth_market() -> np.ndarray:
    left = periodic_noise(70, 75, 1450, 95) * 0.055 + periodic_noise(71, 25, 180, 36) * 0.035
    right = periodic_noise(72, 80, 1550, 95) * 0.055 + periodic_noise(73, 28, 195, 36) * 0.035
    # Alternating calls suggest several cloth sellers rather than one voice pasted in the centre.
    for at, duration, base, side in [
        (1.1, 1.55, 126.0, 0), (4.4, 1.15, 154.0, 1), (7.6, 1.75, 118.0, 0),
        (11.4, 1.30, 166.0, 1), (15.2, 1.65, 132.0, 1), (19.1, 1.25, 148.0, 0),
        (22.0, 1.35, 121.0, 1),
    ]:
        add_vendor_call(left if side == 0 else right, at, duration, base, 0.048)
    # Short filtered swishes evoke bolts of cloth being shaken open.
    rng = np.random.RandomState(74)
    for at in [2.8, 6.2, 9.7, 13.3, 17.5, 21.0]:
        begin = int(at * SR)
        length = min(int(0.42 * SR), N - begin)
        x = np.arange(length, dtype=np.float64) / SR
        swish = rng.randn(length) * np.sin(np.pi * x / 0.42) ** 2 * 0.055
        (right if int(at * 10) % 2 else left)[begin:begin + length] += swish
    return stereo(left, right)


def transition_air_raid() -> np.ndarray:
    left = periodic_noise(80, 15, 210, 60) * 0.12
    right = periodic_noise(81, 17, 230, 60) * 0.12
    sweep = 0.5 - 0.5 * np.cos(2.0 * np.pi * T / 6.0)
    frequency = 285.0 + 235.0 * sweep
    phase = 2.0 * np.pi * np.cumsum(frequency) / SR
    siren = (np.sin(phase) + 0.24 * np.sin(phase * 2.0)) * (0.11 + 0.025 * np.sin(2 * np.pi * T / 3.0))
    left += siren
    right += np.roll(siren, int(0.035 * SR)) * 0.92
    for index, at in enumerate([2.7, 6.4, 9.8, 13.1, 16.0, 19.5, 22.4]):
        add_distant_boom(left if index % 2 == 0 else right, at, 0.22 if index < 2 else 0.30)
        add_distant_boom(right if index % 2 == 0 else left, at + 0.12, 0.11)
    return stereo(left, right)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    tracks = {
        "music-01-night.wav": music_night(),
        "music-02-forge.wav": music_forge(),
        "music-03-old-town.wav": music_old_town(),
        "music-04-shelter.wav": music_shelter(),
        "music-05-dawn.wav": music_dawn(),
        "ambient-01-rain.wav": ambience_rain(12, 0.055),
        "ambient-02-forge.wav": ambience_forge(),
        "ambient-03-rain.wav": ambience_rain(18, 0.085),
        "ambient-04-shelter.wav": ambience_shelter(),
        "ambient-05-dawn.wav": ambience_dawn(),
        "transition-02-kiln.wav": transition_kiln(),
        "transition-03-cloth-market.wav": transition_cloth_market(),
        "transition-04-air-raid.wav": transition_air_raid(),
    }
    for filename, track in tracks.items():
        write_wav(filename, track)
        print("[AUDIO]", filename)
    metadata = {
        "generator": "tools/generate_audio_loops.py",
        "created_at": "2026-09-13",
        "license": "project-generated original media",
        "sample_rate": SR,
        "channels": 2,
        "duration_seconds": DURATION,
        "source_material": "none; numeric synthesis only",
        "tracks": list(tracks),
    }
    (OUT / "audio-manifest.json").write_text(json.dumps(metadata, ensure_ascii=False, indent=2), encoding="utf-8")
    print("[RESULT] generated %d original loops" % len(tracks))


if __name__ == "__main__":
    main()
