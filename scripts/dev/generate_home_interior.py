#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[2]
OUT_PATH = ROOT / "assets/generated/maps/home/map_home_interior_bg_v001.png"


def load_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = []
    if bold:
        candidates.extend(
            [
                "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
                "/usr/share/fonts/truetype/liberation2/LiberationSans-Bold.ttf",
            ]
        )
    candidates.extend(
        [
            "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
            "/usr/share/fonts/truetype/liberation2/LiberationSans-Regular.ttf",
        ]
    )
    for path in candidates:
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


FONT_24 = load_font(24)
FONT_30 = load_font(30, bold=True)


def rounded_box(
    draw: ImageDraw.ImageDraw,
    box: tuple[int, int, int, int],
    fill: str,
    outline: str,
    radius: int = 24,
    width: int = 4,
) -> None:
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def draw_label(draw: ImageDraw.ImageDraw, xy: tuple[int, int], text: str) -> None:
    x, y = xy
    bbox = draw.textbbox((0, 0), text, font=FONT_24)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    rounded_box(draw, (x, y, x + tw + 28, y + th + 18), "#fff7dc", "#c9954a", 14, 3)
    draw.text((x + 14, y + 7), text, font=FONT_24, fill="#7a4d2d")


def main() -> None:
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    image = Image.new("RGB", (1280, 720), "#f7e8cf")
    draw = ImageDraw.Draw(image)

    # Back wall and floor.
    draw.rectangle((0, 0, 1280, 470), fill="#f7d9c4")
    draw.rectangle((0, 470, 1280, 720), fill="#d9c08b")
    for x in range(-80, 1280, 120):
        draw.line((x, 470, x + 210, 720), fill="#caa775", width=3)
    for y in range(520, 720, 52):
        draw.line((0, y, 1280, y), fill="#caa775", width=2)

    # Warm wall bands.
    draw.rectangle((0, 0, 1280, 40), fill="#f1c5a8")
    draw.rectangle((0, 446, 1280, 474), fill="#b8875d")

    # Window with outdoor hint.
    rounded_box(draw, (835, 76, 1168, 332), "#bfe2f7", "#926c49", 24, 10)
    draw.rectangle((996, 84, 1008, 324), fill="#926c49")
    draw.rectangle((844, 196, 1158, 208), fill="#926c49")
    draw.ellipse((870, 145, 970, 245), fill="#ffe08a", outline="#e2b85d", width=4)
    draw.polygon([(835, 332), (1010, 240), (1168, 332)], fill="#94c986")
    draw_label(draw, (927, 338), "sunny window")

    # Home door and trip corner.
    rounded_box(draw, (70, 210, 275, 612), "#d69b62", "#9c7042", 30, 6)
    rounded_box(draw, (112, 275, 232, 612), "#f3d79b", "#9c7042", 18, 5)
    draw.ellipse((205, 430, 220, 445), fill="#8c5b35")
    rounded_box(draw, (42, 618, 312, 690), "#bfe0c6", "#6f9c72", 28, 5)
    draw_label(draw, (78, 150), "home")

    # Pet corner left, leaving current runtime pet node room to sit on top.
    rounded_box(draw, (138, 420, 452, 610), "#cfe7d0", "#78a572", 30, 5)
    rounded_box(draw, (168, 454, 328, 560), "#fff6dc", "#c99952", 24, 5)
    draw.ellipse((198, 493, 298, 548), fill="#f2a65d", outline="#b66f3d", width=5)
    draw.polygon([(215, 500), (238, 455), (254, 506)], fill="#d88148")
    draw.polygon([(270, 503), (292, 458), (305, 508)], fill="#d88148")
    rounded_box(draw, (335, 514, 416, 552), "#77bdd2", "#5d8da0", 18, 4)
    draw_label(draw, (173, 626), "pet corner")

    # Welcome box area.
    rounded_box(draw, (505, 414, 735, 608), "#f4c76c", "#b77b36", 26, 6)
    draw.polygon([(495, 424), (620, 330), (746, 424)], fill="#cf775b", outline="#a85642")
    rounded_box(draw, (560, 455, 680, 535), "#fff7e1", "#b77b36", 18, 5)
    draw.text((589, 470), "A", font=FONT_30, fill="#d65d4f")
    draw.ellipse((626, 480, 666, 520), fill="#e85f54", outline="#9b4038", width=3)
    draw_label(draw, (526, 626), "Welcome Box")

    # Sofa and reading/play area.
    rounded_box(draw, (792, 424, 1160, 604), "#bf8dc4", "#866091", 32, 6)
    rounded_box(draw, (820, 368, 1124, 472), "#d7a8da", "#866091", 28, 6)
    rounded_box(draw, (830, 554, 1076, 642), "#b88955", "#805a38", 18, 5)
    rounded_box(draw, (865, 516, 1015, 570), "#fff0b8", "#c68a46", 14, 4)
    draw.line((940, 522, 940, 562), fill="#c68a46", width=3)
    draw_label(draw, (845, 650), "read and play")

    # School bag and outfit cue.
    rounded_box(draw, (1125, 505, 1215, 625), "#78a5d4", "#4f739c", 18, 5)
    rounded_box(draw, (1146, 475, 1194, 530), "#78a5d4", "#4f739c", 20, 5)
    rounded_box(draw, (1082, 612, 1242, 676), "#fff1c7", "#c9954a", 18, 4)
    draw.text((1112, 629), "trip bag", font=FONT_24, fill="#7a4d2d")

    # Soft overhead lights and open walking center.
    draw.ellipse((446, 58, 548, 120), fill="#ffe7a7", outline="#d2ab5f", width=4)
    draw.line((497, 0, 497, 58), fill="#b8875d", width=4)
    draw.ellipse((650, 70, 750, 132), fill="#ffe7a7", outline="#d2ab5f", width=4)
    draw.line((700, 0, 700, 70), fill="#b8875d", width=4)
    rounded_box(draw, (470, 500, 790, 700), "#e6cf9a", "#d0ad78", 38, 4)

    image.save(OUT_PATH)
    print(OUT_PATH)


if __name__ == "__main__":
    main()
