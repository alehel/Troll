"""Procedurally composes the game's music and sound effects.

    python3 tools/gen_audio.py          # writes assets/audio/*.ogg and *.wav

Requires numpy, scipy and soundfile. Everything is synthesised from scratch:
plucked strings (Karplus-Strong), music box bells, a breathy flute, a fiddle,
soft pads, a little percussion and a simple Schroeder reverb.
"""
import os
import sys

import numpy as np
import soundfile as sf
from scipy.signal import butter, lfilter

SR = 22050
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "audio")
rng = np.random.default_rng(1234)


def mtof(m):
    return 440.0 * 2.0 ** ((m - 69) / 12.0)


def t_axis(dur):
    return np.arange(int(dur * SR)) / SR


def env_adsr(n, a=0.01, d=0.1, s=0.7, r=0.1, sustain_time=None):
    total = n / SR
    if sustain_time is None:
        sustain_time = max(0.0, total - a - d - r)
    e = np.zeros(n)
    t = np.arange(n) / SR
    e = np.where(t < a, t / max(a, 1e-4), e)
    m = (t >= a) & (t < a + d)
    e = np.where(m, 1.0 - (1.0 - s) * (t - a) / max(d, 1e-4), e)
    m2 = (t >= a + d) & (t < a + d + sustain_time)
    e = np.where(m2, s, e)
    m3 = t >= a + d + sustain_time
    e = np.where(m3, s * np.clip(1.0 - (t - a - d - sustain_time) / max(r, 1e-4), 0, 1), e)
    return e


def lowpass(x, cutoff, order=2):
    b, a = butter(order, min(cutoff / (SR / 2), 0.99), btype="low")
    return lfilter(b, a, x)


def highpass(x, cutoff, order=2):
    b, a = butter(order, min(cutoff / (SR / 2), 0.99), btype="high")
    return lfilter(b, a, x)


def bandpass(x, lo, hi, order=2):
    b, a = butter(order, [lo / (SR / 2), min(hi / (SR / 2), 0.99)], btype="band")
    return lfilter(b, a, x)


# ---------------------------------------------------------------- instruments
def pluck(freq, dur, bright=0.5, decay=0.996):
    """Karplus-Strong plucked string, vectorised with an IIR filter."""
    n = int(dur * SR)
    period = max(2, int(round(SR / freq)))
    burst = rng.uniform(-1, 1, period)
    burst = lowpass(burst, 1500 + bright * 6000, 1)
    x = np.zeros(n)
    x[:period] = burst
    a = np.zeros(period + 2)
    a[0] = 1.0
    a[period] = -0.5 * decay
    a[period + 1] = -0.5 * decay
    y = lfilter([1.0], a, x)
    y *= env_adsr(n, 0.002, 0.05, 1.0, 0.08)
    return y * 0.6


def music_box(freq, dur, decay=1.4):
    t = t_axis(dur)
    e = np.exp(-t * (3.0 / decay)) * np.minimum(1.0, t / 0.003)
    y = np.sin(2 * np.pi * freq * t) + 0.18 * np.sin(2 * np.pi * freq * 3.0 * t) * np.exp(-t * 6)
    y += 0.1 * np.sin(2 * np.pi * freq * 5.4 * t) * np.exp(-t * 12)
    return y * e * 0.5


def flute(freq, dur, vib=5.0):
    t = t_axis(dur)
    v = 1.0 + 0.006 * np.sin(2 * np.pi * vib * t) * np.minimum(1.0, t / 0.4)
    phase = 2 * np.pi * np.cumsum(freq * v) / SR
    y = np.sin(phase) + 0.12 * np.sin(2 * phase) + 0.05 * np.sin(3 * phase)
    breath = lowpass(rng.normal(0, 1, len(t)), 3000) * 0.04
    e = env_adsr(len(t), 0.07, 0.15, 0.8, 0.18)
    return (y + breath) * e * 0.32


