"""Fetch a reciter's surah audio metadata and word timings into
assets/quran/audio_<key>.json.

    python -I -X utf8 tool/data/fetch_timings.py alafasy
    python -I -X utf8 tool/data/fetch_timings.py husary_muallim

Source: the quran.com audio API. Each surah is one MP3 with ayah and word
timings. Word positions are checked against assets/quran (the app's words).
A few long ayahs have no segment for one or two words: the app then plays from
the word before to the word after. A position past the last word fails the
build.
"""

import json
import sys
import time
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
QURAN = ROOT / "assets" / "quran"
API = "https://api.qurancdn.com/api/qdc/audio/reciters/{}/audio_files?chapter={}&segments=true"

# key: (quran.com reciter id, display name)
RECITERS = {
    "alafasy": (7, "Mishary Rashid Alafasy"),
    "husary_muallim": (12, "Mahmoud Khalil Al-Husary (Muallim)"),
}

HEADERS = {"User-Agent": "rattil-build/1.0", "Accept": "application/json"}  # the API refuses Python's default


def get(url: str) -> dict:
    for attempt in range(4):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers=HEADERS), timeout=60) as r:
                return json.loads(r.read().decode("utf-8"))
        except Exception as e:  # network hiccup: retry
            if attempt == 3:
                raise
            print(f"retry {url}: {e}", file=sys.stderr)
            time.sleep(2 * (attempt + 1))
    raise AssertionError


def size_of(url: str) -> int:
    req = urllib.request.Request(url, method="HEAD", headers=HEADERS)
    with urllib.request.urlopen(req, timeout=60) as r:
        return int(r.headers["Content-Length"])


def main() -> int:
    key = sys.argv[1] if len(sys.argv) > 1 else "alafasy"
    reciter_id, name = RECITERS[key]
    surahs = []
    dropped = 0  # words with no segment
    for s in range(1, 115):
        local = json.loads((QURAN / f"s{s:03d}.json").read_text(encoding="utf-8"))
        words_per_ayah = {a["a"]: len(a["w"]) for a in local["ayahs"]}
        f = get(API.format(reciter_id, s))["audio_files"][0]
        ayahs = []
        for vt in f["verse_timings"]:
            a = int(vt["verse_key"].split(":")[1])
            # The reciter sometimes goes back and repeats a phrase, so a word
            # can have several segments. Keep them in time order: [word, from, to].
            # A few segments in the source end before they start: drop them
            # (the word then plays from the word before to the word after).
            segs = [[int(seg[0]), round(seg[1]), round(seg[2])] for seg in vt["segments"] if len(seg) == 3 and seg[2] > seg[1]]
            n = words_per_ayah[a]
            # A few ayahs count words from 0 instead of 1.
            if segs and min(seg[0] for seg in segs) == 0:
                segs = [[seg[0] + 1, seg[1], seg[2]] for seg in segs]
            if any(not 1 <= seg[0] <= n for seg in segs):
                sys.exit(f"{s}:{a}: word position out of range 1..{n}")
            missing = set(range(1, n + 1)) - {seg[0] for seg in segs}
            dropped += len(missing)
            ayahs.append([round(vt["timestamp_from"]), round(vt["timestamp_to"]), [[seg[0] - 1, seg[1], seg[2]] for seg in segs]])
        if len(ayahs) != len(words_per_ayah):
            sys.exit(f"surah {s}: {len(ayahs)} ayah timings, {len(words_per_ayah)} ayahs")
        size = int(f["file_size"]) if f.get("file_size") else size_of(f["audio_url"])
        surahs.append({"s": s, "url": f["audio_url"], "bytes": size, "ms": round(f["duration"]), "ayahs": ayahs})
        print(f"surah {s:3d}  {size / 1e6:6.1f} MB", flush=True)
    out = QURAN / f"audio_{key}.json"
    out.write_text(json.dumps({"reciter": name, "surahs": surahs}, separators=(",", ":")), encoding="utf-8")
    print(f"done: {dropped} words without a segment")
    return 0


if __name__ == "__main__":
    sys.exit(main())
