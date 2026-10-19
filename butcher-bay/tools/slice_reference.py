#!/usr/bin/env python3
"""Cut butcher and victim skins from the concept reference and build anim frames."""

from __future__ import annotations

from collections import deque
from pathlib import Path

from PIL import Image, ImageEnhance, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
REF_COPY = ROOT / "assets" / "reference" / "butchers_bay_concept.png"
REF_UPLOAD = Path("/home/ubuntu/.cursor/projects/workspace/assets/fcbeaaca-1e82-494f-a673-e0e1bb0eac8c.png")
OUT_P = ROOT / "assets" / "sprites" / "player"
OUT_B = ROOT / "assets" / "sprites" / "butcher"


def load_ref() -> Image.Image:
    REF_COPY.parent.mkdir(parents=True, exist_ok=True)
    src = REF_COPY if REF_COPY.exists() else REF_UPLOAD
    im = Image.open(src).convert("RGBA")
    if src != REF_COPY:
        im.save(REF_COPY)
    return im


def lumish(r: int, g: int, b: int) -> float:
    return 0.3 * r + 0.59 * g + 0.11 * b


def flood_keep(im: Image.Image, seeds: list[tuple[int, int]], keep_fn) -> Image.Image:
    w, h = im.size
    px = im.load()
    seen = [[False] * w for _ in range(h)]
    q: deque[tuple[int, int]] = deque()
    for sx, sy in seeds:
        if 0 <= sx < w and 0 <= sy < h:
            q.append((sx, sy))
            seen[sy][sx] = True
    keep: set[tuple[int, int]] = set()
    while q:
        x, y = q.popleft()
        r, g, b, a = px[x, y]
        if a == 0 or not keep_fn(x, y, r, g, b, a):
            continue
        keep.add((x, y))
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < w and 0 <= ny < h and not seen[ny][nx]:
                seen[ny][nx] = True
                q.append((nx, ny))
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    op = out.load()
    for x, y in keep:
        op[x, y] = px[x, y]
    return out


def dilate_alpha(im: Image.Image, rad: int = 1) -> Image.Image:
    a = im.getchannel("A").filter(ImageFilter.MaxFilter(rad * 2 + 1))
    out = im.copy()
    out.putalpha(a)
    src = im.load()
    dst = out.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            if src[x, y][3] > 0:
                dst[x, y] = src[x, y]
                continue
            if dst[x, y][3] == 0:
                continue
            cols: list[tuple[int, int, int]] = []
            for dy in range(-rad, rad + 1):
                for dx in range(-rad, rad + 1):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and src[nx, ny][3] > 0:
                        cols.append(src[nx, ny][:3])
            if cols:
                dst[x, y] = (
                    sum(c[0] for c in cols) // len(cols),
                    sum(c[1] for c in cols) // len(cols),
                    sum(c[2] for c in cols) // len(cols),
                    230,
                )
    return out


def trim(im: Image.Image, pad: int = 2) -> Image.Image:
    bbox = im.getbbox()
    if not bbox:
        return im
    l, t, r, b = bbox
    l = max(0, l - pad)
    t = max(0, t - pad)
    r = min(im.width, r + pad)
    b = min(im.height, b + pad)
    return im.crop((l, t, r, b))


def place(im: Image.Image, canvas: tuple[int, int], feet_y: int | None = None) -> Image.Image:
    out = Image.new("RGBA", canvas, (0, 0, 0, 0))
    cw, ch = canvas
    if feet_y is None:
        feet_y = ch - 2
    x = (cw - im.width) // 2
    y = feet_y - im.height
    out.paste(im, (x, y), im)
    return out


def largest_blob(im: Image.Image) -> Image.Image:
    w, h = im.size
    px = im.load()
    seen = [[False] * w for _ in range(h)]
    best: list[tuple[int, int]] = []
    for y in range(h):
        for x in range(w):
            if seen[y][x] or px[x, y][3] == 0:
                continue
            blob: list[tuple[int, int]] = []
            q = deque([(x, y)])
            seen[y][x] = True
            while q:
                cx, cy = q.popleft()
                blob.append((cx, cy))
                for nx, ny in ((cx - 1, cy), (cx + 1, cy), (cx, cy - 1), (cx, cy + 1)):
                    if 0 <= nx < w and 0 <= ny < h and not seen[ny][nx] and px[nx, ny][3] > 0:
                        seen[ny][nx] = True
                        q.append((nx, ny))
            if len(blob) > len(best):
                best = blob
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    op = out.load()
    for x, y in best:
        op[x, y] = px[x, y]
    return out


