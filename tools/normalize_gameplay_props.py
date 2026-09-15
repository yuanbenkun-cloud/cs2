from pathlib import Path
from typing import List, Tuple
from PIL import Image, ImageEnhance


ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets" / "production" / "props" / "gameplay" / "source"
OUT = ROOT / "assets" / "production" / "props" / "gameplay"


def alpha_crop(image: Image.Image) -> Image.Image:
    alpha = image.getchannel("A")
    box = alpha.getbbox()
    if box is None:
        raise ValueError("empty transparent image")
    return image.crop(box)


def fit(image: Image.Image, size: Tuple[int, int], padding: int = 1) -> Image.Image:
    image = alpha_crop(image)
    max_w, max_h = size[0] - padding * 2, size[1] - padding * 2
    ratio = min(max_w / image.width, max_h / image.height)
    scaled = image.resize(
        (max(1, round(image.width * ratio)), max(1, round(image.height * ratio))),
        Image.Resampling.LANCZOS,
    )
    scaled = ImageEnhance.Sharpness(scaled).enhance(1.25)
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    x = (size[0] - scaled.width) // 2
    y = size[1] - padding - scaled.height
    canvas.alpha_composite(scaled, (x, y))
    return canvas


def fit_stretch(image: Image.Image, size: Tuple[int, int], padding: int = 1) -> Image.Image:
    image = alpha_crop(image)
    scaled = image.resize(
        (size[0] - padding * 2, size[1] - padding * 2),
        Image.Resampling.LANCZOS,
    )
    scaled = ImageEnhance.Sharpness(scaled).enhance(1.25)
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    canvas.alpha_composite(scaled, (padding, padding))
    return canvas


def split_horizontal(
    source: Path, names: List[str], canvas: Tuple[int, int], stretch: bool = False
) -> None:
    image = Image.open(source).convert("RGBA")
    for i, name in enumerate(names):
        left = round(image.width * i / len(names))
        right = round(image.width * (i + 1) / len(names))
        source_slice = image.crop((left, 0, right, image.height))
        result = fit_stretch(source_slice, canvas) if stretch else fit(source_slice, canvas)
        result.save(OUT / name, optimize=True)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    split_horizontal(
        SRC / "cargo-states-raw.png",
        ["cargo-intact.png", "cargo-damaged.png", "cargo-ruined.png"],
        (52, 40),
        True,
    )
    split_horizontal(
        SRC / "blast-shield-states-raw.png",
        ["blast-shield-intact.png", "blast-shield-damaged.png", "blast-shield-ruined.png"],
        (184, 104),
        True,
    )
    bomb = Image.open(SRC / "aerial-bomb-raw.png").convert("RGBA")
    fit(bomb, (18, 44), 0).save(OUT / "aerial-bomb.png", optimize=True)
    runtime_specs = [
        ("porridge-pot.png", "porridge-pot-runtime.png", (88, 80)),
        ("log-bundle.png", "log-bundle-runtime.png", (148, 74)),
        ("forge-wall.png", "forge-wall-runtime.png", (220, 260)),
        ("loose-tile.png", "loose-tile-runtime.png", (100, 44)),
    ]
    for source_name, output_name, size in runtime_specs:
        source = Image.open(OUT / source_name).convert("RGBA")
        fit(source, size, 1).save(OUT / output_name, optimize=True)
    print("[RESULT] normalized gameplay props")


if __name__ == "__main__":
    main()
