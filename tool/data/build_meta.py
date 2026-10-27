"""Build assets/quran/meta.json (Madani pages, juz, hizb quarters, sajdahs).

    python -I -X utf8 tool/data/build_meta.py

Input: data/raw/tanzil/quran-data.xml (pinned in data/CHECKSUMS). Each list
holds the [surah, ayah] where a division starts, in order.
"""

import hashlib
import json
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
SRC = ROOT / "data" / "raw" / "tanzil" / "quran-data.xml"
OUT = ROOT / "assets" / "quran" / "meta.json"


def main() -> int:
    pinned = {
        name.lstrip("*"): digest
        for digest, name in (l.split(maxsplit=1) for l in (ROOT / "data" / "CHECKSUMS").read_text().splitlines() if l)
    }
    if hashlib.sha256(SRC.read_bytes()).hexdigest() != pinned["tanzil/quran-data.xml"]:
        sys.exit("CHECKSUM FAIL tanzil/quran-data.xml")
    root = ET.parse(SRC).getroot()

    def starts(group: str, tag: str) -> list[list[int]]:
        return [[int(e.get("sura")), int(e.get("aya"))] for e in root.find(group).iter(tag)]

    meta = {
        "pages": starts("pages", "page"),
        "juz": starts("juzs", "juz"),
        "quarters": starts("hizbs", "quarter"),
        "sajdas": [[int(e.get("sura")), int(e.get("aya"))] for e in root.find("sajdas").iter("sajda")],
    }
    for key, n in [("pages", 604), ("juz", 30), ("quarters", 240), ("sajdas", 15)]:
        if len(meta[key]) != n:
            sys.exit(f"{key}: {len(meta[key])}, expected {n}")
        if key != "sajdas" and meta[key] != sorted(meta[key]):
            sys.exit(f"{key} not in order")
    OUT.write_text(json.dumps(meta, separators=(",", ":")), encoding="utf-8")
    print(f"wrote {OUT.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