def fill_holes(im: Image.Image) -> Image.Image:
    """Fill enclosed transparent pockets with nearby figure color."""
    w, h = im.size
    px = im.load()
    exterior = [[False] * w for _ in range(h)]
    q: deque[tuple[int, int]] = deque()

    def push(x: int, y: int) -> None:
        if 0 <= x < w and 0 <= y < h and not exterior[y][x] and px[x, y][3] == 0:
            exterior[y][x] = True
            q.append((x, y))

    for x in range(w):
        push(x, 0)
        push(x, h - 1)
    for y in range(h):
        push(0, y)
        push(w - 1, y)
    while q:
        x, y = q.popleft()
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            push(nx, ny)

    out = im.copy()
    op = out.load()
    for y in range(h):
        for x in range(w):
            if px[x, y][3] > 0 or exterior[y][x]:
                continue
            cols: list[tuple[int, int, int, int]] = []
            for rad in range(1, 4):
                for dx in range(-rad, rad + 1):
                    for dy in range(-rad, rad + 1):
                        nx, ny = x + dx, y + dy
                        if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] > 0:
                            cols.append(px[nx, ny])
                if cols:
                    break
            if cols:
                op[x, y] = (
                    sum(c[0] for c in cols) // len(cols),
                    sum(c[1] for c in cols) // len(cols),
                    sum(c[2] for c in cols) // len(cols),
                    sum(c[3] for c in cols) // len(cols),
                )
    return out


def add_rim(im: Image.Image, color: tuple[int, int, int, int]) -> Image.Image:
    w, h = im.size
    src = im.load()
    rim = Image.new("RGBA", (w + 2, h + 2), (0, 0, 0, 0))
    rp = rim.load()
    for y in range(h):
        for x in range(w):
            if src[x, y][3] == 0:
                continue
            for nx, ny in ((x, y - 1), (x, y + 1), (x - 1, y), (x + 1, y)):
                if not (0 <= nx < w and 0 <= ny < h) or src[nx, ny][3] == 0:
                    rp[x + 1 + (nx - x), y + 1 + (ny - y)] = color
    rim.paste(im, (1, 1), im)
    return rim


def punch_up(im: Image.Image) -> Image.Image:
    rgb = im.convert("RGB")
    rgb = ImageEnhance.Contrast(rgb).enhance(1.12)
    rgb = ImageEnhance.Color(rgb).enhance(1.08)
    out = rgb.convert("RGBA")
    out.putalpha(im.getchannel("A"))
    return out


def extract_butcher(src: Image.Image) -> Image.Image:
    crop = src.crop((22, 178, 158, 372))

    def keep(_x, _y, r, g, b, _a):
        lum = lumish(r, g, b)
        if lum <= 32:
            return True
        if 70 < r < 160 and 35 < g < 100 and b < 80 and r > b + 20:
            return True
        if b > 110 and b > r + 20 and g > 80:
            return True
        return False

    cut = flood_keep(crop, [(78, 128), (80, 95), (84, 48), (70, 40), (92, 36), (70, 170)], keep)
    cut = largest_blob(cut)
    cut = fill_holes(cut)
    cut = dilate_alpha(cut, 1)
    cut = add_rim(trim(cut, 2), (92, 18, 16, 230))
    return punch_up(trim(cut, 1))


def extract_victim(src: Image.Image) -> Image.Image:
    # Hairline crop: hanging carcasses stay above the frame.
    crop = src.crop((200, 286, 322, 400)).copy()
    px = crop.load()
    w, h = crop.size
    for y in range(0, 7):
        for x in range(w):
            if x < 68 or x > 100:
                px[x, y] = (0, 0, 0, 0)

    def in_body(x: int, y: int) -> bool:
        if 68 <= x <= 102 and 0 <= y <= 28:
            return True
        if 52 <= x <= 98 and 20 <= y <= 88:
            return True
        if 88 <= x <= 128 and 14 <= y <= 42:
            return True
        if 0 <= x <= 58 and 42 <= y <= 78:
            return True
        if 4 <= x <= 58 and 70 <= y <= 100:
            return True
        if 62 <= x <= 112 and 78 <= y <= 114:
            return True
        return False

    def keep(x, y, r, g, b, _a):
        if not in_body(x, y):
            return False
        lum = lumish(r, g, b)
        if lum <= 42 and max(r, g, b) < 62:
            return True
        if r > 112 and r > b + 6 and 65 < g < 205 and b < 185 and r > g - 18:
            return True
        if lum > 148 and r > 130 and g > 118 and abs(r - g) < 48 and b <= r + 8:
            return True
        if r > 110 and g < 100 and b < 100 and r > g + 20:
            return True
        if lum < 70 and r >= g - 8 and g >= b - 12 and max(r, g, b) < 100:
            return True
        return False

    seeds = [
        (78, 10),
        (74, 24),
        (70, 42),
        (68, 58),
        (104, 22),
        (94, 24),
        (16, 64),
        (30, 56),
        (24, 76),
        (80, 96),
        (44, 72),
        (86, 32),
        (60, 50),
    ]
    cut = flood_keep(crop, seeds, keep)
    cut = largest_blob(cut)
    cut = fill_holes(cut)
    cut = dilate_alpha(cut, 1)
    cut = add_rim(trim(cut, 2), (28, 16, 12, 230))
    return punch_up(trim(cut, 1))


