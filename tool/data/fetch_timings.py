"""Fetch Alafasy surah audio metadata and word timings into assets/quran/audio_alafasy.json.

    python -I -X utf8 tool/data/fetch_timings.py

Source: the quran.com audio API (reciter 7, Mishary Alafasy, murattal). Each
surah is one MP3 with ayah and word timings. Word positions are checked
against assets/quran (the app's words): an ayah whose word count differs keeps
its ayah timing and drops its word timings, so a word is never highlighted
wrong.
"""

import json
import sys
import time
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
QURAN = ROOT / "assets" / "quran"
OUT = QURAN / "audio_alafasy.json"
API = "https://api.qurancdn.com/api/qdc/audio/reciters/7/audio_files?chapter={}&segments=true"


def get(url: str) -> dict:
    for attempt in range(4):
        try:
            with urllib.request.urlopen(url, timeout=60) as r:
                return json.loads(r.read().decode("utf-8"))
        except Exception as e:  # network hiccup: retry
            if attempt == 3:
                raise
            print(f"retry {url}: {e}", file=sys.stderr)
            time.sleep(2 * (attempt + 1))
    raise AssertionError


def main() -> int:
    surahs = []
    dropped = 0
    for s in range(1, 115):
        local = json.loads((QURAN / f"s{s:03d}.json").read_text(encoding="utf-8"))
        words_per_ayah = {a["a"]: len(a["w"]) for a in local["ayahs"]}
        f = get(API.format(s))["audio_files"][0]
        ayahs = []
        for vt in f["verse_timings"]:
            a = int(vt["verse_key"].split(":")[1])
            segs = [seg for seg in vt["segments"] if len(seg) == 3]
            positions = [seg[0] for seg in segs]
            if positions != list(range(1, words_per_ayah[a] + 1)):
                dropped += 1
                print(f"  {s}:{a} word timings dropped: {len(positions)} segments, {words_per_ayah[a]} words")
                segs = []
            ayahs.append([vt["timestamp_from"], vt["timestamp_to"], [[seg[1], seg[2]] for seg in segs]])
        if [vt_a for vt_a in range(1, len(ayahs) + 1)] != sorted(words_per_ayah):
            sys.exit(f"surah {s}: {len(ayahs)} ayah timings, {len(words_per_ayah)} ayahs")
        surahs.append({"s": s, "url": f["audio_url"], "bytes": int(f["file_size"]), "ms": f["duration"], "ayahs": ayahs})
        print(f"surah {s:3d}  {int(f['file_size']) / 1e6:6.1f} MB", flush=True)
    OUT.write_text(json.dumps({"reciter": "Mishary Rashid Alafasy", "surahs": surahs}, separators=(",", ":")), encoding="utf-8")
    print(f"done: {dropped} ayahs without word timings")
    return 0


if __name__ == "__main__":
    sys.exit(main())
