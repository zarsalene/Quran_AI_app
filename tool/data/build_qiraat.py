"""Build assets/qiraat/<riwaya>.json and the matching fonts from the King Fahd
Complex (KFGQPC) Unicode data, for the riwayat other than Hafs.

    python -I -X utf8 tool/data/build_qiraat.py          # verify pins and build
    python -I -X utf8 tool/data/build_qiraat.py --pin    # once, to pin new sources

Source: KFGQPC data and fonts (qurancomplex.gov.sa), through the mirror
github.com/thetruetruth/quran-data-kfgqpc at a fixed commit. Every source file
is pinned by SHA-256 in data/CHECKSUMS_QIRAAT.

The displayed text is never changed. Each source ayah ends with a space and
the ayah number in Arabic digits: the build removes exactly that
suffix and fails unless the number equals the ayah's position. The build also
fails unless each riwaya has its known ayah count.

Al-Duri and al-Susi (Abu Amr) are not built yet: their data has 6217 ayahs,
and the count the Complex uses for them is not confirmed.
"""

import hashlib
import json
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
COMMIT = "281dbbe8eed1370daa5a023b6cd81655cbfd6473"
BASE = f"https://raw.githubusercontent.com/thetruetruth/quran-data-kfgqpc/{COMMIT}"
PINS = ROOT / "data" / "CHECKSUMS_QIRAAT"
CACHE = ROOT / "build" / "qiraat-src"
OUT = ROOT / "assets" / "qiraat"
FONTS = ROOT / "assets" / "fonts" / "qiraat"

# key: (mirror folder, data file, font file, ayah count, counting school)
RIWAYAT = {
    "warsh": ("warsh", "warshData_v10.json", "warsh.10.ttf", 6214, "Madani (later)"),
    "qalun": ("qaloon", "QaloonData_v10.json", "qaloon.10.ttf", 6214, "Madani (later)"),
    "shuba": ("shouba", "ShoubaData08.json", "shouba.8.ttf", 6236, "Kufi"),
    "bazzi": ("bazzi", "BazziData_v07.json", "bazzi.7.ttf", 6220, "Makki"),
    "qunbul": ("qumbul", "QumbulData_v07.json", "qumbul.7.ttf", 6220, "Makki"),
}

DIGITS = "٠١٢٣٤٥٦٧٨٩"


def sha256(b: bytes) -> str:
    return hashlib.sha256(b).hexdigest()


def fetch(rel: str) -> bytes:
    path = CACHE / rel
    if not path.exists():
        path.parent.mkdir(parents=True, exist_ok=True)
        with urllib.request.urlopen(f"{BASE}/{rel}", timeout=120) as r:
            path.write_bytes(r.read())
    return path.read_bytes()


def arabic_int(s: str) -> int:
    if not s or any(c not in DIGITS for c in s):
        raise ValueError(s)
    return int("".join(str(DIGITS.index(c)) for c in s))


def build(key: str, folder: str, data_file: str, count: int) -> dict:
    rows = json.loads(fetch(f"{folder}/data/{data_file}").decode("utf-8"))
    if len(rows) != count:
        sys.exit(f"{key}: {len(rows)} ayahs, expected {count}")
    surahs: dict[int, list] = {}
    for r in rows:
        s, a = int(r.get("sura_no") or r["sora"]), int(r["aya_no"])
        text = r["aya_text"].rstrip()
        # The number follows a no-break space (a normal space in 2 Warsh ayahs).
        cut = max(text.rfind(" "), text.rfind(" "))
        body, num = text[:cut], text[cut + 1 :]
        if cut < 0 or arabic_int(num) != a:
            sys.exit(f"{key} {s}:{a}: ayah number suffix missing or wrong: {text[-12:]!r}")
        ayahs = surahs.setdefault(s, [])
        if a != len(ayahs) + 1:
            sys.exit(f"{key} {s}:{a}: out of order")
        page = int(str(r["page"]).split("-")[0])
        ayahs.append([body, page, int(r["jozz"])])
    if sorted(surahs) != list(range(1, 115)):
        sys.exit(f"{key}: surahs {len(surahs)}")
    return {"key": key, "ayahs": count, "surahs": [{"s": s, "a": surahs[s]} for s in range(1, 115)]}


def main() -> int:
    pin = "--pin" in sys.argv
    pins = {}
    if not pin:
        for line in PINS.read_text(encoding="utf-8").splitlines():
            digest, name = line.split(maxsplit=1)
            pins[name.lstrip("*")] = digest
    out_pins = []
    OUT.mkdir(parents=True, exist_ok=True)
    FONTS.mkdir(parents=True, exist_ok=True)
    for key, (folder, data_file, font_file, count, school) in RIWAYAT.items():
        for rel in (f"{folder}/data/{data_file}", f"{folder}/font/{font_file}"):
            got = sha256(fetch(rel))
            if not pin and pins.get(rel) != got:
                sys.exit(f"CHECKSUM FAIL {rel}: {got}")
            out_pins.append(f"{got} *{rel}")
        result = build(key, folder, data_file, count)
        (OUT / f"{key}.json").write_text(json.dumps(result, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
        (FONTS / f"{key}.ttf").write_bytes(fetch(f"{folder}/font/{font_file}"))
        print(f"{key:7s} {count} ayahs ({school})")
    if pin:
        PINS.write_text(f"# github.com/thetruetruth/quran-data-kfgqpc @ {COMMIT}\n" + "\n".join(out_pins) + "\n", encoding="utf-8")
        print(f"pinned {len(out_pins)} files")
    return 0


if __name__ == "__main__":
    sys.exit(main())
