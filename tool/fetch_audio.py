"""Download the bundled recitation audio into assets/audio/ and verify it.

    python tool/fetch_audio.py --pin    # after the audio source changes

The encoded MP3s are committed, so builds do not run this script. Run it only
to change the bundled audio, then commit assets/audio/ and data/AUDIO_CHECKSUMS.

Bundled: Al-Fatiha and Juz 30 (surahs 78-114), Alafasy, so a new user can
listen and learn with no internet. Other surahs download in the app.

Each source MP3 is pinned by SHA-256 in data/AUDIO_CHECKSUMS, then re-encoded
to 40 kbps mono (about 17 MB in total instead of 62 MB). Re-encoding keeps the
duration, so the word timings in assets/quran/audio_alafasy.json still match.
"""

import hashlib
import json
import shutil
import subprocess
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TIMINGS = ROOT / "assets" / "quran" / "audio_alafasy.json"
PINS = ROOT / "data" / "AUDIO_CHECKSUMS"
CACHE = ROOT / "build" / "audio-src"
DEST = ROOT / "assets" / "audio"
BUNDLED = [1, *range(78, 115)]


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def ffmpeg() -> str:
    exe = shutil.which("ffmpeg")
    if exe:
        return exe
    try:
        import imageio_ffmpeg  # pip install imageio-ffmpeg

        return imageio_ffmpeg.get_ffmpeg_exe()
    except ImportError:
        sys.exit("ffmpeg not found: install it, or pip install imageio-ffmpeg")


def main() -> int:
    pin = "--pin" in sys.argv
    urls = {s["s"]: s["url"] for s in json.loads(TIMINGS.read_text(encoding="utf-8"))["surahs"]}
    pins = {}
    if not pin:
        for line in PINS.read_text(encoding="utf-8").splitlines():
            digest, name = line.split(maxsplit=1)
            pins[name.lstrip("*")] = digest
    CACHE.mkdir(parents=True, exist_ok=True)
    DEST.mkdir(parents=True, exist_ok=True)
    exe = ffmpeg()
    out_pins = []
    for s in BUNDLED:
        name = f"s{s:03d}.mp3"
        src = CACHE / name
        if not src.exists() or (not pin and sha256(src) != pins[name]):
            print(f"fetch   {name}", flush=True)
            req = urllib.request.Request(urls[s], headers={"User-Agent": "rattil-build/1.0"})
            with urllib.request.urlopen(req, timeout=120) as r:
                src.write_bytes(r.read())
        got = sha256(src)
        if not pin and got != pins[name]:
            print(f"FAIL    {name}: sha256 {got}, expected {pins[name]}", file=sys.stderr)
            return 1
        out_pins.append(f"{got} *{name}")
        out = DEST / name
        stamp = CACHE / f"{name}.encoded"  # outside assets/, so it never ships
        if out.exists() and stamp.exists() and stamp.read_text() == got:
            print(f"ok      {name}")
            continue
        subprocess.run(
            [exe, "-loglevel", "error", "-y", "-i", str(src), "-map_metadata", "-1", "-vn",
             "-ac", "1", "-ar", "24000", "-b:a", "40k", str(out)],
            check=True,
        )
        stamp.write_text(got)
        print(f"encode  {name}  {out.stat().st_size / 1e6:.1f} MB", flush=True)
    if pin:
        PINS.write_text("\n".join(out_pins) + "\n", encoding="utf-8")
        print(f"pinned {len(out_pins)} files in {PINS.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