def fiddle(freq, dur):
    t = t_axis(dur)
    v = 1.0 + 0.008 * np.sin(2 * np.pi * 6.0 * t) * np.minimum(1.0, t / 0.15)
    phase = np.cumsum(freq * v) / SR
    saw = 2.0 * (phase - np.floor(phase + 0.5))
    y = lowpass(saw, 2600, 2)
    y = y + 0.3 * bandpass(saw, 900, 1400)
    e = env_adsr(len(t), 0.02, 0.06, 0.8, 0.05)
    return y * e * 0.28


def pad(freqs, dur, level=0.12):
    t = t_axis(dur)
    y = np.zeros(len(t))
    for f in freqs:
        for det in (-0.004, 0.004):
            ph = np.cumsum(np.full(len(t), f * (1 + det))) / SR
            y += 2.0 * (ph - np.floor(ph + 0.5))
    y = lowpass(y, 1100, 2)
    e = env_adsr(len(t), min(0.6, dur * 0.3), 0.3, 0.8, min(0.8, dur * 0.3))
    return y * e * level / max(1, len(freqs))


def accordion(freqs, dur, level=0.12):
    t = t_axis(dur)
    y = np.zeros(len(t))
    for f in freqs:
        for det in (-0.003, 0.003):
            ph = np.cumsum(np.full(len(t), f * (1 + det))) / SR
            y += np.sign(np.sin(2 * np.pi * ph)) * 0.5
    y = lowpass(y, 1800, 2)
    e = env_adsr(len(t), 0.02, 0.05, 0.85, 0.05)
    return y * e * level / max(1, len(freqs))


def kick(dur=0.25):
    t = t_axis(dur)
    f = 120 * np.exp(-t * 25) + 45
    ph = 2 * np.pi * np.cumsum(f) / SR
    return np.sin(ph) * np.exp(-t * 14) * 0.8


def clap(dur=0.15):
    t = t_axis(dur)
    n = rng.normal(0, 1, len(t))
    n = bandpass(n, 900, 3500)
    e = np.exp(-t * 30) + 0.5 * np.exp(-np.maximum(0, t - 0.012) * 30) * (t > 0.012)
    return n * e * 0.35


def noise(dur):
    return rng.normal(0, 1, int(dur * SR))


# ---------------------------------------------------------------- mixing
def place(buf, sig, start_s, gain=1.0, pan=0.0):
    i = int(start_s * SR)
    j = min(len(buf), i + len(sig))
    if j > i:
        buf[i:j] += sig[: j - i] * gain


def reverb(x, wet=0.25, room=0.82):
    combs = [1557, 1617, 1491, 1422, 1277, 1356]
    out = np.zeros(len(x))
    for d in combs:
        d = int(d * SR / 44100)
        a = np.zeros(d + 1)
        a[0] = 1.0
        a[d] = -room
        c = lfilter([1.0], a, x)
        out += lowpass(c, 5000, 1)
    out /= len(combs)
    for d, g in ((225, 0.5), (556, 0.5), (441, 0.5)):
        d = int(d * SR / 44100)
        b = np.zeros(d + 1)
        a = np.zeros(d + 1)
        b[0] = -g
        b[d] = 1.0
        a[0] = 1.0
        a[d] = -g
        out = lfilter(b, a, out)
    return x * (1 - wet) + out * wet * 1.4


def master(x, peak=0.89):
    x = x - np.mean(x)
    x = np.tanh(x * 1.2) / np.tanh(1.2)
    m = np.max(np.abs(x)) + 1e-9
    return x * (peak / m)


def loopify(buf, length_s, wet=0.25, room=0.82):
    """Render with reverb, then wrap the tail around so the loop is seamless."""
    L = int(length_s * SR)
    y = reverb(buf, wet, room)
    out = y[:L].copy()
    tail = y[L:]
    out[: len(tail)] += tail[: L]
    return out


