#!/usr/bin/env python3
"""Dựng video hoàn chỉnh từ một lượt quay của record.mjs.

1. Ảnh chụp màn hình (CDP screencast, khung hình không đều) -> video 30 fps đúng thời gian thực.
2. Mỗi câu thoại đặt đúng mốc đã ghi lúc quay (adelay) — không cắt frame nào, nên tiếng khớp hình.
3. Nhạc nền tự hạ khi có lời (sidechain), mờ vào / mờ ra, chuẩn hoá âm lượng -16 LUFS.
4. Xuất bản chính, bản nhẹ 720p (hoặc 540x960 với bản dọc) và phụ đề .srt.

Dùng: python3 scripts/build-video.py [--vertical] [--music "music/There is Romance.mp3"] [--music-start 0]
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
import textwrap
from pathlib import Path

ROOT = Path.cwd()
NARRATION = ROOT / "demo-out" / "narration"
FPS = 30

# Fedora (ffmpeg-free) không có libx264; OpenH264 cho H.264 xem được ở mọi nơi, chỉnh chất lượng bằng bitrate.
def h264(bitrate: str) -> list[str]:
    return ["-c:v", "libopenh264", "-b:v", bitrate, "-maxrate", bitrate, "-bufsize", bitrate, "-g", str(FPS * 2)]


def run(cmd: list[str]) -> None:
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        sys.exit(f"ffmpeg failed: {' '.join(cmd[:6])}...\n{proc.stderr[-2500:]}")


def srt_time(ms: float) -> str:
    ms = max(0, int(round(ms)))
    h, ms = divmod(ms, 3_600_000)
    m, ms = divmod(ms, 60_000)
    s, ms = divmod(ms, 1000)
    return f"{h:02}:{m:02}:{s:02},{ms:03}"


def write_srt(lines: list[dict], dest: Path) -> None:
    # Mỗi câu một cue, tối đa 2 dòng x 42 ký tự; câu dài hơn thì tách theo dấu câu, chia thời gian
    # theo số ký tự.
    cues = []
    for ln in lines:
        text = ln["text"]
        parts = [text]
        if len(text) > 84:
            cut = max(text.rfind(". ", 0, len(text) // 2 + 20), text.rfind(", ", 0, len(text) // 2 + 20))
            if cut > 0:
                parts = [text[: cut + 1].strip(), text[cut + 1 :].strip()]
        start, total = ln["offsetMs"], ln["ms"]
        for p in parts:
            dur = total * len(p) / len(text)
            cues.append((start, start + dur, "\n".join(textwrap.wrap(p, 42))))
            start += dur
    dest.write_text(
        "".join(f"{i}\n{srt_time(a)} --> {srt_time(b)}\n{t}\n\n" for i, (a, b, t) in enumerate(cues, 1)),
        encoding="utf-8",
    )


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--vertical", action="store_true")
    ap.add_argument("--music", default="music/There is Romance.mp3")
    ap.add_argument("--music-start", type=float, default=0.0, help="bắt đầu nhạc từ giây thứ mấy của bài")
    ap.add_argument("--music-volume", type=float, default=0.32)
    args = ap.parse_args()

    name = "vertical" if args.vertical else "horizontal"
    rec = ROOT / "demo-out" / f"rec-{name}"
    out = ROOT / "demo-out" / "final"
    out.mkdir(parents=True, exist_ok=True)
    work = rec / "build"
    work.mkdir(exist_ok=True)

    timing = json.loads((rec / "timing.json").read_text())
    frames = json.loads((rec / "frames.json").read_text())
    t0, end = timing["t0"], timing["end"]
    total = (end - t0) / 1000

    # --- 1. video từ ảnh, giữ đúng thời gian thực ---
    frames.sort(key=lambda f: f["ts"])
    first = max((i for i, f in enumerate(frames) if f["ts"] <= t0), default=0)
    used = frames[first:]
    used = [f for f in used if f["ts"] <= end] or used[:1]
    concat = work / "frames.txt"
    with concat.open("w") as fh:
        for i, f in enumerate(used):
            start = max(f["ts"], t0)
            nxt = used[i + 1]["ts"] if i + 1 < len(used) else end
            fh.write(f"file '{(ROOT / f['file']).resolve()}'\nduration {max(nxt - start, 1) / 1000:.4f}\n")
        fh.write(f"file '{(ROOT / used[-1]['file']).resolve()}'\n")
    silent = work / "video.mp4"
    run(["ffmpeg", "-y", "-v", "error", "-f", "concat", "-safe", "0", "-i", str(concat),
         "-vf", f"fps={FPS},format=yuv420p", "-t", f"{total:.3f}",
         *h264("14M"), str(silent)])

    # --- 2 + 3. tiếng: thoại theo mốc + nhạc tự hạ ---
    lines = timing["lines"]
    inputs: list[str] = []
    for ln in lines:
        inputs += ["-i", str(NARRATION / f"{ln['id']}.mp3")]
    music_idx = len(lines)
    inputs += ["-ss", str(args.music_start), "-i", str(ROOT / args.music)]

    voice_chains = [f"[{i}]aresample=48000,adelay={ln['offsetMs']}|{ln['offsetMs']}[v{i}]" for i, ln in enumerate(lines)]
    mix_voice = "".join(f"[v{i}]" for i in range(len(lines))) + f"amix=inputs={len(lines)}:normalize=0,apad=whole_dur={total:.3f}[voice]"
    fade_out = max(total - 4, 0)
    music = (f"[{music_idx}]aresample=48000,atrim=0:{total:.3f},asetpts=PTS-STARTPTS,volume={args.music_volume},"
             f"afade=t=in:d=2.5,afade=t=out:st={fade_out:.2f}:d=4[bed]")
    graph = ";".join(voice_chains + [mix_voice, music,
        "[voice]asplit=2[voice_out][key]",
        "[bed][key]sidechaincompress=threshold=0.03:ratio=6:attack=25:release=500[ducked]",
        "[ducked][voice_out]amix=inputs=2:normalize=0,alimiter=limit=0.95,loudnorm=I=-16:TP=-1.5:LRA=11[aout]"])
    audio = work / "audio.m4a"
    run(["ffmpeg", "-y", "-v", "error", *inputs, "-filter_complex", graph, "-map", "[aout]",
         "-t", f"{total:.3f}", "-ar", "48000", "-c:a", "aac", "-b:a", "192k", str(audio)])

    # --- 4. xuất ---
    base = f"cham-mot-cham-thoi-{'9x16' if args.vertical else '16x9'}"
    final = out / f"{base}.mp4"
    run(["ffmpeg", "-y", "-v", "error", "-i", str(silent), "-i", str(audio), "-map", "0:v", "-map", "1:a",
         "-c:v", "copy", "-c:a", "copy", "-movflags", "+faststart", "-shortest", str(final)])
    small_size = "540:960" if args.vertical else "1280:720"
    small = out / f"{base}-{'540p' if args.vertical else '720p'}.mp4"
    run(["ffmpeg", "-y", "-v", "error", "-i", str(final), "-vf", f"scale={small_size}:flags=lanczos",
         *h264("3500k"), "-c:a", "aac", "-b:a", "128k",
         "-movflags", "+faststart", str(small)])
    write_srt(lines, out / f"{base}.srt")

    for f in (final, small):
        print(f"{f}  {f.stat().st_size / 1e6:.1f} MB")
    print(f"{len(lines)} câu thoại, {total:.1f}s")


if __name__ == "__main__":
    main()
