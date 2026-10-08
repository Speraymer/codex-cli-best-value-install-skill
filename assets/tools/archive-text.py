import argparse
import os
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from urllib.parse import urlparse

sys.path.insert(0, r"G:\Codex\tools\python")
from pypdf import PdfReader

sys.stdout.reconfigure(encoding="utf-8")

parser = argparse.ArgumentParser(description="Archive webpage, PDF, or image text as Markdown.")
parser.add_argument("sources", nargs="+", help="Files or public http(s) URLs")
parser.add_argument("--output", type=Path, default=Path(r"G:\Codex\archives"))
args = parser.parse_args()

tools = Path(r"G:\Codex\tools")
python = Path(r"G:\Anaconda\python.exe")


def safe_name(value: str) -> str:
    name = re.sub(r"[^\w.-]+", "-", value, flags=re.UNICODE).strip(".-")
    return (name or "archive")[:80]


def run(command: list[str]) -> str:
    environment = {**os.environ, "PYTHONPATH": r"G:\Codex\tools\python"}
    result = subprocess.run(command, capture_output=True, text=True, encoding="utf-8", errors="replace", env=environment)
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or "Extraction failed.")
    return result.stdout.strip()


def archive(source: str) -> tuple[str, str, str]:
    parsed = urlparse(source)
    if parsed.scheme in {"http", "https"}:
        return "网页", source, run([str(python), str(tools / "browse.py"), source])

    path = Path(source).resolve()
    if not path.is_file():
        raise FileNotFoundError(f"Source not found: {path}")
    if path.suffix.lower() == ".pdf":
        text = "\n\n".join(page.extract_text() or "" for page in PdfReader(path).pages).strip()
        if not text:
            text = run([str(python), str(tools / "ocr.py"), str(path)])
        return "PDF", str(path), text
    return "图片", str(path), run([str(python), str(tools / "ocr.py"), str(path)])


args.output.mkdir(parents=True, exist_ok=True)
stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
for index, source in enumerate(args.sources, 1):
    try:
        kind, reference, text = archive(source)
        title = safe_name(urlparse(source).netloc if source.startswith(("http://", "https://")) else Path(source).stem)
        target = args.output / f"{stamp}-{index:02}-{title}.md"
        target.write_text(
            f"# {title}\n\n- 类型：{kind}\n- 来源：{reference}\n- 归档时间：{datetime.now().astimezone().isoformat(timespec='seconds')}\n\n## 正文\n\n{text or '（未提取到可读文本）'}\n",
            encoding="utf-8",
        )
        print(target)
    except Exception as error:
        print(f"Failed: {source}: {error}", file=sys.stderr)
