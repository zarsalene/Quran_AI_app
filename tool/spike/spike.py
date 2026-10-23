"""ASR spike: run the Quran phoneme model on 5 clips and compare with quran-transcript.

Usage (from tool/spike):
    .venv/Scripts/hf.exe auth login                    # once, after HF approves access
    .venv/Scripts/python.exe -I -X utf8 spike.py --model v3   # gated, needs approval
    .venv/Scripts/python.exe -I -X utf8 spike.py --model v2   # public mirror

The Quran text comes from the quran-transcript package data. Nothing is typed here.
"""

import dataclasses
import json
import os
import sys
import time
import urllib.request
from pathlib import Path

import numpy as np
import soundfile as sf
import soxr
from quran_transcript import Aya, MoshafAttributes, alphabet, quran_phonetizer

HERE = Path(__file__).parent
CLIPS_DIR = HERE / "clips"
MODEL_DIR = HERE / "model"
# Pick a model with --model. v3 is gated (manual approval). v2 is an
# unmodified public mirror of Muno459/zipformer_p-arabic-v2 (NPL-1.1).
MODELS = {
    "v3": ("Quran-Lab/zipformer_p-arabic-v3", "zipformer_p_arabic_v3.int8.onnx"),
    "v2": ("swaraadam/quran-phoneme-zipformer", "model.int8.onnx"),
}
MODEL_NAME = sys.argv[sys.argv.index("--model") + 1] if "--model" in sys.argv else "v3"
MODEL_REPO, MODEL_FILE = MODELS[MODEL_NAME]
TOKENS_FILE = "tokens.txt"
REPORT = HERE / f"SPIKE_REPORT_{MODEL_NAME}.md"
RECITER = "Alafasy_64kbps"

# (surah, ayah): short, long, and edge cases (basmala ayah, last ayah of the mushaf).
CLIPS = [(1, 1), (1, 7), (2, 255), (112, 1), (114, 6)]

# Murattal Hafs settings. The model card says its training labels fix munfasil at 4.
MOSHAF = MoshafAttributes(
    rewaya="hafs",
    madd_monfasel_len=4,
    madd_mottasel_len=4,
    madd_mottasel_waqf=4,
    madd_aared_len=4,
)


def reference(surah: int, ayah: int) -> tuple[str, list[str], str]:
    uthmani = Aya(surah, ayah).get().uthmani
    out = quran_phonetizer(uthmani, MOSHAF, remove_spaces=False, sura_idx=surah)
    words = out.phonemes.split(alphabet.uthmani.space)
    return uthmani, words, "".join(words)


def fetch_clip(surah: int, ayah: int) -> np.ndarray:
    CLIPS_DIR.mkdir(exist_ok=True)
    mp3 = CLIPS_DIR / f"{surah:03d}{ayah:03d}.mp3"
    if not mp3.exists():
        url = f"https://everyayah.com/data/{RECITER}/{mp3.name}"
        urllib.request.urlretrieve(url, mp3)
    audio, sr = sf.read(mp3, dtype="float32", always_2d=True)
    audio = audio.mean(axis=1)
    return soxr.resample(audio, sr, 16000).astype(np.float32)


def fetch_model() -> tuple[Path, Path] | None:
    model_dir = MODEL_DIR / MODEL_NAME
    model, tokens = model_dir / MODEL_FILE, model_dir / TOKENS_FILE
    if model.exists() and tokens.exists():
        return model, tokens
    from huggingface_hub import get_token, hf_hub_download

    token = os.environ.get("HF_TOKEN") or get_token()
    if not token and MODEL_NAME == "v3":
        return None

    for name in (MODEL_FILE, TOKENS_FILE, "LICENSE"):
        hf_hub_download(MODEL_REPO, name, local_dir=model_dir, token=token)
    return model, tokens


