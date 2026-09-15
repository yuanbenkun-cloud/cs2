"""Build runtime ground plates whose visible surface matches the physics floor.

The source sheets contain sky, railings or walls above the actual walkable strip.
Displaying the entire 1024px sheet made characters appear to hover 25-35px above it.
This keeps only the portion beginning at the real contact surface and gently tones it
to sit beneath the foreground characters.
"""

from pathlib import Path
from PIL import Image, ImageEnhance


ROOT = Path(__file__).resolve().parents[1]
PROFILES = {
    "01": ("assets/raw/素材2/背景/01洪崖洞-现代夜/地形_无缝单元_1024_v3.png", 250, 0.82, 0.90),
    "02": ("assets/raw/素材2/背景/02磁器口-古代窑场/地形_无缝单元_1024_v3.png", 0, 0.72, 0.82),
    "03": ("assets/raw/素材2/背景/03中山古镇-古代/地形_无缝单元_1024_v3.png", 0, 0.78, 0.82),
    "04": ("assets/raw/素材2/背景/04防空洞-近代/地形_无缝单元_1024_v3.png", 330, 0.68, 0.78),
    "05": ("assets/raw/素材2/背景/05洪崖洞-归来晨光/地形_无缝单元_1024_v3.png", 430, 0.78, 0.78),
}


def build(era: str, source_rel: str, surface_y: int, brightness: float, saturation: float) -> None:
    source = Image.open(ROOT / source_rel).convert("RGB")
    visible = source.crop((0, surface_y, source.width, source.height))
    visible = ImageEnhance.Brightness(visible).enhance(brightness)
    visible = ImageEnhance.Color(visible).enhance(saturation)

    canvas = Image.new("RGB", (source.width, source.height))
    canvas.paste(visible, (0, 0))
    remaining = source.height - visible.height
    if remaining > 0:
        tail_height = min(72, visible.height)
        tail = visible.crop((0, visible.height - tail_height, visible.width, visible.height))
        tail = tail.resize((source.width, remaining), Image.Resampling.BILINEAR)
        # The lower extension is normally below the viewport; darkening prevents a flat band
        # becoming conspicuous during camera shake or unusual aspect ratios.
        tail = ImageEnhance.Brightness(tail).enhance(0.72)
        canvas.paste(tail, (0, visible.height))

    out_dir = ROOT / "assets" / "production" / "terrain" / era
    out_dir.mkdir(parents=True, exist_ok=True)
    canvas.save(out_dir / "ground.png", optimize=True)


if __name__ == "__main__":
    for key, profile in PROFILES.items():
        build(key, *profile)
    print("[RESULT] generated 5 grounded runtime terrain plates")