def transform(im: Image.Image, dy: int = 0, rot: float = 0.0, scale: float = 1.0, squash_y: float = 1.0) -> Image.Image:
    work = im
    if scale != 1.0 or squash_y != 1.0:
        nw = max(1, int(work.width * scale))
        nh = max(1, int(work.height * scale * squash_y))
        work = work.resize((nw, nh), Image.Resampling.LANCZOS)
    if rot != 0.0:
        work = work.rotate(rot, resample=Image.Resampling.BICUBIC, expand=True)
    if dy:
        shifted = Image.new("RGBA", (work.width, work.height + abs(dy) + 4), (0, 0, 0, 0))
        shifted.paste(work, (0, max(0, -dy)), work)
        work = shifted
    return work


def fit_canvas(im: Image.Image, size: tuple[int, int], bottom: int = 4) -> Image.Image:
    cw, ch = size
    max_h = ch - bottom - 4
    max_w = cw - 6
    s = min(max_w / im.width, max_h / im.height)
    nw, nh = max(1, int(im.width * s)), max(1, int(im.height * s))
    scaled = im.resize((nw, nh), Image.Resampling.LANCZOS)
    return place(scaled, size, feet_y=ch - bottom)


def victim_frames(cut: Image.Image) -> dict[str, list[Image.Image]]:
    canvas = (96, 128)
    base = cut
    run = [
        fit_canvas(transform(base, dy=0, rot=-1.2, scale=1.0), canvas),
        fit_canvas(transform(base, dy=-4, rot=1.5, scale=1.02, squash_y=0.97), canvas),
        fit_canvas(transform(base, dy=-1, rot=-0.6, scale=1.0), canvas),
        fit_canvas(transform(base, dy=-5, rot=2.2, scale=1.01, squash_y=0.96), canvas),
    ]
    jump = [
        fit_canvas(transform(base, dy=-2, rot=-6, squash_y=0.92), canvas),
        fit_canvas(transform(base, dy=-10, rot=-2, scale=1.04, squash_y=0.88), canvas),
        fit_canvas(transform(base, dy=-12, rot=3, scale=1.02, squash_y=0.9), canvas),
        fit_canvas(transform(base, dy=-4, rot=8, squash_y=0.94), canvas),
    ]
    slide = [
        fit_canvas(transform(base, rot=72, scale=1.05, squash_y=0.85), canvas, bottom=10),
        fit_canvas(transform(base, rot=78, scale=1.06, squash_y=0.82), canvas, bottom=12),
        fit_canvas(transform(base, rot=74, scale=1.05, squash_y=0.84), canvas, bottom=10),
        fit_canvas(transform(base, rot=68, scale=1.04, squash_y=0.86), canvas, bottom=8),
    ]
    vent = [
        fit_canvas(transform(base, dy=-14, rot=-4, squash_y=0.72), canvas),
        fit_canvas(transform(base, dy=-16, rot=0, squash_y=0.68), canvas),
        fit_canvas(transform(base, dy=-15, rot=3, squash_y=0.7), canvas),
        fit_canvas(transform(base, dy=-13, rot=-2, squash_y=0.74), canvas),
    ]
    return {"run": run, "jump": jump, "slide": slide, "vent": vent}


def butcher_frames(cut: Image.Image) -> dict[str, list[Image.Image]]:
    canvas = (128, 160)
    run = [
        fit_canvas(transform(cut, dy=0, rot=-2), canvas),
        fit_canvas(transform(cut, dy=-3, rot=3, scale=1.02), canvas),
        fit_canvas(transform(cut, dy=0, rot=-1), canvas),
        fit_canvas(transform(cut, dy=-4, rot=4, scale=1.03), canvas),
    ]
    ambush = [
        fit_canvas(transform(cut, dy=-8, rot=-12, scale=1.12), canvas),
        fit_canvas(transform(cut, dy=-4, rot=8, scale=1.18), canvas),
        fit_canvas(transform(cut, dy=0, rot=16, scale=1.2), canvas),
        fit_canvas(transform(cut, dy=2, rot=10, scale=1.14), canvas),
    ]
    return {"run": run, "ambush": ambush}


def save_frames(folder: Path, frames: dict[str, list[Image.Image]]) -> None:
    folder.mkdir(parents=True, exist_ok=True)
    for anim, imgs in frames.items():
        for i, im in enumerate(imgs):
            im.save(folder / f"{anim}_{i}.png")


def main() -> None:
    src = load_ref()
    butcher = extract_butcher(src)
    victim = extract_victim(src)
    (ROOT / "assets" / "reference").mkdir(parents=True, exist_ok=True)
    butcher.save(ROOT / "assets" / "reference" / "cut_butcher.png")
    victim.save(ROOT / "assets" / "reference" / "cut_victim.png")
    save_frames(OUT_P, victim_frames(victim))
    save_frames(OUT_B, butcher_frames(butcher))
    print("sliced", butcher.size, victim.size)


if __name__ == "__main__":
    main()