def write_ogg(name, x):
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name)
    sf.write(path, master(x).astype(np.float32), SR, format="OGG", subtype="VORBIS")
    print("wrote", path, "%.1fs" % (len(x) / SR))


def write_wav(name, x, peak=0.8):
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name)
    x = np.asarray(x, dtype=np.float64)
    fade = min(len(x), int(0.005 * SR))
    if fade > 0:
        x[-fade:] *= np.linspace(1, 0, fade)
    m = np.max(np.abs(x)) + 1e-9
    x = x * (peak / m)
    sf.write(path, (x * 32767).astype(np.int16), SR, subtype="PCM_16")
    print("wrote", path)


# ---------------------------------------------------------------- music
CHORDS = {
    "D": [50, 57, 62, 66], "G": [43, 55, 59, 62], "A": [45, 57, 61, 64], "Bm": [47, 59, 62, 66],
    "Em": [40, 55, 59, 64], "C": [48, 55, 60, 64], "Am": [45, 57, 60, 64], "F#m": [42, 57, 61, 66],
    "Dmaj7": [50, 57, 61, 66], "Bm7": [47, 57, 62, 66], "Gmaj7": [43, 59, 62, 66], "Asus4": [45, 57, 62, 64],
    "Em7": [40, 55, 62, 64], "A7": [45, 55, 61, 64], "F#m7": [42, 57, 61, 64],
}


def day_theme():
    bpm = 100
    beat = 60.0 / bpm
    bar = beat * 3
    chords = ["D", "G", "D", "A", "D", "G", "A", "D",
              "Bm", "G", "D", "A", "Bm", "G", "Em", "A",
              "D", "G", "D", "A", "D", "G", "A", "D",
              "G", "D", "Em", "A", "G", "D", "A", "D"]
    A = [[(69, 1), (74, 1), (78, 1)], [(79, 2), (78, .5), (76, .5)], [(78, 1), (74, 1), (69, 1)], [(76, 2), (73, 1)],
         [(74, 1), (78, 1), (81, 1)], [(83, 1.5), (81, .5), (79, 1)], [(78, 1), (76, 1), (73, 1)], [(74, 3)]]
    B = [[(78, 1), (83, 1), (86, 1)], [(86, 1.5), (83, .5), (79, 1)], [(81, 2), (78, 1)], [(76, 1), (80, 1), (81, 1)],
         [(83, 1), (81, 1), (78, 1)], [(79, 1), (83, 1), (86, 1)], [(88, 1.5), (86, .5), (83, 1)], [(81, 2), (None, 1)]]
    A2 = A[:7] + [[(74, 1), (69, 1), (74, 1)]]
    C = [[(83, 1), (81, 1), (79, 1)], [(78, 1.5), (76, .5), (74, 1)], [(76, 1), (79, 1), (83, 1)], [(81, 2), (79, .5), (78, .5)],
         [(79, 1), (83, 1), (86, 1)], [(81, 1.5), (78, .5), (74, 1)], [(76, 1), (73, 1), (76, 1)], [(74, 3)]]
    melody = A + B + A2 + C
    length = bar * len(chords)
    buf = np.zeros(int((length + 4) * SR))
    for i, ch in enumerate(chords):
        t0 = i * bar
        notes = CHORDS[ch]
        place(buf, pluck(mtof(notes[0] - 12 if notes[0] > 45 else notes[0]), bar * 0.95, 0.3, 0.997), t0, 0.9)
        for b in (1, 2):
            for k, m in enumerate(notes[1:]):
                place(buf, pluck(mtof(m), beat * 1.2, 0.55, 0.994), t0 + b * beat + k * 0.012, 0.32)
        place(buf, pad([mtof(m) for m in notes[1:]], bar * 1.05, 0.09), t0, 1.0)
        tt = t0
        for m, d in melody[i]:
            if m is not None:
                place(buf, music_box(mtof(m), d * beat + 1.2), tt, 0.55)
                if 8 <= i < 16 or 24 <= i < 32:
                    place(buf, flute(mtof(m), d * beat * 0.98), tt, 0.5)
            tt += d * beat
    return loopify(buf, length, 0.28, 0.83)


