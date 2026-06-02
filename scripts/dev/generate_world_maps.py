#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path
from typing import Iterable

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[2]
HOTSPOT_PATH = ROOT / "data/maps/sunshine_world_hotspots_v001.json"
OUT_DIR = ROOT / "assets/generated/maps/world"
OVERVIEW_PATH = OUT_DIR / "map_sunshine_world_overview_v001.png"
AZ_LABEL_PATH = OUT_DIR / "map_sunshine_world_az_label_v001.png"
AZ_SHOWCASE_PATH = OUT_DIR / "map_sunshine_world_az_label_showcase_v001.png"

STRONG_ANCHORS = {
    "anchor_a_apple",
    "anchor_c_clock",
    "anchor_e_elephant",
    "anchor_g_gate",
    "anchor_k_kite",
    "anchor_l_lion",
    "anchor_s_sun",
    "anchor_t_taxi",
    "anchor_w_watch",
    "anchor_u_umbrella",
}

PLACE_DRAW_ORDER = [
    "home",
    "sunshine_school",
    "classroom",
    "library",
    "music_room",
    "art_room",
    "canteen",
    "playground",
    "post_office",
    "bus_station",
    "bookshop",
    "park",
    "restaurant",
    "hospital",
    "cinema",
    "supermarket",
    "pet_shop",
    "clothes_shop",
    "general_store",
    "railway_station",
    "airport",
]

PLACE_COLORS = {
    "sunshine_school": ("#f8efc9", "#b57f2f"),
    "classroom": ("#f8d394", "#b97d32"),
    "library": ("#f6d39a", "#b97d32"),
    "music_room": ("#ffd7b8", "#bf8246"),
    "art_room": ("#ffd6ef", "#ba6f98"),
    "canteen": ("#f9df96", "#bf9549"),
    "playground": ("#80c96b", "#4b9a4f"),
    "home": ("#f5d1a0", "#b98241"),
    "post_office": ("#f0c09d", "#bf855b"),
    "hospital": ("#dfbfd1", "#a86f8c"),
    "supermarket": ("#ffe58d", "#cca440"),
    "pet_shop": ("#bfe7cf", "#5fa476"),
    "clothes_shop": ("#f6c0d8", "#b76f95"),
    "general_store": ("#d9c9f2", "#9074bf"),
    "bookshop": ("#efc88e", "#b07d3d"),
    "restaurant": ("#fab77b", "#b87e3a"),
    "park": ("#8fcb89", "#579457"),
    "cinema": ("#948bd1", "#695ba3"),
    "bus_station": ("#aab5d1", "#667490"),
    "railway_station": ("#aeb7d3", "#6a7590"),
    "airport": ("#b4c7df", "#6e87a7"),
}


def load_data() -> dict:
    return json.loads(HOTSPOT_PATH.read_text(encoding="utf-8"))


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


FONT_18 = load_font(18)
FONT_22 = load_font(22)
FONT_26 = load_font(26, bold=True)
FONT_30 = load_font(30, bold=True)
FONT_36 = load_font(36, bold=True)
FONT_44 = load_font(44, bold=True)


def rect_of(hotspot: dict) -> tuple[int, int, int, int]:
    r = hotspot["rect"]
    return int(r["x"]), int(r["y"]), int(r["w"]), int(r["h"])


def center_of(hotspot: dict) -> tuple[int, int]:
    x, y, w, h = rect_of(hotspot)
    return x + w // 2, y + h // 2


def rounded_box(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], fill: str, outline: str, radius: int = 24, width: int = 4) -> None:
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def draw_label(draw: ImageDraw.ImageDraw, xy: tuple[int, int], text: str, font: ImageFont.ImageFont, fill: str = "#ffffff", outline: str = "#5b7db2", text_fill: str = "#355785", padding: tuple[int, int] = (14, 8), radius: int = 15) -> tuple[int, int, int, int]:
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    x, y = xy
    box = (x, y, x + tw + padding[0] * 2, y + th + padding[1] * 2)
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=4)
    draw.text((x + padding[0], y + padding[1] - 2), text, font=font, fill=text_fill)
    return box


