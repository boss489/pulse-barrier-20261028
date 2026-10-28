import wave
import math
import struct
import pathlib

root = pathlib.Path(__file__).resolve().parent / "assets"
specs = {"step": (.07, 420, 310), "pulse": (.19, 105, 52), "fail": (.34, 310, 59), "win": (.48, 440, 880)}
rate = 22050
for name, (duration, start, end) in specs.items():
    path = root / (name + ".wav")
    with wave.open(str(path), "wb") as sound:
        sound.setnchannels(1)
        sound.setsampwidth(2)
        sound.setframerate(rate)
        phase = 0.0
        data = []
        for i in range(int(rate * duration)):
            t = i / rate
            hz = start + (end - start) * t / duration
            phase += 2 * math.pi * hz / rate
            envelope = (1 - t / duration) ** 2 * (1 - math.exp(-t * 90))
            signal = math.sin(phase) * .57 + math.sin(phase * 2.01) * .13
            data.append(struct.pack("<h", int(max(-1, min(1, signal * envelope)) * 18000)))
        sound.writeframes(b"".join(data))
    print(name, path.stat().st_size)