def night_theme():
    bpm = 66
    beat = 60.0 / bpm
    bar = beat * 4
    chords = ["Dmaj7", "Bm7", "Gmaj7", "Asus4", "Dmaj7", "F#m7", "Gmaj7", "A",
              "Bm7", "Gmaj7", "Em7", "A7", "Dmaj7", "Gmaj7", "Em7", "D"]
    mel = [[(78, 4)], [(78, 2), (76, 2)], [(74, 4)], [(76, 4)], [(78, 2), (81, 2)], [(85, 3), (81, 1)], [(83, 4)], [(81, 4)],
           [(None, 4)], [(None, 4)], [(79, 2), (78, 2)], [(76, 3), (73, 1)], [(74, 4)], [(71, 2), (74, 2)], [(76, 2), (73, 2)], [(74, 4)]]
    length = bar * len(chords)
    buf = np.zeros(int((length + 5) * SR))
    for i, ch in enumerate(chords):
        t0 = i * bar
        notes = CHORDS[ch]
        tones = sorted(set([m + 12 for m in notes[1:]]))
        arp = [tones[0], tones[1], tones[2], tones[-1] + 5 if len(tones) < 4 else tones[3], tones[0] + 12, tones[2], tones[1], tones[0]]
        for k, m in enumerate(arp):
            place(buf, music_box(mtof(m), 2.2, 1.8), t0 + k * beat * 0.5, 0.28 if k % 2 == 0 else 0.2)
        place(buf, pad([mtof(m) for m in notes[1:]], bar * 1.1, 0.11), t0, 1.0)
        place(buf, pluck(mtof(notes[0]), bar, 0.2, 0.998), t0, 0.5)
        tt = t0
        for m, d in mel[i]:
            if m is not None:
                place(buf, flute(mtof(m), d * beat * 0.97, 4.0), tt, 0.42)
            tt += d * beat
    return loopify(buf, length, 0.4, 0.88)


def festival_theme():
    bpm = 132
    beat = 60.0 / bpm
    bar = beat * 4
    part1 = [
        ("G", [74, 79, 83, 79, 74, 79, 83, 86]), ("G", [84, 83, 81, 79, 81, 83, 79, 74]),
        ("C", [76, 79, 84, 79, 76, 79, 84, 88]), ("D", [86, 84, 83, 81, 78, 81, 86, 84]),
        ("G", [83, 86, 91, 86, 83, 79, 83, 86]), ("Em", [88, 86, 83, 79, 76, 79, 83, 88]),
        ("C", [84, 88, 86, 84, 83, 81, 78, 81]), ("G", [(79, 2), (83, 1), (86, 1), (91, 4)]),
    ]
    part2 = [
        ("C", [88, 84, 79, 84, 88, 91, 88, 84]), ("G", [86, 83, 79, 83, 86, 91, 86, 83]),
        ("Am", [84, 81, 76, 81, 84, 88, 84, 81]), ("D", [86, 81, 78, 81, 86, 90, 88, 86]),
        ("G", [83, 79, 74, 79, 83, 86, 83, 79]), ("C", [84, 88, 91, 88, 84, 79, 76, 79]),
        ("D", [78, 81, 86, 90, 93, 90, 86, 81]), ("G", [(91, 4), (86, 2), (79, 2)]),
    ]
    song = part1 + part2 + part1
    length = bar * len(song)
    buf = np.zeros(int((length + 3) * SR))
    for i, (ch, mel) in enumerate(song):
        t0 = i * bar
        notes = CHORDS[ch]
        for b in range(4):
            if b % 2 == 0:
                place(buf, kick(), t0 + b * beat, 0.7)
                place(buf, pluck(mtof(notes[0]), beat * 0.9, 0.35, 0.995), t0 + b * beat, 0.8)
            else:
                place(buf, clap(), t0 + b * beat, 0.5)
                place(buf, pluck(mtof(notes[0] + 7), beat * 0.9, 0.35, 0.995), t0 + b * beat, 0.6)
                place(buf, accordion([mtof(m) for m in notes[1:]], beat * 0.8, 0.16), t0 + b * beat, 1.0)
        tt = t0
        for item in mel:
            if isinstance(item, tuple):
                m, d = item
            else:
                m, d = item, 1
            d = d * 0.5
            place(buf, fiddle(mtof(m), d * beat * 0.95), tt, 0.6)
            tt += d * beat
    return loopify(buf, length, 0.18, 0.75)


