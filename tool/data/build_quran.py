"""Build assets/quran/*.json from the pinned source files.

    tool/spike/.venv/Scripts/python.exe -I -X utf8 tool/data/build_quran.py

Inputs (byte-exact, pinned in data/CHECKSUMS):
  data/raw/tanzil/quran-uthmani.xml   displayed text, verbatim
  data/raw/tanzil/quran-data.xml      surah metadata
Phonemes come from quran-transcript (pip), from its own copy of the text.

Displayed text is never changed: each ayah is split on spaces only, and the
build fails unless the pieces join back to the exact source string.
"""

import hashlib
import json
import sys
import time
import unicodedata
import xml.etree.ElementTree as ET
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
RAW = ROOT / "data" / "raw"
OUT = ROOT / "assets" / "quran"

# Tanzil pause marks and the sajdah sign: separate tokens, not words.
MARKS = set("ۖۗۘۙۚۛۜ۩")


def check_sums() -> None:
    for line in (ROOT / "data" / "CHECKSUMS").read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        digest, name = line.split(maxsplit=1)
        path = RAW / name.lstrip("*")
        if not path.exists():
            continue  # QUL files may not be downloaded yet
        got = hashlib.sha256(path.read_bytes()).hexdigest()
        if got != digest:
            sys.exit(f"CHECKSUM FAIL {name}: {got}")


def is_mark(tok: str) -> bool:
    return all(c in MARKS for c in tok)


def phonetize(text: str, surah: int) -> list[str]:
    from quran_transcript import MoshafAttributes, alphabet, quran_phonetizer

    moshaf = MoshafAttributes(
        rewaya="hafs", madd_monfasel_len=4, madd_mottasel_len=4, madd_mottasel_waqf=4, madd_aared_len=4
    )
    out = quran_phonetizer(text, moshaf, remove_spaces=False, sura_idx=surah)
    return out.phonemes.split(alphabet.uthmani.space)


def per_word(words: list[str], surah: int) -> list[str]:
    """Phonemes of [words] read together, one string per word.

    Usually the phonemes have one space-separated group per word. Two cases
    break that: separate letters (muqatta'at, 2:1) give several groups for one
    word, and idgham of tanween joins two words into one group (2:2). Then:
    1. match groups to words, comparing with each word phonetized alone;
    2. inside a group that holds several words, cut where each piece best
       matches its word alone.
    """
    groups = phonetize(" ".join(words), surah)
    if len(groups) == len(words):
        return groups
    alone = ["".join(phonetize(w, surah)) for w in words]
    pairs = _match_groups(groups, alone)
    out: list[str] = []
    for (g0, g1), (w0, w1) in pairs:
        text = "".join(groups[g0:g1])
        out.extend(_cut(text, alone[w0:w1]))
    if len(out) != len(words):
        sys.exit(f"surah {surah}: cannot split phonemes of {words!r}")
    return out


def _dist(a: str, b: str) -> float:
    import Levenshtein

    return Levenshtein.distance(a, b) / max(len(a), len(b), 1)


def _match_groups(groups: list[str], alone: list[str]) -> list[tuple[tuple[int, int], tuple[int, int]]]:
    """Pairs of (group range, word range): one group to 1-12 words (chained
    idgham, 26:57-58 joins 7), or 1-8 groups to one word (separate letters). Minimum total distance, by dynamic programming."""
    ng, nw = len(groups), len(alone)
    inf = float("inf")
    best = [[inf] * (nw + 1) for _ in range(ng + 1)]
    back: list[list[tuple[int, int] | None]] = [[None] * (nw + 1) for _ in range(ng + 1)]
    best[0][0] = 0.0
    moves = [(1, k) for k in range(1, 13)] + [(k, 1) for k in range(2, 9)]
    for g in range(ng + 1):
        for w in range(nw + 1):
            if best[g][w] == inf:
                continue
            for dg, dw in moves:
                g2, w2 = g + dg, w + dw
                if g2 > ng or w2 > nw:
                    continue
                text = "".join(groups[g:g2])
                if len(text) < dw:
                    continue  # cannot give each word at least one character
                c = best[g][w] + _dist(text, "".join(alone[w:w2])) + 0.3 * (dg + dw - 2)
                if c < best[g2][w2]:
                    best[g2][w2] = c
                    back[g2][w2] = (g, w)
    if back[ng][nw] is None:
        sys.exit(f"cannot match phoneme groups {groups!r} to words {alone!r}")
    pairs = []
    g, w = ng, nw
    while (g, w) != (0, 0):
        pg, pw = back[g][w]
        pairs.append(((pg, g), (pw, w)))
        g, w = pg, pw
    return pairs[::-1]


# Vowels, madd letters and markers of the phonetic script: a word never
# starts with one, so a cut before one is almost always wrong.
# Hidden noon and meem (ikhfa) always end a syllable, so they cannot start one.
NOT_WORD_START = set("َُؙِ۪اۦۥـڇۜں۾")


