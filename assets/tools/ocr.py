import argparse
import subprocess
import sys
import tempfile
from pathlib import Path

import pymupdf

sys.stdout.reconfigure(encoding="utf-8")

parser = argparse.ArgumentParser(description="Extract text from an image or scanned PDF locally.")
parser.add_argument("input", type=Path)
parser.add_argument("--lang", default="chi_sim+eng", help="Tesseract languages, default: chi_sim+eng")
parser.add_argument("--psm", default="3", help="Tesseract page-segmentation mode, default: 3")
args = parser.parse_args()

engine = Path(r"G:\Codex\tools\tesseract\tesseract.exe")
if not engine.exists():
    raise SystemExit("Tesseract is missing from G:\\Codex\\tools\\tesseract.")
if not args.input.is_file():
    raise SystemExit(f"Input file not found: {args.input}")


def extract(image: Path) -> str:
    completed = subprocess.run(
        [str(engine), str(image), "stdout", "-l", args.lang, "--psm", args.psm],
        text=True,
        encoding="utf-8",
        errors="replace",
        capture_output=True,
        check=False,
    )
    if completed.returncode:
        raise RuntimeError(completed.stderr.strip() or "Tesseract failed.")
    return completed.stdout.strip()


if args.input.suffix.lower() != ".pdf":
    print(extract(args.input))
else:
    with tempfile.TemporaryDirectory() as directory:
        pdf = pymupdf.open(args.input)
        for number, page in enumerate(pdf, 1):
            image = Path(directory) / f"page-{number}.png"
            page.get_pixmap(matrix=pymupdf.Matrix(2, 2), alpha=False).save(image)
            print(f"--- Page {number} ---")
            print(extract(image))
