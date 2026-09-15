from __future__ import annotations

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1] / "assets" / "production" / "backgrounds"
TARGET_SIZE = (1280, 720)


def resize_layer(source: Path, target: Path, alpha: bool) -> Image.Image:
    mode = "RGBA" if alpha else "RGB"
    with Image.open(source) as image:
        normalized = image.convert(mode).resize(TARGET_SIZE, Image.Resampling.LANCZOS)
    normalized.save(target, optimize=True)
    return normalized.convert("RGBA")


def main() -> None:
    for era in ("01", "02", "03", "04", "05"):
        folder = ROOT / era
        sky = resize_layer(folder / "sky-raw.png", folder / "sky.png", False)
        far = resize_layer(folder / "far-raw.png", folder / "far.png", True)
        mid = resize_layer(folder / "mid-raw.png", folder / "mid.png", True)
        preview = Image.alpha_composite(Image.alpha_composite(sky, far), mid)
        preview.convert("RGB").save(folder / "layered-preview.png", optimize=True)
        print(f"[PASS] {era}: {TARGET_SIZE[0]}x{TARGET_SIZE[1]}")


if __name__ == "__main__":
    main()