def _cut(text: str, alone: list[str]) -> list[str]:
    """Splits [text] into len(alone) non-empty pieces that best match [alone]
    (dynamic programming over cut positions)."""
    n, k = len(text), len(alone)
    if k == 1:
        return [text]
    inf = float("inf")
    best = [[inf] * (k + 1) for _ in range(n + 1)]
    back = [[0] * (k + 1) for _ in range(n + 1)]
    best[0][0] = 0.0
    for j in range(1, k + 1):
        for i in range(j, n - (k - j) + 1):
            for p in range(j - 1, i):
                if best[p][j - 1] == inf:
                    continue
                c = best[p][j - 1] + _dist(text[p:i], alone[j - 1])
                if p > 0 and text[p] in NOT_WORD_START:
                    c += 1.0
                if c < best[i][j]:
                    best[i][j] = c
                    back[i][j] = p
    if best[n][k] == inf:
        sys.exit(f"cannot cut {text!r} into {k} words")
    cuts, i = [], n
    for j in range(k, 0, -1):
        cuts.append(i)
        i = back[i][j]
    cuts.append(0)
    cuts.reverse()
    return [text[cuts[j] : cuts[j + 1]] for j in range(k)]


def build_surah(args: tuple[int, list[str], str | None]) -> dict:
    from quran_transcript import Aya

    surah, texts, basmala = args
    ayahs = []
    qt_words = [Aya(surah, a).get().uthmani.split(" ") for a in range(1, len(texts) + 1)]
    for a, text in enumerate(texts, start=1):
        toks = text.split(" ")
        words: list[dict] = []
        for tok in toks:
            if is_mark(tok):
                if not words:
                    sys.exit(f"{surah}:{a} starts with a mark")
                words[-1]["m"] = words[-1].get("m", "") + (" " if "m" in words[-1] else "") + tok
            else:
                words.append({"t": tok})
        # The display pieces must give back the exact source string.
        rebuilt = " ".join(w["t"] + (" " + w["m"] if "m" in w else "") for w in words)
        if rebuilt != text:
            sys.exit(f"{surah}:{a} display split changed the text")

        qt = qt_words[a - 1]
        if len(qt) != len(words):
            sys.exit(f"{surah}:{a} word count {len(words)} vs quran-transcript {len(qt)}")
        ph = per_word(qt, surah)
        for w, p in zip(words, ph):
            w["p"] = p

        # Stopping at a pause mark: the word before it in its waqf form, and
        # the word after it as a fresh start (hamzat wasl is pronounced).
        for i, w in enumerate(words[:-1]):
            if "m" in w:
                _add_variant(w, per_word(qt[: i + 1], surah)[-1])
                _add_variant(words[i + 1], per_word(qt[i + 1 :], surah)[0])
        ayahs.append({"a": a, "w": words})

    # Joining two ayahs without stopping (wasl): the last word of one and the
    # first word of the next change form.
    for a in range(1, len(ayahs)):
        joined = per_word(qt_words[a - 1] + qt_words[a], surah)
        n = len(qt_words[a - 1])
        _add_variant(ayahs[a - 1]["w"][-1], joined[n - 1])
        _add_variant(ayahs[a]["w"][0], joined[n])

    return {"s": surah, "basmala": basmala, "ayahs": ayahs}


def _add_variant(word: dict, p: str) -> None:
    if p != word["p"] and p not in word.get("v", []):
        word.setdefault("v", []).append(p)


def main() -> int:
    check_sums()
    text_root = ET.parse(RAW / "tanzil" / "quran-uthmani.xml").getroot()
    meta_root = ET.parse(RAW / "tanzil" / "quran-data.xml").getroot()
    meta = {int(s.get("index")): s.attrib for s in meta_root.find("suras")}

    jobs = []
    total = 0
    for sura in text_root:
        s = int(sura.get("index"))
        texts = [aya.get("text") for aya in sura]
        if len(texts) != int(meta[s]["ayas"]):
            sys.exit(f"surah {s}: {len(texts)} ayahs, metadata says {meta[s]['ayas']}")
        total += len(texts)
        jobs.append((s, texts, sura[0].get("bismillah")))
    if len(jobs) != 114 or total != 6236:
        sys.exit(f"expected 114 surahs and 6236 ayahs, got {len(jobs)} and {total}")

    OUT.mkdir(parents=True, exist_ok=True)
    t0 = time.time()
    with ProcessPoolExecutor() as ex:
        for result in ex.map(build_surah, jobs):
            s = result["s"]
            path = OUT / f"s{s:03d}.json"
            path.write_text(json.dumps(result, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
            print(f"surah {s:3d}  {len(result['ayahs']):3d} ayahs  {time.time() - t0:6.1f}s", flush=True)

    index = [
        {
            "s": s,
            "name": meta[s]["name"],
            "tname": meta[s]["tname"],
            "ename": meta[s]["ename"],
            "type": meta[s]["type"],
            "ayas": int(meta[s]["ayas"]),
        }
        for s in range(1, 115)
    ]
    (OUT / "index.json").write_text(json.dumps(index, ensure_ascii=False, indent=0), encoding="utf-8")
    print(f"done in {time.time() - t0:.0f}s")
    return 0


if __name__ == "__main__":
    sys.exit(main())