def recognize(rec, samples: np.ndarray) -> str:
    stream = rec.create_stream()
    stream.accept_waveform(16000, samples)
    stream.accept_waveform(16000, np.zeros(int(0.66 * 16000), dtype=np.float32))
    stream.input_finished()
    while rec.is_ready(stream):
        rec.decode_stream(stream)
    return rec.get_result(stream)


def edit_distance(a: str, b: str) -> int:
    prev = list(range(len(b) + 1))
    for i, ca in enumerate(a, 1):
        cur = [i]
        for j, cb in enumerate(b, 1):
            cur.append(min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (ca != cb)))
        prev = cur
    return prev[-1]


def main() -> int:
    paths = fetch_model()
    rec = None
    if paths:
        import sherpa_onnx

        rec = sherpa_onnx.OnlineRecognizer.from_zipformer2_ctc(
            tokens=str(paths[1]),
            model=str(paths[0]),
            num_threads=2,
            sample_rate=16000,
            feature_dim=80,
            decoding_method="greedy_search",
        )
        token_chars = set()
        for line in paths[1].read_text(encoding="utf-8").splitlines():
            sym = line.rsplit(" ", 1)[0]
            if not sym.startswith("<"):
                token_chars.update(sym)
    else:
        print("No HF_TOKEN and no local model: printing reference phonemes only.\n")

    lines = ["# ASR spike report", "", f"Model: `{MODEL_REPO}/{MODEL_FILE}`", f"Audio: everyayah `{RECITER}`", ""]
    ref_chars: set[str] = set()
    hyp_chars: set[str] = set()
    total_err = total_len = 0
    hyps: dict[str, str] = {}
    for surah, ayah in CLIPS:
        uthmani, words, ref = reference(surah, ayah)
        ref_chars.update(ref)
        samples = fetch_clip(surah, ayah)
        block = [f"## {surah}:{ayah} ({len(samples) / 16000:.1f} s, {len(words)} words)", "", f"text: {uthmani}", f"ref : {ref}"]
        if rec:
            t0 = time.perf_counter()
            hyp = recognize(rec, samples).replace(" ", "")
            rtf = (time.perf_counter() - t0) / (len(samples) / 16000)
            hyps[f"{surah}:{ayah}"] = hyp
            hyp_chars.update(hyp)
            err = edit_distance(ref, hyp)
            total_err += err
            total_len += len(ref)
            block += [f"hyp : {hyp}", f"char edits: {err} / {len(ref)} ({100 * err / len(ref):.2f}%), RTF {rtf:.3f}"]
        block.append("")
        print("\n".join(block))
        lines += [block[0], "", "```", *block[2:-1], "```", ""]

    if rec:
        alpha = {getattr(alphabet.phonetics, f.name) for f in dataclasses.fields(alphabet.phonetics)}
        alpha_chars = {c for s in alpha for c in s}
        lines += [
            "## Alphabet check",
            "",
            f"- Overall character error rate vs reference: {100 * total_err / total_len:.2f}%",
            f"- quran-transcript phonetic alphabet: {len(alpha_chars)} characters",
            f"- Model tokens.txt characters not in that alphabet: {sorted(token_chars - alpha_chars) or 'none'}",
            f"- Alphabet characters missing from tokens.txt: {sorted(alpha_chars - token_chars) or 'none'}",
            f"- Characters in model output not in that alphabet: {sorted(hyp_chars - alpha_chars) or 'none'}",
        ]
        print("\n".join(lines[-6:]))
        REPORT.write_text("\n".join(lines) + "\n", encoding="utf-8")
        (HERE / f"hyp_{MODEL_NAME}.json").write_text(json.dumps(hyps, ensure_ascii=False, indent=1), encoding="utf-8")
        print(f"\nWrote {REPORT}")

    # Save the per-word reference so the Dart aligner tests can reuse it.
    (HERE / "reference_words.json").write_text(
        json.dumps({f"{s}:{a}": reference(s, a)[1] for s, a in CLIPS}, ensure_ascii=False, indent=1),
        encoding="utf-8",
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
