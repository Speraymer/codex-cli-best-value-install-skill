import json
import subprocess
import sys
import tempfile
from pathlib import Path

from reportlab.pdfgen.canvas import Canvas

with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    pdf = root / "check.pdf"
    canvas = Canvas(str(pdf))
    for page in range(32):
        canvas.drawString(72, 720, f"Page {page + 1}")
        canvas.showPage()
    canvas.save()
    output = subprocess.check_output(
        [sys.executable, r"G:\Codex\tools\pdf-to-images.py", str(pdf), "--output", str(root / "pages")],
        text=True,
        encoding="utf-8",
    )
    result = json.loads(output)
    assert result["pages"] == 32 and result["rendered"] == 30
    assert all(Path(path).is_file() for path in result["files"])
    tail = subprocess.check_output(
        [sys.executable, r"G:\Codex\tools\pdf-to-images.py", str(pdf), "--output", str(root / "tail"), "--start-page", "31"],
        text=True,
        encoding="utf-8",
    )
    assert json.loads(tail)["rendered"] == 2

print("pdf-vision-renderer-ok")
