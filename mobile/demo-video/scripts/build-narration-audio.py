#!/usr/bin/env python3
"""Synthesise every narration line and record its length.

This runs BEFORE recording. The specs read the manifest this produces so a scene
can be paced to the narration rather than the other way round — see
tests/demo/demo-narration.ts.

Usage:
  scripts/build-narration-audio.py [--force]
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

# Đường dẫn tính theo thư mục dự án đang chạy, không theo vị trí script, để bộ
# script này copy vào repo nào cũng chạy được.
ROOT = Path(os.environ.get("DEMO_PROJECT_ROOT", Path.cwd())).resolve()
SPEC = Path(os.environ.get("DEMO_NARRATION_FILE", ROOT / "demo-narration.json"))
OUT = ROOT / "demo-out" / "narration"
MANIFEST = OUT / "manifest.json"

TTS_CANDIDATES = [
    ROOT / ".tts-venv" / "bin" / "edge-tts",
    Path(shutil.which("edge-tts") or "/nonexistent"),
]


def tts_binary() -> Path:
    for candidate in TTS_CANDIDATES:
        if candidate.exists():
            return candidate
    sys.exit("edge-tts not found. python3 -m venv .tts-venv && .tts-venv/bin/pip install edge-tts")


# Ngưỡng coi là file audio hợp lệ. edge-tts khi lỗi tạm thời vẫn tạo file rỗng,
# và lần chạy sau sẽ tưởng đã có sẵn rồi bỏ qua — nên phải kiểm tra kích thước.
MIN_AUDIO_BYTES = 800

# Dịch vụ của Microsoft chặn tốc độ khi gọi liên tiếp: cùng một câu lúc chạy lúc
# không, báo lỗi 'No audio was received' như thể sai tham số. Cách chữa là chờ lâu
# hơn giữa các lần thử và giãn nhịp giữa các câu, không phải sửa nội dung câu.
TTS_RETRIES = 6
TTS_BACKOFF_SECONDS = 5
TTS_GAP_SECONDS = 1.5


def run(cmd: list[str]) -> None:
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        sys.exit(f"command failed: {' '.join(cmd[:5])}...\n{proc.stderr[-1500:]}")


def usable(path: Path) -> bool:
    return path.exists() and path.stat().st_size >= MIN_AUDIO_BYTES


def synthesise(binary: str, voice: str, rate: str, text: str, dest: Path) -> None:
    """Sinh một câu, thử lại khi dịch vụ trả lỗi tạm thời.

    edge-tts gọi ra dịch vụ mạng và thỉnh thoảng trả 'No audio was received' dù tham
    số đúng. Nó vẫn để lại file rỗng, nên phải xoá file hỏng trước khi thử lại —
    không thì lần chạy kế tiếp coi đó là bản đã cache.
    """
    last_error = ""
    for attempt in range(1, TTS_RETRIES + 1):
        proc = subprocess.run(
            [binary, "--voice", voice, f"--rate={rate}", "--text", text,
             "--write-media", str(dest)],
            capture_output=True, text=True)

        if proc.returncode == 0 and usable(dest):
            time.sleep(TTS_GAP_SECONDS)  # giãn nhịp để không bị chặn tốc độ
            return

        last_error = (proc.stderr or proc.stdout or "").strip().splitlines()[-1:] or [""]
        last_error = last_error[0]
        dest.unlink(missing_ok=True)
        if attempt < TTS_RETRIES:
            time.sleep(TTS_BACKOFF_SECONDS * attempt)

    sys.exit(f"TTS thất bại sau {TTS_RETRIES} lần cho câu:\n  {text[:80]}\n  {last_error}")


def duration_ms(path: Path) -> int:
    out = subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(path)],
        capture_output=True, text=True, check=True).stdout.strip()
    return int(round(float(out) * 1000))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--force", action="store_true", help="re-synthesise lines that already exist")
    args = parser.parse_args()

    spec = json.loads(SPEC.read_text(encoding="utf-8"))
    # Mỗi câu chọn giọng theo "speaker"; câu không ghi speaker dùng giọng mặc định.
    voices = spec.get("voices") or {"default": {"voice": spec["voice"], "rate": spec["rate"]}}
    default_speaker = spec.get("defaultSpeaker", next(iter(voices)))
    OUT.mkdir(parents=True, exist_ok=True)

    lines: dict[str, dict] = {}
    binary = str(tts_binary())

    for scene_key, scene in spec["scenes"].items():
        print(f"==> {scene_key}")
        for line in scene["lines"]:
            dest = OUT / f"{line['id']}.mp3"
            # Chỉ coi là đã cache khi file thật sự dùng được, không chỉ khi tồn tại.
            speaker = line.get("speaker", default_speaker)
            v = voices[speaker]
            if args.force or not usable(dest):
                synthesise(binary, v["voice"], v["rate"], line["text"], dest)
            ms = duration_ms(dest)
            lines[line["id"]] = {"file": dest.name, "ms": ms, "text": line["text"], "speaker": speaker}
            print(f"    {line['id']:<10} {speaker:<5} {ms / 1000:5.1f}s  {line['text'][:56]}")

    MANIFEST.write_text(json.dumps({"voices": voices, "lines": lines},
                                   ensure_ascii=False, indent=2), encoding="utf-8")

    total = sum(v["ms"] for v in lines.values()) / 1000
    print(f"\n{len(lines)} lines, {total:.0f}s of speech -> {MANIFEST}")


if __name__ == "__main__":
    main()
