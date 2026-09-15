"""Normalize the irregular six-cell old-man source sheet into equal animation frames."""

from pathlib import Path

from PIL import Image


PROJECT = Path(__file__).resolve().parents[1]
SOURCE = PROJECT / "assets" / "npc_anim" / "old_man.png"
OUTPUT = PROJECT / "assets" / "npc_anim" / "old_man_fixed.png"

# The source generator left opaque separator borders and unequal cell widths.
# Coordinates exclude those borders while preserving the original ground line.
FRAME_RANGES = [
    (7, 354),
    (357, 664),
    (667, 973),
    (975, 1281),
    (1283, 1593),
    (1595, 1941),
]
SOURCE_TOP = 7
SOURCE_BOTTOM = 521
FRAME_WIDTH = 350
FRAME_HEIGHT = SOURCE_BOTTOM - SOURCE_TOP


def main() -> None:
    source = Image.open(SOURCE).convert("RGBA")
    output = Image.new("RGBA", (FRAME_WIDTH * len(FRAME_RANGES), FRAME_HEIGHT))
    for index, (left, right) in enumerate(FRAME_RANGES):
        frame = source.crop((left, SOURCE_TOP, right, SOURCE_BOTTOM))
        target_x = index * FRAME_WIDTH + (FRAME_WIDTH - frame.width) // 2
        output.alpha_composite(frame, (target_x, 0))

    # Remove any one-pixel remnants from the generator's cell borders.
    pixels = output.load()
    for index in range(len(FRAME_RANGES)):
        cell_left = index * FRAME_WIDTH
        cell_right = cell_left + FRAME_WIDTH
        for x in range(cell_left, cell_left + 6):
            for y in range(FRAME_HEIGHT):
                pixels[x, y] = (0, 0, 0, 0)
        for x in range(cell_right - 6, cell_right):
            for y in range(FRAME_HEIGHT):
                pixels[x, y] = (0, 0, 0, 0)
        for y in list(range(5)) + list(range(FRAME_HEIGHT - 5, FRAME_HEIGHT)):
            for x in range(cell_left, cell_right):
                pixels[x, y] = (0, 0, 0, 0)
    output.save(OUTPUT)
    print(f"wrote {OUTPUT} ({output.width}x{output.height}, {len(FRAME_RANGES)} frames)")


if __name__ == "__main__":
    main()
