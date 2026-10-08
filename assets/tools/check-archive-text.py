import subprocess
import tempfile
import os
from pathlib import Path

from PIL import Image, ImageDraw
import sys

root = Path(r"G:\Codex")
python = Path(r"G:\Anaconda\python.exe")
sys.path.insert(0, str(root / "tools" / "python"))
from reportlab.pdfgen.canvas import Canvas
with tempfile.TemporaryDirectory() as folder:
    work = Path(folder)
    image = work / "sample.png"
    canvas = Image.new("RGB", (1000, 300), "white")
    ImageDraw.Draw(canvas).text((40, 100), "Archive check 123", fill="black", font_size=60)
    canvas.save(image)
    output = work / "archives"
    result = subprocess.run([str(python), str(root / "tools" / "archive-text.py"), str(image), "--output", str(output)], capture_output=True, text=True, encoding="utf-8", env={**os.environ, "PYTHONPATH": str(root / "tools" / "python")})
    assert result.returncode == 0, result.stderr
    files = list(output.glob("*.md"))
    assert len(files) == 1
    assert "类型：图片" in files[0].read_text(encoding="utf-8")
    pdf = work / "sample.pdf"
    canvas = Canvas(str(pdf))
    canvas.drawString(72, 720, "PDF archive check")
    canvas.save()
    result = subprocess.run([str(python), str(root / "tools" / "archive-text.py"), str(pdf), "--output", str(output)], capture_output=True, text=True, encoding="utf-8", env={**os.environ, "PYTHONPATH": str(root / "tools" / "python")})
    assert result.returncode == 0, result.stderr
    assert any("PDF archive check" in file.read_text(encoding="utf-8") for file in output.glob("*.md"))
print("archive-text-ok")
