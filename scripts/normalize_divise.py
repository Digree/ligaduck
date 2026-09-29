from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def normalize_image(path: Path, width: int, height: int, apply: bool) -> bool:
    with Image.open(path) as source:
        if source.format != "WEBP":
            raise ValueError(f"expected WebP, got {source.format}")
        if source.size == (width, height):
            return False

        source = source.convert("RGBA")
        scale = min(width / source.width, height / source.height)
        resized = source.resize(
            (round(source.width * scale), round(source.height * scale)),
            Image.Resampling.LANCZOS,
        )
        canvas = Image.new("RGBA", (width, height), (0, 0, 0, 0))
        canvas.alpha_composite(
            resized,
            ((width - resized.width) // 2, (height - resized.height) // 2),
        )

        if apply:
            temporary = path.with_name(f".{path.name}.tmp")
            try:
                canvas.save(temporary, format="WEBP", quality=90, method=4)
                with Image.open(temporary) as result:
                    result.load()
                    if result.format != "WEBP" or result.size != (width, height):
                        raise ValueError("normalized output failed validation")
                temporary.replace(path)
            finally:
                temporary.unlink(missing_ok=True)

        return True


def main() -> int:
    project_root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(
        description="Normalize all divise WebP assets to a transparent canvas."
    )
    parser.add_argument(
        "--directory",
        type=Path,
        default=project_root / "assets" / "divise",
    )
    parser.add_argument("--width", type=int, default=512)
    parser.add_argument("--height", type=int, default=683)
    parser.add_argument(
        "--apply",
        action="store_true",
        help="Rewrite assets (without this flag, only report what would change).",
    )
    args = parser.parse_args()

    if args.width < 1 or args.height < 1:
        parser.error("canvas dimensions must be positive")
    if not args.directory.is_dir():
        parser.error(f"directory does not exist: {args.directory}")

    images = sorted(args.directory.rglob("*.webp"))
    changed = 0
    for path in images:
        try:
            changed += normalize_image(path, args.width, args.height, args.apply)
        except Exception as error:
            print(f"Failed: {path}: {error}")
            return 1

    action = "Normalized" if args.apply else "Would normalize"
    print(f"{action} {changed} of {len(images)} WebP images to {args.width}x{args.height}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())