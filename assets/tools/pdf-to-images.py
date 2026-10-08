import argparse
import json
from pathlib import Path

import pymupdf

parser = argparse.ArgumentParser()
parser.add_argument("pdf", type=Path)
parser.add_argument("--output", required=True, type=Path)
parser.add_argument("--max-pages", type=int, default=30)
parser.add_argument("--start-page", type=int, default=1)
args = parser.parse_args()

if not args.pdf.is_file() or args.pdf.suffix.lower() != ".pdf":
    raise SystemExit(f"PDF not found: {args.pdf}")
if args.max_pages < 1 or args.start_page < 1:
    raise SystemExit("--max-pages and --start-page must be at least 1")

args.output.mkdir(parents=True, exist_ok=True)
pdf = pymupdf.open(args.pdf)
# ponytail: limit image pages to control request size; add page-range selection if very long PDFs become routine.
start = args.start_page - 1
count = min(max(len(pdf) - start, 0), args.max_pages)
files = []
for index in range(start, start + count):
    path = args.output / f"page-{index + 1:03}.png"
    pdf[index].get_pixmap(matrix=pymupdf.Matrix(1.5, 1.5), alpha=False).save(path)
    files.append(str(path))

print(json.dumps({"pages": len(pdf), "start_page": args.start_page, "rendered": count, "files": files}))