# ---------------------------------------------------------------- effects
def formant_voice(f0_curve, dur, formants, vib=0.0, vib_rate=6.0, breath=0.05):
    t = t_axis(dur)
    f0 = np.interp(t, np.linspace(0, dur, len(f0_curve)), f0_curve)
    f0 = f0 * (1 + vib * np.sin(2 * np.pi * vib_rate * t))
    ph = np.cumsum(f0) / SR
    src = 2.0 * (ph - np.floor(ph + 0.5)) + rng.normal(0, breath, len(t))
    y = np.zeros(len(t))
    for (fc, bw, g) in formants:
        y += bandpass(src, max(50, fc - bw / 2), fc + bw / 2) * g
    return y


def sfx_all():
    fx = {}
    t = t_axis(0.14)
    fx["step"] = lowpass(noise(0.14), 500) * np.exp(-t * 35) * 0.8 + np.sin(2 * np.pi * 70 * t) * np.exp(-t * 40) * 0.6
    fx["pickup"] = np.concatenate([music_box(mtof(88), 0.09, 0.4)[:int(0.07 * SR)], music_box(mtof(93), 0.4, 0.5)])
    sw = bandpass(noise(0.35), 1500, 6000) * np.sin(np.linspace(0, np.pi, int(0.35 * SR))) * 0.5
    cl = np.zeros(int(0.45 * SR))
    place(cl, sw, 0.0, 1.0)
    place(cl, music_box(mtof(96), 0.3, 0.4), 0.1, 0.5)
    fx["clean"] = cl
    g = np.zeros(int(0.9 * SR))
    for k, m in enumerate([84, 88, 91, 96]):
        place(g, music_box(mtof(m), 0.7, 0.6), k * 0.08, 0.6)
    fx["gift"] = g
    q = np.zeros(int(1.6 * SR))
    for k, (m, d) in enumerate([(79, 0.12), (84, 0.12), (88, 0.12), (91, 0.9)]):
        place(q, music_box(mtof(m), 1.2, 0.9), k * 0.13, 0.6)
        place(q, flute(mtof(m), d + 0.1), k * 0.13, 0.35)
    place(q, pad([mtof(67), mtof(71), mtof(74)], 1.2, 0.2), 0.39, 1.0)
    fx["quest"] = reverb(q, 0.25)
    fx["scream"] = formant_voice([520, 880, 950, 700], 0.75, [(850, 300, 1.0), (1250, 300, 0.6), (2700, 500, 0.2)], 0.03, 9.0)
    fx["scream"] *= env_adsr(len(fx["scream"]), 0.02, 0.1, 0.85, 0.25)
    fx["lift"] = formant_voice([110, 140, 170], 0.45, [(350, 200, 1.0), (800, 250, 0.4)], 0.02, 20.0) * env_adsr(int(0.45 * SR), 0.03, 0.1, 0.8, 0.15)
    t = t_axis(0.5)
    fx["thud"] = np.sin(2 * np.pi * (60 + 40 * np.exp(-t * 20)) * t) * np.exp(-t * 9) + lowpass(noise(0.5), 300) * np.exp(-t * 12) * 0.4
    t = t_axis(0.9)
    fx["splash"] = (lowpass(noise(0.9), 2500) * np.exp(-t * 5) + bandpass(noise(0.9), 3000, 8000) * np.exp(-t * 9) * 0.3)
    fx["bleat"] = formant_voice([620, 680, 600], 0.55, [(600, 200, 1.0), (1900, 400, 0.5)], 0.06, 22.0) * env_adsr(int(0.55 * SR), 0.03, 0.05, 0.9, 0.2)
    fx["baa"] = formant_voice([330, 360, 320], 0.6, [(750, 250, 1.0), (1150, 300, 0.6)], 0.05, 16.0) * env_adsr(int(0.6 * SR), 0.03, 0.05, 0.9, 0.2)
    t = t_axis(0.7)
    fx["rustle"] = bandpass(noise(0.7), 2000, 7000) * (0.5 + 0.5 * np.abs(np.sin(2 * np.pi * 9 * t))) * np.exp(-t * 3) * 0.6
    gi = np.zeros(int(0.7 * SR))
    for k in range(5):
        v = formant_voice([900 - k * 30, 1000 - k * 40], 0.09, [(1000, 400, 1.0), (2800, 600, 0.5)], 0.0) * env_adsr(int(0.09 * SR), 0.005, 0.02, 0.7, 0.04)
        place(gi, v, k * 0.12, 1.0 - k * 0.1)
    fx["giggle"] = gi
    sl = np.zeros(int(2.0 * SR))
    for k, m in enumerate([81, 78, 74, 69]):
        place(sl, music_box(mtof(m), 1.4, 1.2), k * 0.32, 0.6)
    fx["sleep"] = reverb(sl, 0.35)
    t = t_axis(0.35)
    fx["paper"] = bandpass(noise(0.35), 1500, 7000) * (np.abs(np.sin(2 * np.pi * 14 * t)) ** 3) * np.exp(-t * 5)
    ck = np.zeros(int(0.9 * SR))
    for k in range(5):
        tt = t_axis(0.12)
        f = 250 + k * 60 + 500 * tt / 0.12
        place(ck, np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-tt * 25), k * 0.1, 0.5)
    place(ck, music_box(mtof(91), 0.5, 0.5), 0.55, 0.6)
    fx["cook"] = ck
    t = t_axis(0.04)
    fx["ui_move"] = np.sin(2 * np.pi * 1320 * t) * np.exp(-t * 90)
    t = t_axis(0.14)
    fx["ui_select"] = np.sin(2 * np.pi * np.where(t < 0.05, 880, 1320) * t) * np.exp(-t * 25)
    t = t_axis(0.16)
    fx["ui_open"] = np.sin(2 * np.pi * np.cumsum(500 + 1200 * t / 0.16) / SR) * np.exp(-t * 18)
    t = t_axis(0.13)
    fx["ui_close"] = np.sin(2 * np.pi * np.cumsum(1200 - 800 * t / 0.13) / SR) * np.exp(-t * 20)
    t = t_axis(0.26)
    fx["error"] = np.sign(np.sin(2 * np.pi * 140 * t)) * 0.3 * ((t < 0.1) | (t > 0.14)) * np.exp(-t * 6)
    t = t_axis(0.07)
    bl = formant_voice([420, 440], 0.07, [(700, 400, 1.0), (1500, 500, 0.5)], 0.0, breath=0.02)
    fx["blip"] = bl * env_adsr(len(bl), 0.005, 0.02, 0.6, 0.03)
    return fx


def main():
    only = sys.argv[1:]
    if not only or "music" in only:
        write_ogg("music_day.ogg", day_theme())
        write_ogg("music_night.ogg", night_theme())
        write_ogg("music_festival.ogg", festival_theme())
    if not only or "sfx" in only:
        for name, x in sfx_all().items():
            write_wav("sfx_%s.wav" % name, x, 0.5 if name in ("blip", "ui_move", "step") else 0.8)


if __name__ == "__main__":
    main()
