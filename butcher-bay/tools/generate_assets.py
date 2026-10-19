#!/usr/bin/env python3
"""Procedural pixel-art and SFX generator for Butcher Bay."""

from __future__ import annotations

import math
import os
import random
import struct
import wave
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SPR = ROOT / "assets" / "sprites"
AUD = ROOT / "assets" / "audio"

C = {
    "void": (0, 0, 0, 0),
    "ink": (10, 7, 8, 255),
    "bg": (16, 9, 11, 255),
    "bg2": (28, 14, 16, 255),
    "flesh": (138, 46, 44, 255),
    "flesh_hi": (176, 74, 62, 255),
    "flesh_dk": (82, 22, 26, 255),
    "meat": (118, 32, 36, 255),
    "bone": (216, 200, 168, 255),
    "bone_dk": (166, 142, 110, 255),
    "blood": (176, 10, 22, 255),
    "blood_hi": (220, 36, 40, 255),
    "blood_dk": (86, 6, 12, 255),
    "skin": (216, 190, 172, 255),
    "skin_dk": (170, 132, 116, 255),
    "hair": (38, 28, 26, 255),
    "rag": (66, 58, 54, 255),
    "rag_hi": (96, 84, 76, 255),
    "pants": (42, 38, 44, 255),
    "apron": (236, 232, 218, 255),
    "apron_stain": (186, 140, 120, 255),
    "metal": (126, 132, 136, 255),
    "metal_hi": (206, 210, 214, 255),
    "metal_dk": (52, 56, 60, 255),
    "rust": (150, 70, 36, 255),
    "eye": (228, 42, 38, 255),
    "gold": (214, 176, 64, 255),
    "gold_dk": (148, 108, 28, 255),
    "cyan": (92, 196, 188, 255),
}


def ensure_dirs() -> None:
    for p in [
        SPR / "player",
        SPR / "butcher",
        SPR / "obstacles",
        SPR / "env",
        SPR / "ui",
        AUD,
    ]:
        p.mkdir(parents=True, exist_ok=True)


def new_img(w: int, h: int) -> Image.Image:
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def px(img: Image.Image, x: int, y: int, c: tuple[int, int, int, int]) -> None:
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), c)


def rect(img: Image.Image, x: int, y: int, w: int, h: int, c) -> None:
    d = ImageDraw.Draw(img)
    d.rectangle([x, y, x + w - 1, y + h - 1], fill=c)


def oval(img: Image.Image, x: int, y: int, w: int, h: int, c) -> None:
    d = ImageDraw.Draw(img)
    d.ellipse([x, y, x + w - 1, y + h - 1], fill=c)


def outline_oval(img: Image.Image, x: int, y: int, w: int, h: int, fill, edge) -> None:
    oval(img, x, y, w, h, edge)
    oval(img, x + 1, y + 1, max(1, w - 2), max(1, h - 2), fill)


def scale_nn(img: Image.Image, k: int) -> Image.Image:
    return img.resize((img.width * k, img.height * k), Image.NEAREST)


def save(img: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path)


