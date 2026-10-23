"""Download the on-device models into assets/models/ and verify their SHA-256.

The models are not in Git (72 MB). CI and local builds run this first:
    python tool/fetch_models.py

Every file is pinned to an exact source revision and checksum. A changed file
fails the build instead of shipping silently.
"""

import hashlib
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEST = ROOT / "assets" / "models"

# ASR: zipformer_p-arabic-v2 (Muno459 / Quran-Lab), streaming CTC, int8.
# Public unmodified mirror. License NPL-1.1: free, non-profit use only.
_HF = "https://huggingface.co/swaraadam/quran-phoneme-zipformer/resolve/2193d07a7d02761f6177ed12a56ecaf30658d123"
# VAD: Silero VAD as packaged by sherpa-onnx (MIT).
_VAD = "https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/silero_vad.onnx"

FILES = [
    ("asr.int8.onnx", f"{_HF}/model.int8.onnx", "97da4c2fcaa192bfd1e0deb79f2a76cc30882dfc5f077ffa41ac9fe87f80f667"),
    ("tokens.txt", f"{_HF}/tokens.txt", "252c10687e442aa9291973065fae19fa39bcd681c4f5612ec496a647e20b43a1"),
    ("ASR_LICENSE.txt", f"{_HF}/LICENSE", "8ee6366f4b3ccb70dd2e9265d8a02505b402c088065a72b2251e1b89e8476b34"),
    ("silero_vad.onnx", _VAD, "9e2449e1087496d8d4caba907f23e0bd3f78d91fa552479bb9c23ac09cbb1fd6"),
]


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for block in iter(lambda: f.read(1 << 20), b""):
            h.update(block)
    return h.hexdigest()


def main() -> int:
    DEST.mkdir(parents=True, exist_ok=True)
    for name, url, expected in FILES:
        path = DEST / name
        if path.exists() and sha256(path) == expected:
            print(f"ok      {name}")
            continue
        print(f"fetch   {name}")
        tmp = path.with_suffix(path.suffix + ".part")
        urllib.request.urlretrieve(url, tmp)
        got = sha256(tmp)
        if got != expected:
            tmp.unlink()
            print(f"FAIL    {name}: sha256 {got}, expected {expected}", file=sys.stderr)
            return 1
        tmp.replace(path)
    return 0


if __name__ == "__main__":
    sys.exit(main())
