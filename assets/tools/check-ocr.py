import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

with tempfile.TemporaryDirectory() as directory:
    image = Path(directory) / "check.png"
    canvas = Image.new("RGB", (900, 220), "white")
    draw = ImageDraw.Draw(canvas)
    draw.text((20, 60), "OCR CHECK 123", fill="black", font=ImageFont.truetype(r"C:\Windows\Fonts\arial.ttf", 72))
    canvas.save(image)
    output = subprocess.check_output(
        [sys.executable, r"G:\Codex\tools\ocr.py", str(image), "--lang", "eng"],
        text=True,
        encoding="utf-8",
    )
    assert "OCR CHECK 123" in output, output

print("local-ocr-ok")