def draw_player(anim: str, i: int) -> Image.Image:
    img = new_img(48, 48)
    bob = [0, -1, 0, 1][i % 4]
    if anim == "jump":
        bob = [-2, -6, -5, -1][i]
    if anim == "slide":
        bob = 10
    if anim == "vent":
        bob = -12

    hx, hy = 22, 6 + bob
    if anim == "slide":
        hx, hy = 26, 18

    # shadow
    oval(img, 14, 42, 20, 5, (0, 0, 0, 70))

    # legs
    if anim == "slide":
        rect(img, 8, 30, 26, 6, C["pants"])
        rect(img, 6, 32, 8, 5, C["hair"])
        rect(img, 30, 28, 10, 5, C["pants"])
        rect(img, 38, 30, 6, 4, C["hair"])
    else:
        phase = i if anim == "run" else 0
        l1 = [6, 2, 6, 10][phase]
        l2 = [10, 6, 2, 6][phase]
        if anim == "jump":
            l1, l2 = 4, 8
        rect(img, 20, 28 + bob, 5, 10 + l1 // 3, C["pants"])
        rect(img, 26, 28 + bob, 5, 10 + l2 // 3, C["pants"])
        rect(img, 19, 36 + bob + l1 // 3, 6, 4, C["hair"])
        rect(img, 26, 36 + bob + l2 // 3, 6, 4, C["hair"])
        if anim == "run":
            # trailing foot smear
            if i % 2 == 0:
                rect(img, 16, 40 + bob, 4, 2, C["blood_dk"])

    # torso
    tx, ty = (12, 20) if anim == "slide" else (18, 16 + bob)
    tw, th = (22, 10) if anim == "slide" else (14, 14)
    rect(img, tx, ty, tw, th, C["rag"])
    rect(img, tx + 1, ty + 1, tw - 4, 3, C["rag_hi"])
    # torn hem
    px(img, tx + 2, ty + th, C["rag"])
    px(img, tx + 6, ty + th + 1, C["rag"])
    px(img, tx + tw - 3, ty + th, C["blood"])

    # arms
    if anim == "jump":
        rect(img, 14, 14 + bob, 4, 10, C["skin_dk"])
        rect(img, 32, 12 + bob, 4, 10, C["skin"])
    elif anim == "slide":
        rect(img, 32, 22, 12, 4, C["skin"])
    else:
        swing = [-3, 2, 3, -2][i]
        rect(img, 15, 18 + bob, 4, 9 + swing, C["skin_dk"])
        rect(img, 31, 18 + bob, 4, 9 - swing, C["skin"])

    # head
    outline_oval(img, hx, hy, 13, 13, C["skin"], C["hair"])
    oval(img, hx + 1, hy - 1, 13, 7, C["hair"])  # hair
    px(img, hx + 9, hy + 6, C["ink"])  # eye
    px(img, hx + 10, hy + 6, C["eye"])
    px(img, hx + 8, hy + 9, C["skin_dk"])  # mouth
    # fear sweat
    px(img, hx + 3, hy + 7, (240, 240, 240, 180))
    return img


def draw_butcher(anim: str, i: int) -> Image.Image:
    img = new_img(64, 64)
    bob = [0, -1, 0, 1][i % 4]
    if anim == "ambush":
        bob = [-8, -2, 0, 2][i]

    oval(img, 16, 56, 28, 6, (0, 0, 0, 80))

    # legs
    phase = i
    l1 = [8, 3, 8, 12][phase]
    l2 = [12, 8, 3, 8][phase]
    rect(img, 24, 38 + bob, 7, 16 + l1 // 4, C["ink"])
    rect(img, 34, 38 + bob, 7, 16 + l2 // 4, C["ink"])
    rect(img, 22, 52 + bob + l1 // 5, 9, 5, C["metal_dk"])
    rect(img, 34, 52 + bob + l2 // 5, 9, 5, C["metal_dk"])

    # bulky torso + apron
    rect(img, 18, 20 + bob, 28, 24, C["rag"])
    rect(img, 22, 24 + bob, 20, 22, C["apron"])
    rect(img, 24, 30 + bob, 8, 10, C["apron_stain"])
    rect(img, 30, 36 + bob, 10, 6, C["blood"])
    # straps
    rect(img, 24, 18 + bob, 4, 8, C["apron"])
    rect(img, 36, 18 + bob, 4, 8, C["apron"])

    # head / mask
    outline_oval(img, 24, 6 + bob, 18, 18, C["skin_dk"], C["ink"])
    rect(img, 26, 10 + bob, 14, 8, C["ink"])  # mask
    px(img, 30, 13 + bob, C["eye"])
    px(img, 37, 13 + bob, C["eye"])
    rect(img, 28, 18 + bob, 10, 3, C["blood_dk"])  # grim mouth

    # chainsaw in front hand
    saw_x = 42
    saw_y = 22 + bob + [-1, 1, -2, 2][i]
    if anim == "ambush":
        saw_x, saw_y = 38, 8 + i * 3
    rect(img, saw_x, saw_y + 6, 14, 6, C["metal_dk"])  # bar
    rect(img, saw_x + 2, saw_y + 7, 12, 4, C["metal"])
    # teeth
    for t in range(6):
        ox = (t + i) % 2
        rect(img, saw_x + 2 + t * 2, saw_y + 4 + ox, 2, 3, C["metal_hi"])
        rect(img, saw_x + 2 + t * 2, saw_y + 11 - ox, 2, 3, C["metal_hi"])
    # engine
    rect(img, saw_x - 8, saw_y + 4, 10, 10, C["rust"])
    rect(img, saw_x - 6, saw_y + 6, 6, 6, C["metal_dk"])
    px(img, saw_x - 4, saw_y + 8, C["eye"])
    # blood spray
    if i % 2 == 0:
        px(img, saw_x + 14, saw_y + 3, C["blood_hi"])
        px(img, saw_x + 16, saw_y + 8, C["blood"])
    return img


def blob(img: Image.Image, rng: random.Random, n: int, cols: list) -> None:
    for _ in range(n):
        x = rng.randint(0, img.width - 1)
        y = rng.randint(0, img.height - 1)
        r = rng.randint(2, 10)
        oval(img, x - r, y - r, r * 2, r * 2, rng.choice(cols))


def make_env() -> None:
    rng = random.Random(77)
    far = Image.new("RGBA", (256, 180), C["bg"])
    blob(far, rng, 40, [C["bg2"], C["flesh_dk"], C["ink"]])
    for x in range(0, 256, 18):
        rect(far, x + rng.randint(0, 6), 0, 3, rng.randint(20, 70), C["blood_dk"])
    save(far, SPR / "env" / "far.png")

    wall = Image.new("RGBA", (128, 128), C["flesh_dk"])
    blob(wall, rng, 28, [C["flesh"], C["meat"], C["flesh_hi"], C["blood_dk"]])
    for i in range(10):
        x = rng.randint(0, 110)
        rect(wall, x, 0, 4, rng.randint(40, 128), C["bone_dk"])
        rect(wall, x + 1, 8, 2, 20, C["bone"])
    save(wall, SPR / "env" / "wall.png")

    floor = Image.new("RGBA", (64, 32), C["ink"])
    for x in range(0, 64, 8):
        rect(floor, x, 8, 8, 24, C["bone_dk"] if (x // 8) % 2 == 0 else C["flesh_dk"])
        px(floor, x + 3, 18, C["blood"])
    rect(floor, 0, 0, 64, 8, C["blood_dk"])
    save(floor, SPR / "env" / "floor.png")

    ceil = Image.new("RGBA", (64, 40), (0, 0, 0, 0))
    rect(ceil, 0, 0, 64, 14, C["flesh_dk"])
    for x in range(4, 64, 12):
        rect(ceil, x, 10, 3, 22, C["bone"])
        rect(ceil, x - 1, 28, 5, 4, C["bone_dk"])
    save(ceil, SPR / "env" / "ceiling.png")

    drip = new_img(16, 32)
    rect(drip, 7, 0, 3, 18, C["blood"])
    oval(drip, 5, 16, 7, 10, C["blood_hi"])
    save(drip, SPR / "env" / "drip.png")


def make_obstacles() -> None:
    hook = new_img(32, 64)
    rect(hook, 14, 0, 4, 28, C["metal_dk"])
    rect(hook, 14, 0, 4, 8, C["rust"])
    oval(hook, 8, 24, 18, 22, C["metal"])
    rect(hook, 8, 30, 10, 4, (0, 0, 0, 0))
    # wipe inner to make hook C
    for y in range(30, 42):
        for x in range(12, 20):
            px(hook, x, y, (0, 0, 0, 0))
    oval(hook, 18, 40, 8, 8, C["blood"])
    save(hook, SPR / "obstacles" / "hook.png")

    for i in range(4):
        saw = new_img(48, 28)
        oval(saw, 4, 2, 40, 24, C["metal_dk"])
        oval(saw, 8, 6, 32, 16, C["metal"])
        oval(saw, 16, 10, 16, 8, C["ink"])
        for t in range(12):
            ang = (t / 12) * math.tau + i * 0.2
            cx, cy = 24, 14
            x = int(cx + math.cos(ang) * 20)
            y = int(cy + math.sin(ang) * 12)
            rect(saw, x - 1, y - 1, 3, 3, C["metal_hi"])
        rect(saw, 0, 20, 48, 6, C["rust"])
        save(saw, SPR / "obstacles" / f"saw_{i}.png")

    corpse = new_img(48, 24)
    oval(corpse, 4, 8, 16, 12, C["skin_dk"])
    rect(corpse, 16, 10, 22, 10, C["rag"])
    oval(corpse, 34, 8, 12, 10, C["skin"])
    rect(corpse, 10, 16, 28, 6, C["blood"])
    px(corpse, 40, 12, C["ink"])
    save(corpse, SPR / "obstacles" / "corpse.png")

    puddle = new_img(48, 16)
    oval(puddle, 2, 4, 44, 10, C["blood_dk"])
    oval(puddle, 8, 6, 28, 6, C["blood"])
    oval(puddle, 16, 7, 10, 4, C["blood_hi"])
    save(puddle, SPR / "obstacles" / "puddle.png")

    wall = new_img(36, 64)
    blob(wall, random.Random(3), 18, [C["flesh"], C["flesh_hi"], C["meat"], C["blood"]])
    rect(wall, 0, 0, 36, 64, C["flesh"])
    for y in range(0, 64, 8):
        oval(wall, 4, y, 28, 10, C["flesh_hi"] if y % 16 == 0 else C["meat"])
        rect(wall, 16, y + 2, 4, 8, C["blood_dk"])
    save(wall, SPR / "obstacles" / "gut_wall.png")

    trash = new_img(40, 32)
    rect(trash, 4, 10, 32, 18, C["metal_dk"])
    rect(trash, 6, 12, 28, 8, C["rust"])
    oval(trash, 10, 4, 12, 10, C["bone_dk"])
    rect(trash, 22, 6, 10, 8, C["rag"])
    px(trash, 28, 20, C["blood"])
    save(trash, SPR / "obstacles" / "trash.png")

    burst = new_img(40, 48)
    rect(burst, 8, 8, 24, 36, C["flesh_dk"])
    oval(burst, 4, 16, 12, 20, C["flesh"])
    rect(burst, 18, 0, 6, 16, C["bone"])
    oval(burst, 22, 20, 14, 16, C["blood"])
    save(burst, SPR / "obstacles" / "wall_burst.png")

    for name, col, inner in [
        ("amulet_shield", C["gold"], C["cyan"]),
        ("amulet_speed", C["gold"], C["blood_hi"]),
    ]:
        am = new_img(24, 24)
        oval(am, 2, 2, 20, 20, col)
        oval(am, 5, 5, 14, 14, C["gold_dk"])
        oval(am, 8, 8, 8, 8, inner)
        rect(am, 11, 0, 2, 6, C["bone"])
        save(am, SPR / "obstacles" / f"{name}.png")

    vent = new_img(64, 24)
    rect(vent, 0, 0, 64, 24, C["metal_dk"])
    for x in range(4, 60, 8):
        rect(vent, x, 4, 4, 16, C["ink"])
    rect(vent, 0, 0, 64, 3, C["rust"])
    save(vent, SPR / "obstacles" / "vent.png")

    squeeze = new_img(96, 80)
    rect(squeeze, 0, 0, 96, 24, C["flesh_dk"])
    rect(squeeze, 0, 56, 96, 24, C["flesh_dk"])
    blob(squeeze, random.Random(9), 12, [C["flesh"], C["meat"]])
    save(squeeze, SPR / "obstacles" / "squeeze.png")


def make_ui() -> None:
    for i in range(4):
        saw = new_img(160, 160)
        rect(saw, 0, 0, 160, 160, C["ink"])
        oval(saw, 16, 16, 128, 128, C["metal_dk"])
        oval(saw, 32, 32, 96, 96, C["metal"])
        oval(saw, 64, 64, 32, 32, C["ink"])
        for t in range(16):
            ang = (t / 16) * math.tau + i * 0.18
            x = int(80 + math.cos(ang) * 62)
            y = int(80 + math.sin(ang) * 62)
            rect(saw, x - 4, y - 4, 8, 8, C["metal_hi"])
            rect(saw, x - 2, y - 2, 4, 4, C["blood_hi"] if t % 3 == 0 else C["rust"])
        # blood splatters
        rng = random.Random(4 + i)
        blob(saw, rng, 10, [C["blood"], C["blood_dk"], C["blood_hi"]])
        save(saw, SPR / "ui" / f"saw_close_{i}.png")

    bar_bg = new_img(200, 16)
    rect(bar_bg, 0, 0, 200, 16, C["ink"])
    rect(bar_bg, 2, 2, 196, 12, C["blood_dk"])
    save(bar_bg, SPR / "ui" / "bar_bg.png")

    bar_fill = new_img(8, 12)
    rect(bar_fill, 0, 0, 8, 12, C["blood_hi"])
    save(bar_fill, SPR / "ui" / "bar_fill.png")

    dust = new_img(16, 12)
    oval(dust, 1, 3, 8, 6, (90, 70, 60, 160))
    oval(dust, 6, 2, 9, 7, (70, 50, 44, 120))
    save(dust, SPR / "ui" / "dust.png")

    streak = new_img(28, 8)
    oval(streak, 0, 1, 28, 6, C["blood"])
    oval(streak, 6, 2, 14, 3, C["blood_hi"])
    save(streak, SPR / "ui" / "blood_streak.png")

    vig = Image.new("RGBA", (256, 144), (0, 0, 0, 0))
    for y in range(144):
        for x in range(256):
            nx = (x / 255.0 - 0.5) * 2.0
            ny = (y / 143.0 - 0.5) * 2.0
            d = (nx * nx * 0.85 + ny * ny) ** 0.5
            a = int(min(210, max(0, (d - 0.52) * 300)))
            if a:
                vig.putpixel((x, y), (48, 4, 10, a))
    save(vig.resize((1280, 720), Image.BILINEAR), SPR / "ui" / "vignette.png")

    title = new_img(64, 64)
    oval(title, 4, 4, 56, 56, C["blood_dk"])
    oval(title, 12, 12, 40, 40, C["metal"])
    rect(title, 28, 8, 8, 48, C["metal_hi"])
    save(title, SPR / "ui" / "logo_saw.png")


def make_icon() -> None:
    icon = new_img(128, 128)
    rect(icon, 0, 0, 128, 128, C["ink"])
    oval(icon, 12, 12, 104, 104, C["metal_dk"])
    oval(icon, 28, 28, 72, 72, C["metal"])
    oval(icon, 54, 54, 20, 20, C["ink"])
    for t in range(12):
        ang = t / 12 * math.tau
        x = int(64 + math.cos(ang) * 48)
        y = int(64 + math.sin(ang) * 48)
        rect(icon, x - 5, y - 5, 10, 10, C["metal_hi"])
    oval(icon, 70, 40, 18, 18, C["blood_hi"])
    save(icon, ROOT / "icon.png")
    save(scale_nn(icon, 2), SPR / "ui" / "icon_512.png")


def make_svg_icon() -> None:
    svg = """<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">
<rect width="128" height="128" fill="#0a0708"/>
<circle cx="64" cy="64" r="52" fill="#34383c"/>
<circle cx="64" cy="64" r="36" fill="#7e8488"/>
<circle cx="64" cy="64" r="10" fill="#0a0708"/>
<circle cx="96" cy="40" r="10" fill="#b00a16"/>
</svg>
"""
    (ROOT / "icon.svg").write_text(svg)


def write_wav(path: Path, samples: list[float], rate: int = 22050) -> None:
    with wave.open(str(path), "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        frames = b"".join(
            struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767)) for s in samples
        )
        w.writeframes(frames)


def tone(freq: float, t: float, rate: int, amp: float = 0.4) -> float:
    return math.sin(2 * math.pi * freq * t) * amp


def make_audio() -> None:
    rate = 22050
    rng = random.Random(1)

    def noise(n: int, amp: float = 0.2) -> list[float]:
        return [rng.uniform(-amp, amp) for _ in range(n)]

    # jump
    n = int(rate * 0.18)
    jump = [
        tone(420 + i * 2.2, i / rate, rate, 0.35) * (1 - i / n) for i in range(n)
    ]
    write_wav(AUD / "sfx_jump.wav", jump, rate)

    n = int(rate * 0.2)
    slide = [
        tone(180, i / rate, rate, 0.2) * (1 - i / n) + rng.uniform(-0.08, 0.08)
        for i in range(n)
    ]
    write_wav(AUD / "sfx_slide.wav", slide, rate)

    n = int(rate * 0.25)
    hit = [rng.uniform(-0.6, 0.6) * (1 - i / n) + tone(70, i / rate, rate, 0.3) for i in range(n)]
    write_wav(AUD / "sfx_hit.wav", hit, rate)

    n = int(rate * 0.22)
    pickup = [
        tone(660 + (120 if i > n // 2 else 0), i / rate, rate, 0.28) * (1 - i / n * 0.5)
        for i in range(n)
    ]
    write_wav(AUD / "sfx_pickup.wav", pickup, rate)

    n = int(rate * 0.4)
    saw = [
        tone(90, i / rate, rate, 0.18)
        + tone(180, i / rate, rate, 0.08)
        + rng.uniform(-0.22, 0.22)
        for i in range(n)
    ]
    write_wav(AUD / "sfx_saw.wav", saw, rate)

    n = int(rate * 0.5)
    ambush = [
        tone(55, i / rate, rate, 0.45) * min(1, i / (n * 0.2)) * (1 - i / n)
        + rng.uniform(-0.15, 0.15)
        for i in range(n)
    ]
    write_wav(AUD / "sfx_ambush.wav", ambush, rate)

    n = int(rate * 0.28)
    smash = [
        rng.uniform(-0.7, 0.7) * (1 - i / n) + tone(50, i / rate, rate, 0.4)
        for i in range(n)
    ]
    write_wav(AUD / "sfx_smash.wav", smash, rate)

    n = int(rate * 0.9)
    death = [
        tone(140 - i * 0.08, i / rate, rate, 0.4) * (1 - i / n)
        + rng.uniform(-0.2, 0.2) * (1 - i / n)
        for i in range(n)
    ]
    write_wav(AUD / "sfx_death.wav", death, rate)

    n = int(rate * 0.12)
    step = [rng.uniform(-0.18, 0.18) * (1 - i / n) + tone(90, i / rate, rate, 0.08) for i in range(n)]
    write_wav(AUD / "sfx_step.wav", step, rate)

    n = int(rate * 2.0)
    drone = [
        tone(46, i / rate, rate, 0.12)
        + tone(92.5, i / rate, rate, 0.05)
        + tone(69, i / rate, rate, 0.03)
        + rng.uniform(-0.02, 0.02)
        for i in range(n)
    ]
    write_wav(AUD / "music_drone.wav", drone, rate)

    n = int(rate * 0.14)
    land = [
        rng.uniform(-0.35, 0.35) * (1 - i / n) + tone(70, i / rate, rate, 0.22) * (1 - i / n)
        for i in range(n)
    ]
    write_wav(AUD / "sfx_land.wav", land, rate)

    n = int(rate * 0.16)
    lane = [
        tone(240 + i * 1.4, i / rate, rate, 0.22) * (1 - i / n)
        + rng.uniform(-0.05, 0.05)
        for i in range(n)
    ]
    write_wav(AUD / "sfx_lane.wav", lane, rate)

    n = int(rate * 0.28)
    puddle = [
        rng.uniform(-0.28, 0.28) * (1 - i / n)
        + tone(110, i / rate, rate, 0.12) * (1 - i / n)
        for i in range(n)
    ]
    write_wav(AUD / "sfx_puddle.wav", puddle, rate)

    n = int(rate * 0.32)
    hook = [
        tone(520 - i * 0.35, i / rate, rate, 0.2) * (1 - i / n)
        + tone(780, i / rate, rate, 0.06) * (1 - i / n)
        for i in range(n)
    ]
    write_wav(AUD / "sfx_hook.wav", hook, rate)

    n = int(rate * 0.7)
    vanish = [
        tone(90 - i * 0.05, i / rate, rate, 0.28) * (1 - i / n)
        + rng.uniform(-0.06, 0.06) * (1 - i / n)
        for i in range(n)
    ]
    write_wav(AUD / "sfx_vanish.wav", vanish, rate)

    n = int(rate * 0.26)
    vent = [
        tone(310 + i * 1.8, i / rate, rate, 0.26) * (1 - i / n)
        + rng.uniform(-0.04, 0.04)
        for i in range(n)
    ]
    write_wav(AUD / "sfx_vent.wav", vent, rate)


def make_player_and_butcher() -> None:
    sliced = ROOT / "assets" / "reference" / "cut_victim.png"
    if sliced.exists():
        print("skip placeholder player/butcher; sliced skins present")
        return
    for i in range(4):
        save(scale_nn(draw_player("run", i), 2), SPR / "player" / f"run_{i}.png")
        save(scale_nn(draw_player("jump", i), 2), SPR / "player" / f"jump_{i}.png")
        save(scale_nn(draw_player("slide", i), 2), SPR / "player" / f"slide_{i}.png")
        save(scale_nn(draw_player("vent", i), 2), SPR / "player" / f"vent_{i}.png")
        save(scale_nn(draw_butcher("run", i), 2), SPR / "butcher" / f"run_{i}.png")
        save(scale_nn(draw_butcher("ambush", i), 2), SPR / "butcher" / f"ambush_{i}.png")


def main() -> None:
    ensure_dirs()
    make_player_and_butcher()
    make_env()
    make_obstacles()
    make_ui()
    make_icon()
    make_svg_icon()
    make_audio()
    print("assets generated under", ROOT)


if __name__ == "__main__":
    main()