def fit_label(draw: ImageDraw.ImageDraw, rect: tuple[int, int, int, int], text: str, preferred_font: ImageFont.ImageFont, inside_top: bool = True) -> None:
    x, y, w, h = rect
    font = preferred_font
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    if tw > w - 18:
        font = FONT_22 if preferred_font != FONT_22 else preferred_font
        bbox = draw.textbbox((0, 0), text, font=font)
        tw = bbox[2] - bbox[0]
    lx = x + max(8, (w - tw) // 2)
    ly = y + 8 if inside_top else y + h - (bbox[3] - bbox[1]) - 8
    draw_label(draw, (lx - 12, ly - 8), text, font)


def place_map(data: dict) -> dict[str, dict]:
    return {hotspot["id"]: hotspot for hotspot in data["hotspots"]}


def anchor_list(data: dict) -> list[dict]:
    return [hotspot for hotspot in data["hotspots"] if hotspot.get("kind") == "memory_anchor"]


def place_list(data: dict) -> list[dict]:
    places = [hotspot for hotspot in data["hotspots"] if hotspot.get("kind") == "place"]
    place_ids = {p["id"]: p for p in places}
    ordered = [place_ids[pid] for pid in PLACE_DRAW_ORDER if pid in place_ids]
    remaining = [p for p in places if p["id"] not in PLACE_DRAW_ORDER]
    return ordered + remaining


def draw_background(draw: ImageDraw.ImageDraw, width: int, height: int) -> None:
    draw.rectangle((0, 0, width, height * 0.54), fill="#b8d5ee")
    draw.rectangle((0, int(height * 0.54), width, height), fill="#cfe5c3")
    draw.rectangle((0, int(height * 0.63), width, height), fill="#c7dfbd")


def draw_roads(draw: ImageDraw.ImageDraw, places: dict[str, dict]) -> None:
    road_fill = "#ead4a3"
    home = places["home"]
    school = places["sunshine_school"]
    bus_station = places["bus_station"]
    supermarket = places["supermarket"]
    pet_shop = places["pet_shop"]
    general_store = places.get("general_store")
    park = places["park"]
    railway = places["railway_station"]

    hx, hy, hw, hh = rect_of(home)
    sx, sy, sw, sh = rect_of(school)
    bx, by, bw, bh = rect_of(bus_station)
    smx, smy, smw, smh = rect_of(supermarket)
    ptx, pty, ptw, pth = rect_of(pet_shop)
    gsx, gsy, _, _ = rect_of(general_store) if general_store else (ptx, pty, 0, 0)
    px, py, pw, ph = rect_of(park)
    rx, ry, rw, rh = rect_of(railway)

    rounded_box(draw, (0, 710, 1120, 835), road_fill, road_fill, radius=36, width=1)
    rounded_box(draw, (230, hy + hh - 10, 500, 790), road_fill, road_fill, radius=30, width=1)
    rounded_box(draw, (sx + 80, 790, sx + 180, sy + sh + 90), road_fill, road_fill, radius=28, width=1)
    rounded_box(draw, (260, 780, 360, by + 240), road_fill, road_fill, radius=28, width=1)
    rounded_box(draw, (px + pw // 2 - 65, 790, px + pw // 2 + 65, 1435), road_fill, road_fill, radius=34, width=1)
    rounded_box(draw, (rx + rw // 2 - 70, 820, rx + rw // 2 + 70, 1435), road_fill, road_fill, radius=34, width=1)
    rounded_box(draw, (smx + 70, 790, smx + 190, smy + 80), road_fill, road_fill, radius=30, width=1)
    rounded_box(draw, (smx + smw - 10, pty + 65, ptx + 35, pty + 130), road_fill, road_fill, radius=24, width=1)
    if general_store:
        rounded_box(draw, (ptx + ptw - 10, gsy + 65, gsx + 35, gsy + 130), road_fill, road_fill, radius=24, width=1)


def draw_home(draw: ImageDraw.ImageDraw, hotspot: dict) -> None:
    x, y, w, h = rect_of(hotspot)
    roof = [(x + 30, y - 10), (x + w // 2, y - 150), (x + w - 30, y - 10)]
    draw.polygon(roof, fill="#cf775b", outline="#b6614a")
    rounded_box(draw, (x, y, x + w, y + h), "#f5d1a0", "#b98241", radius=32)
    rounded_box(draw, (x + 110, y + 95, x + 210, y + h - 10), "#f8f0da", "#b39256", radius=16)
    rounded_box(draw, (x + w - 210, y + 95, x + w - 110, y + h - 10), "#f8f0da", "#b39256", radius=16)
    fit_label(draw, (x + 75, y - 95, w - 150, 40), "home", FONT_36)


def draw_school(draw: ImageDraw.ImageDraw, places: dict[str, dict], anchors: dict[str, dict]) -> None:
    school = places["sunshine_school"]
    x, y, w, h = rect_of(school)
    roof = [(x + 230, y - 10), (x + w // 2, y - 170), (x + w - 230, y - 10)]
    draw.polygon(roof, fill="#cf775b", outline="#b6614a")
    rounded_box(draw, (x, y, x + w, y + h), "#f8efc9", "#b57f2f", radius=34)
    clock = anchors.get("anchor_c_clock")
    if clock:
        cx, cy, cw, ch = rect_of(clock)
        rounded_box(draw, (cx, cy + 40, cx + cw, cy + ch), "#6b92cf", "#4c6ea9", radius=18)
        draw.ellipse((cx + 28, cy + 58, cx + 118, cy + 148), fill="#fffef7", outline="#7f7f7f", width=4)
    apple = anchors.get("anchor_a_apple")
    if apple:
        ax, ay, aw, ah = rect_of(apple)
        draw.ellipse((ax, ay, ax + aw, ay + ah), fill="#eb4242", outline="#ae2b2b", width=5)
        draw.polygon([(ax + aw // 2, ay - 16), (ax + aw // 2 + 55, ay - 55), (ax + aw // 2 + 10, ay - 6)], fill="#44b65d")
    fit_label(draw, (x + 220, max(16, y - 120), 0, 0), "Sunshine School", FONT_44)


def draw_standard_place(draw: ImageDraw.ImageDraw, hotspot: dict) -> None:
    x, y, w, h = rect_of(hotspot)
    place_id = hotspot["id"]
    fill, outline = PLACE_COLORS.get(place_id, ("#e2d7c0", "#9a8a64"))
    radius = 26
    if place_id in {"bus_station", "railway_station", "airport"}:
        radius = 22
    rounded_box(draw, (x, y, x + w, y + h), fill, outline, radius=radius)

    if place_id == "playground":
        draw.rounded_rectangle((x + 28, y + 28, x + w - 28, y + h - 28), radius=26, outline="#ff7442", width=28)
    elif place_id == "music_room":
        draw.ellipse((x + 28, y + 18, x + 82, y + 72), fill="#7da3db", outline="#4c6ea9", width=4)
        draw.line((x + 58, y + 48, x + 58, y + h - 18), fill="#4c6ea9", width=5)
        draw.line((x + 58, y + h - 18, x + 105, y + h - 42), fill="#4c6ea9", width=5)
    elif place_id == "art_room":
        draw.polygon(
            [(x + 26, y + h - 28), (x + 48, y + 20), (x + 92, y + h - 28)],
            fill="#ff98b9",
            outline="#b85d84",
        )
        draw.ellipse((x + 86, y + h - 48, x + 120, y + h - 14), fill="#8dc37e", outline="#5b9155")
    elif place_id == "canteen":
        draw.rectangle((x + 36, y + 26, x + w - 36, y + 58), fill="#ffffff", outline="#c38a42", width=3)
        draw.rectangle((x + 50, y + 66, x + w - 50, y + 82), fill="#fff2a8", outline="#d0a948", width=2)
    elif place_id == "airport":
        draw.rectangle((x + 42, y + 50, x + w - 42, y + h - 40), fill="#b8cae4", outline="#6e87a7", width=4)
    elif place_id == "railway_station":
        draw.ellipse((x + 70, y - 55, x + 210, y + 90), fill="#efe8d5", outline="#b89c62", width=4)
    elif place_id == "pet_shop":
        draw.ellipse((x + 52, y + 46, x + 102, y + 96), fill="#f7f1d6", outline="#5fa476", width=4)
        draw.ellipse((x + 120, y + 45, x + 174, y + 99), fill="#f2a3a0", outline="#b96d68", width=4)
        draw.arc((x + 72, y + 94, x + 154, y + 162), 200, 340, fill="#5fa476", width=5)
    elif place_id == "clothes_shop":
        draw.polygon(
            [(x + 70, y + 42), (x + 122, y + 20), (x + 174, y + 42), (x + 154, y + h - 30), (x + 90, y + h - 30)],
            fill="#fff0f7",
            outline="#b76f95",
        )
        draw.rectangle((x + 86, y + 78, x + 158, y + h - 38), fill="#f48db8", outline="#b76f95", width=4)
    elif place_id == "general_store":
        draw.polygon(
            [(x + 58, y + h - 44), (x + 120, y + 34), (x + 182, y + h - 44)],
            fill="#fff6c8",
            outline="#9074bf",
        )
        draw.rounded_rectangle((x + 55, y + h - 58, x + 185, y + h - 28), radius=14, fill="#c6b1e8", outline="#9074bf", width=4)
        draw.ellipse((x + 52, y + 34, x + 90, y + 72), fill="#f7d458", outline="#9074bf", width=3)
    fit_label(draw, (x + 20, y - 54, 0, 0), hotspot["label"], FONT_26)


def draw_anchor_marker(draw: ImageDraw.ImageDraw, hotspot: dict, style: str) -> None:
    x, y, w, h = rect_of(hotspot)
    cx, cy = x + w // 2, y + h // 2
    if style == "overview":
        label = hotspot["label"]
        if hotspot["id"] in {"anchor_a_apple", "anchor_c_clock", "anchor_e_elephant", "anchor_k_kite", "anchor_s_sun", "anchor_w_watch", "anchor_u_umbrella", "anchor_d_dog"}:
            lx = x + max(0, (w - 130) // 2)
            ly = y - 42
            draw_label(draw, (lx, ly), label, FONT_22)
    elif style == "engineering":
        draw.ellipse((cx - 8, cy - 8, cx + 8, cy + 8), fill="#ffffff", outline="#5677a8", width=3)
    elif style == "showcase":
        if hotspot["id"] in STRONG_ANCHORS:
            draw.ellipse((cx - 14, cy - 14, cx + 14, cy + 14), outline="#f6c847", width=5)


def draw_overview(data: dict) -> Image.Image:
    width = int(data["canvas_size"]["width"])
    height = int(data["canvas_size"]["height"])
    image = Image.new("RGBA", (width, height), "#ffffff")
    draw = ImageDraw.Draw(image)
    places = place_map(data)
    anchors = {a["id"]: a for a in anchor_list(data)}

    draw_background(draw, width, height)
    draw_roads(draw, places)
    draw_home(draw, places["home"])
    draw_school(draw, places, anchors)

    for hotspot in place_list(data):
        if hotspot["id"] in {"sunshine_school", "home"}:
            continue
        draw_standard_place(draw, hotspot)

    for hotspot in anchor_list(data):
        draw_anchor_marker(draw, hotspot, "overview")

    return image


def callout_positions(data: dict) -> dict[str, tuple[int, int]]:
    positions = {
        "anchor_a_apple": (1420, 420),
        "anchor_c_clock": (1390, 150),
        "anchor_d_dog": (640, 590),
        "anchor_e_elephant": (1605, 560),
        "anchor_k_kite": (1310, 70),
        "anchor_r_robot": (1660, 470),
        "anchor_b_bear": (655, 960),
        "anchor_l_lion": (910, 775),
        "anchor_f_fox": (930, 1010),
        "anchor_g_gate": (20, 730),
        "anchor_h_hat": (150, 1295),
        "anchor_i_ice_cream": (1110, 975),
        "anchor_j_jacket": (360, 1315),
        "anchor_m_monkey": (1095, 735),
        "anchor_o_orange": (1625, 1010),
        "anchor_p_panda": (855, 915),
        "anchor_q_queen": (2150, 1035),
        "anchor_v_violin": (2345, 1010),
        "anchor_n_net": (560, 1230),
        "anchor_s_sun": (835, 930),
        "anchor_t_taxi": (380, 990),
        "anchor_w_watch": (1970, 1215),
        "anchor_x_x_mark_box": (1970, 470),
        "anchor_u_umbrella": (2160, 1265),
        "anchor_z_zebra": (1505, 1015),
        "anchor_y_yo_yo": (275, 305),
    }
    return positions


def draw_engineering_overlay(base: Image.Image, data: dict) -> Image.Image:
    image = base.copy()
    draw = ImageDraw.Draw(image)
    places = place_map(data)
    anchors = anchor_list(data)
    callouts = callout_positions(data)

    for hotspot in place_list(data):
        if not hotspot.get("default_visible", False):
            continue
        x, y, w, _ = rect_of(hotspot)
        box = draw_label(draw, (x + 18, max(12, y - 58)), hotspot["label"], FONT_26)
        cx, cy = center_of(hotspot)
        draw.line((box[0] + (box[2] - box[0]) // 2, box[3], cx, cy), fill="#5d84bf", width=3)

    for hotspot in anchors:
        cx, cy = center_of(hotspot)
        call_x, call_y = callouts.get(hotspot["id"], (cx + 40, cy - 20))
        strong = hotspot["id"] in STRONG_ANCHORS
        label_font = FONT_22 if strong else FONT_18
        prefix = f"{hotspot['route_order']} " if not strong else f"{hotspot['route_order']} {hotspot['letter']} "
        label_text = f"{prefix}{hotspot['label']}" if strong else f"{prefix}{hotspot['label']}"
        fill = "#fff5d8" if strong else "#f4f4f4"
        outline = "#d39b1f" if strong else "#7087a7"
        text_fill = "#674a12" if strong else "#4e617c"
        bbox = draw_label(draw, (call_x, call_y), label_text, label_font, fill=fill, outline=outline, text_fill=text_fill, padding=(12, 7), radius=14)
        dot_color = "#f6c847" if strong else "#ffffff"
        draw.ellipse((cx - 7, cy - 7, cx + 7, cy + 7), fill=dot_color, outline=outline, width=3)
        anchor_x = bbox[0] if bbox[0] > cx else bbox[2]
        anchor_y = bbox[1] + (bbox[3] - bbox[1]) // 2
        draw.line((cx, cy, anchor_x, anchor_y), fill=outline, width=3)

    return image


def draw_showcase_overlay(base: Image.Image, data: dict) -> Image.Image:
    image = base.copy()
    draw = ImageDraw.Draw(image)
    width, height = image.size

    draw.rounded_rectangle((24, 24, width - 24, height - 24), radius=28, outline="#ffffff", width=6)

    places = place_map(data)
    for hotspot in place_list(data):
        if not hotspot.get("default_visible", False):
            continue
        x, y, w, _ = rect_of(hotspot)
        draw_label(draw, (x + 28, max(70, y - 54)), hotspot["label"], FONT_22)

    callouts = callout_positions(data)
    for hotspot in anchor_list(data):
        cx, cy = center_of(hotspot)
        if hotspot["id"] in STRONG_ANCHORS:
            call_x, call_y = callouts.get(hotspot["id"], (cx + 40, cy - 20))
            bbox = draw_label(
                draw,
                (call_x, call_y),
                f"{hotspot['letter']} {hotspot['label']}",
                FONT_22,
                fill="#fff4d5",
                outline="#d29b20",
                text_fill="#6a4c14",
                padding=(13, 7),
            )
            draw.ellipse((cx - 13, cy - 13, cx + 13, cy + 13), outline="#f6c847", width=5)
            anchor_x = bbox[0] if bbox[0] > cx else bbox[2]
            anchor_y = bbox[1] + (bbox[3] - bbox[1]) // 2
            draw.line((cx, cy, anchor_x, anchor_y), fill="#d29b20", width=3)
        else:
            draw.ellipse((cx - 8, cy - 8, cx + 8, cy + 8), fill="#ffffff", outline="#5b7db2", width=3)
            draw.text((cx - 6, cy - 10), str(hotspot["route_order"]), font=FONT_18, fill="#4f6e98")

    return image


def save(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)
    print(path.relative_to(ROOT))


def main() -> None:
    data = load_data()
    overview = draw_overview(data)
    engineering = draw_engineering_overlay(overview, data)
    showcase = draw_showcase_overlay(overview, data)
    save(overview, OVERVIEW_PATH)
    save(engineering, AZ_LABEL_PATH)
    save(showcase, AZ_SHOWCASE_PATH)


if __name__ == "__main__":
    main()
