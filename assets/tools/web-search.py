import json
import sys

from ddgs import DDGS

sys.stdout.reconfigure(encoding="utf-8")

if len(sys.argv) < 2:
    raise SystemExit('Usage: python G:\\Codex\\tools\\web-search.py "query"')

results = list(DDGS().text(' '.join(sys.argv[1:]), max_results=8))
print(json.dumps(results, ensure_ascii=False, indent=2))
