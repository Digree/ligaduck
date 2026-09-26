from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor
import os
import sys
from pathlib import Path

from PIL import Image


def convert_image(source: Path, target: Path, max_dimension: int, quality: int) -> None:
    temporary = target.with_name(f".{target.name}.tmp")
    try:
        with Image.open(source) as image:
            has_alpha = "A" in image.getbands() or "transparency" in image.info
            image = image.convert("RGBA" if has_alpha else "RGB")
            image.thumbnail(
                (max_dimension, max_dimension),
                Image.Resampling.LANCZOS,
            )
            image.save(
                temporary,
                format="WEBP",
                quality=quality,
                method=3,
            )

        with Image.open(temporary) as converted:
            converted.load()
            if converted.format != "WEBP":
                raise ValueError("output is not WebP")
            if converted.width > max_dimension or converted.height > max_dimension:
                raise ValueError("output exceeds the maximum dimensions")

        temporary.replace(target)
    except Exception:
        temporary.unlink(missing_ok=True)
        raise


def is_valid_webp(path: Path, max_dimension: int) -> bool:
    try:
        with Image.open(path) as image:
            image.load()
            return (
                image.format == "WEBP"
                and image.width <= max_dimension
                and image.height <= max_dimension
            )
    except Exception:
        return False


def main() -> int:
    project_root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(
        description="Convert divise PNG to optimized WebP assets."
    )
    parser.add_argument(
        "--directory",
        type=Path,
        default=project_root / "assets" / "divise",
        help="Directory to scan (default: assets/divise).",
    )
    parser.add_argument("--max-dimension", type=int, default=768)
    parser.add_argument("--quality", type=int, default=90)
    parser.add_argument(
        "--workers",
        type=int,
        default=min(4, os.cpu_count() or 1),
        help="Number of parallel conversions (default: up to 4).",
    )
    parser.add_argument(
        "--delete-source",
        action="store_true",
        help="Delete PNG files only after every conversion succeeds.",
    )
    args = parser.parse_args()

    if args.max_dimension < 1:
        parser.error("--max-dimension must be positive")
    if not 1 <= args.quality <= 100:
        parser.error("--quality must be between 1 and 100")
    if args.workers < 1:
        parser.error("--workers must be positive")

    directory = args.directory.resolve()
    if not directory.is_dir():
        parser.error(f"directory does not exist: {directory}")

    sources = sorted(directory.rglob("*.png"))
    if not sources:
        print(f"No PNG files found in {directory}")
        return 0

    invalid_targets = [
        source.with_suffix(".webp")
        for source in sources
        if source.with_suffix(".webp").exists()
        and not is_valid_webp(source.with_suffix(".webp"), args.max_dimension)
    ]
    if invalid_targets:
        print(f"Invalid existing WebP: {invalid_targets[0]}", file=sys.stderr)
        return 1

    pending = [source for source in sources if not source.with_suffix(".webp").exists()]
    skipped = len(sources) - len(pending)
    try:
        with ThreadPoolExecutor(max_workers=args.workers) as executor:
            list(
                executor.map(
                    lambda source: convert_image(
                        source,
                        source.with_suffix(".webp"),
                        args.max_dimension,
                        args.quality,
                    ),
                    pending,
                )
            )
    except Exception as error:
        print(f"Conversion failed: {error}", file=sys.stderr)
        return 1

    if args.delete_source:
        for source in sources:
            source.unlink()

    print(
        f"Converted {len(pending)} PNG files; reused {skipped} existing WebP files "
        f"in {directory}"
    )
    if args.delete_source:
        print("Removed the source PNG files after successful conversion.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())