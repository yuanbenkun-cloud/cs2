from __future__ import annotations

"""Build four lively prologue comic panels from the project's approved pixel assets.

This deterministic fallback keeps character identity exact when external image generation
is unavailable.  It deliberately uses different lenses, blocking, tilt, rain and motion
graphics instead of placing the same two upright cutouts over one background crop.
"""

from pathlib import Path
import random

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "production" / "story" / "prologue-v2"
BG_PATH = ROOT / "assets" / "production" / "backgrounds" / "01" / "layered-preview.png"
HERO = ROOT / "assets" / "production" / "hero"
AUNT = ROOT / "assets" / "npc_anim" / "flyer_lady_walk"
SIZE = (1024, 486)


def cover_background(focus_x: float, focus_y: float, zoom: float, blur: float = 0.0) -> Image.Image:
    source = Image.open(BG_PATH).convert("RGB")
    target_ratio = SIZE[0] / SIZE[1]
    crop_w = int(source.width / zoom)
    crop_h = int(crop_w / target_ratio)
    if crop_h > source.height:
        crop_h = int(source.height / zoom)
        crop_w = int(crop_h * target_ratio)
    cx = int(focus_x * source.width)
    cy = int(focus_y * source.height)
    left = max(0, min(source.width - crop_w, cx - crop_w // 2))
    top = max(0, min(source.height - crop_h, cy - crop_h // 2))
    image = source.crop((left, top, left + crop_w, top + crop_h)).resize(SIZE, Image.Resampling.LANCZOS)
    if blur:
        image = image.filter(ImageFilter.GaussianBlur(blur))
    image = ImageEnhance.Color(image).enhance(0.90)
    return image.convert("RGBA")


def grade(image: Image.Image, color: tuple[int, int, int], opacity: int) -> None:
    wash = Image.new("RGBA", SIZE, color + (opacity,))
    image.alpha_composite(wash)
    # Caption-safe lower field, integrated as a cinematic foreground shadow.
    shade = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    draw = ImageDraw.Draw(shade)
    for y in range(300, SIZE[1]):
        alpha = int(8 + 76 * (y - 300) / (SIZE[1] - 300))
        draw.line((0, y, SIZE[0], y), fill=(5, 8, 16, alpha))
    image.alpha_composite(shade)


def add_wet_street(image: Image.Image, horizon: int = 315, seed: int = 0, tilt: int = 0) -> None:
    """Create a readable foreground plane so character feet belong to the scene."""
    rng = random.Random(seed)
    street = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    draw = ImageDraw.Draw(street, "RGBA")
    draw.polygon([(0, horizon + tilt), (SIZE[0], horizon - tilt), (SIZE[0], SIZE[1]), (0, SIZE[1])], fill=(12, 19, 34, 246))
    draw.line((0, horizon + tilt, SIZE[0], horizon - tilt), fill=(90, 107, 130, 130), width=3)
    # Perspective joints and shallow puddle highlights.
    vanishing = (560, horizon - 20)
    for x in range(-180, 1260, 145):
        draw.line((x, SIZE[1], vanishing[0], vanishing[1]), fill=(64, 77, 96, 68), width=2)
    for y in [354, 397, 443, 478]:
        draw.line((0, y + tilt // 2, SIZE[0], y - tilt // 2), fill=(70, 83, 103, 54), width=2)
    for _ in range(34):
        x = rng.randrange(15, SIZE[0] - 30)
        y = rng.randrange(horizon + 14, SIZE[1] - 8)
        width = rng.randrange(12, 70)
        color = rng.choice([(212, 122, 60, 32), (100, 151, 204, 38), (194, 176, 133, 22)])
        draw.line((x, y, x + width, y - tilt / 15), fill=color, width=rng.choice([1, 2]))
    image.alpha_composite(street)


def load_sprite(path: Path, height: int, flip: bool = False, angle: float = 0.0) -> Image.Image:
    sprite = Image.open(path).convert("RGBA")
    bbox = sprite.getbbox()
    if bbox:
        sprite = sprite.crop(bbox)
    width = max(1, int(sprite.width * height / sprite.height))
    sprite = sprite.resize((width, height), Image.Resampling.NEAREST)
    if flip:
        sprite = sprite.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    if angle:
        sprite = sprite.rotate(angle, resample=Image.Resampling.NEAREST, expand=True)
    return sprite


def paste_grounded(image: Image.Image, sprite: Image.Image, foot: tuple[int, int], shadow_scale: float = 1.0) -> None:
    x = int(foot[0] - sprite.width / 2)
    y = int(foot[1] - sprite.height)
    shadow = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    half = int(sprite.width * 0.30 * shadow_scale)
    sd.ellipse((foot[0] - half, foot[1] - 8, foot[0] + half, foot[1] + 8), fill=(0, 0, 0, 90))
    shadow = shadow.filter(ImageFilter.GaussianBlur(7))
    image.alpha_composite(shadow)
    image.alpha_composite(sprite, (x, y))


def add_rain(image: Image.Image, seed: int, density: int, slant: int = -4) -> None:
    rng = random.Random(seed)
    overlay = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    for _ in range(density):
        x = rng.randrange(-20, SIZE[0] + 20)
        y = rng.randrange(0, SIZE[1])
        length = rng.randrange(7, 22)
        alpha = rng.randrange(18, 66)
        draw.line((x, y, x + slant, y + length), fill=(135, 178, 222, alpha), width=rng.choice([1, 1, 2]))
    image.alpha_composite(overlay)


def add_vignette(image: Image.Image, strength: int = 105) -> None:
    mask = Image.new("L", SIZE, 0)
    draw = ImageDraw.Draw(mask)
    for inset in range(0, 130, 4):
        alpha = int(strength * (1.0 - inset / 130.0) ** 2)
        draw.rounded_rectangle((inset, inset // 2, SIZE[0] - inset, SIZE[1] - inset // 2), radius=42, outline=alpha, width=7)
    darkness = Image.new("RGBA", SIZE, (1, 3, 10, 0))
    darkness.putalpha(mask)
    image.alpha_composite(darkness)


def panel_one() -> Image.Image:
    image = cover_background(0.69, 0.50, 1.48, 0.35)
    grade(image, (17, 30, 67), 28)
    add_wet_street(image, 316, 11)
    hero = load_sprite(HERO / "walk" / "walk-3.png", 356, angle=-4.0)
    paste_grounded(image, hero, (660, 430), 1.15)
    # Cool phone/navigation glow off-frame implies urgency without freezing him in a UI pose.
    glow = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse((725, 120, 930, 315), fill=(77, 184, 255, 31))
    glow = glow.filter(ImageFilter.GaussianBlur(28))
    image.alpha_composite(glow)
    add_rain(image, 101, 155, -5)
    add_vignette(image, 92)
    return image


def panel_two() -> Image.Image:
    image = cover_background(0.54, 0.54, 1.26, 0.55)
    # A dark alley mouth on the right and bright crowd shapes behind clarify the shortcut choice.
    draw = ImageDraw.Draw(image, "RGBA")
    draw.polygon([(630, 0), (1024, 0), (1024, 486), (720, 486), (560, 228)], fill=(6, 10, 21, 142))
    # Distant, softened crowd stays behind the street horizon rather than becoming an icon row.
    crowd = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    cd = ImageDraw.Draw(crowd, "RGBA")
    rng = random.Random(22)
    for x in range(55, 430, 39):
        height = rng.randrange(30, 48)
        base = 320 + rng.randrange(-4, 5)
        cd.ellipse((x, base - height, x + 15, base - height + 15), fill=(8, 12, 23, 176))
        cd.rounded_rectangle((x + 2, base - height + 12, x + 14, base), radius=4, fill=(8, 12, 23, 176))
    crowd = crowd.filter(ImageFilter.GaussianBlur(1.3))
    image.alpha_composite(crowd)
    add_wet_street(image, 323, 22)
    hero = load_sprite(HERO / "jump" / "jump-2.png", 285, angle=-11.0)
    paste_grounded(image, hero, (636, 431), 1.05)
    # Directional streaks reinforce a sharp change of course.
    streaks = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    sd = ImageDraw.Draw(streaks)
    for offset in range(8):
        y = 92 + offset * 34
        sd.line((430, y, 690, y + 80), fill=(145, 176, 222, 22 + offset * 2), width=2)
    image.alpha_composite(streaks)
    grade(image, (12, 24, 55), 20)
    add_rain(image, 202, 130, -7)
    add_vignette(image, 104)
    return image


def panel_three() -> Image.Image:
    image = cover_background(0.78, 0.56, 1.63, 1.05)
    grade(image, (22, 26, 54), 36)
    add_wet_street(image, 318, 33)
    hero = load_sprite(HERO / "interact" / "interact-3.png", 330, angle=-2.0)
    aunt = load_sprite(AUNT / "walk-1.png", 350, flip=False, angle=1.2)
    paste_grounded(image, hero, (325, 438), 0.9)
    paste_grounded(image, aunt, (740, 441), 1.0)
    # The offered flyer bridges the gap and creates a readable point of conflict.
    draw = ImageDraw.Draw(image, "RGBA")
    draw.polygon([(587, 224), (651, 213), (659, 250), (594, 260)], fill=(236, 222, 178, 255), outline=(112, 83, 57, 255))
    draw.line((598, 232, 644, 226), fill=(169, 77, 55, 220), width=4)
    draw.line((601, 242, 638, 237), fill=(74, 92, 94, 180), width=3)
    # Warm lantern pool on the aunt, cool phone-side light on Chen Mo.
    light = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    ld = ImageDraw.Draw(light)
    ld.ellipse((545, 40, 960, 470), fill=(255, 142, 56, 35))
    light = light.filter(ImageFilter.GaussianBlur(72))
    image.alpha_composite(light)
    add_rain(image, 303, 105, -4)
    add_vignette(image, 88)
    return image


def panel_four() -> Image.Image:
    base = cover_background(0.66, 0.53, 1.35, 0.9)
    # Rotate the environment, then crop back to frame for a restrained Dutch angle.
    rotated = base.rotate(3.2, resample=Image.Resampling.BICUBIC, expand=True, fillcolor=(7, 10, 22, 255))
    left = (rotated.width - SIZE[0]) // 2
    top = (rotated.height - SIZE[1]) // 2
    image = rotated.crop((left, top, left + SIZE[0], top + SIZE[1]))
    grade(image, (17, 21, 52), 34)
    add_wet_street(image, 316, 44, 20)
    aunt = load_sprite(AUNT / "walk-6.png", 284, flip=True, angle=-7.0)
    hero = load_sprite(HERO / "jump" / "jump-2.png", 330, angle=-8.0)
    paste_grounded(image, aunt, (375, 426), 0.85)
    paste_grounded(image, hero, (764, 451), 1.15)
    motion = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    md = ImageDraw.Draw(motion)
    rng = random.Random(404)
    for _ in range(25):
        y = rng.randrange(70, 390)
        x = rng.randrange(0, 570)
        length = rng.randrange(70, 220)
        md.line((x, y, x + length, y - 28), fill=(165, 193, 224, rng.randrange(18, 55)), width=rng.choice([1, 2, 3]))
    # Flyers trail diagonally between pursuer and runner.
    for x, y, angle in [(478, 170, -14), (552, 126, 9), (621, 208, -7)]:
        paper = Image.new("RGBA", (72, 48), (0, 0, 0, 0))
        pd = ImageDraw.Draw(paper)
        pd.polygon([(5, 8), (66, 3), (61, 42), (9, 46)], fill=(229, 217, 178, 235), outline=(111, 81, 58, 220))
        paper = paper.rotate(angle, resample=Image.Resampling.BICUBIC, expand=True)
        motion.alpha_composite(paper, (x, y))
    image.alpha_composite(motion)
    add_rain(image, 404, 175, -9)
    add_vignette(image, 108)
    return image


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    panels = [panel_one(), panel_two(), panel_three(), panel_four()]
    for index, panel in enumerate(panels, 1):
        path = OUT / f"panel-{index}.png"
        panel.convert("RGB").save(path, optimize=True)
        print("[COMIC]", path.relative_to(ROOT))
    print("[RESULT] generated 4 prologue panels")


if __name__ == "__main__":
    main()
