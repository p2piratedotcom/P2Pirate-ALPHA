#!/usr/bin/env python3
"""Render native desktop icons from the canonical P2Pirate SVG.

Run with python3-gi, the librsvg GdkPixbuf loader and Pillow installed.
Each PNG is rendered from vectors at four times its target size before
downsampling; native icon containers are then built from the same artwork.
"""

from pathlib import Path

import gi
from PIL import Image

gi.require_version("GdkPixbuf", "2.0")
from gi.repository import GdkPixbuf


ROOT = Path(__file__).resolve().parent.parent
SVG = ROOT / "assets/logo/p2pirate_mark.svg"
MAC_ICONS = ROOT / "macos/Runner/Assets.xcassets/AppIcon.appiconset"


def render(size: int) -> Image.Image:
    rendered_size = size * 4
    pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_scale(
        str(SVG), rendered_size, rendered_size, True
    )
    mode = "RGBA" if pixbuf.get_has_alpha() else "RGB"
    image = Image.frombytes(
        mode,
        (pixbuf.get_width(), pixbuf.get_height()),
        pixbuf.get_pixels(),
        "raw",
        mode,
        pixbuf.get_rowstride(),
    )
    return image.resize((size, size), Image.Resampling.LANCZOS)


def main() -> None:
    render(512).save(ROOT / "linux/P2Pirate.png", optimize=True)

    for size in (16, 32, 64, 128, 256, 512, 1024):
        render(size).save(MAC_ICONS / f"app_icon_{size}.png", optimize=True)
    render(1024).save(MAC_ICONS / "AppIcon.icns", format="ICNS")

    render(256).save(
        ROOT / "windows/runner/resources/app_icon.ico",
        format="ICO",
        sizes=[(size, size) for size in (16, 24, 32, 48, 64, 128, 256)],
    )


if __name__ == "__main__":
    main()
