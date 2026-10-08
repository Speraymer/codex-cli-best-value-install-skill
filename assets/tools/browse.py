import argparse
import sys
from pathlib import Path

from playwright.sync_api import sync_playwright

sys.stdout.reconfigure(encoding="utf-8")

parser = argparse.ArgumentParser()
parser.add_argument('url')
parser.add_argument('--screenshot')
args = parser.parse_args()

with sync_playwright() as p:
    browser = p.chromium.launch(channel='msedge', headless=True)
    page = browser.new_page(viewport={'width': 1440, 'height': 1000})
    page.goto(args.url, wait_until='domcontentloaded', timeout=30000)
    print(f'Title: {page.title()}\nURL: {page.url}\n\n{page.locator("body").inner_text()[:12000]}')
    if args.screenshot:
        path = Path(args.screenshot).resolve()
        path.parent.mkdir(parents=True, exist_ok=True)
        page.screenshot(path=str(path), full_page=True)
        print(f'\nScreenshot: {path}')
    browser.close()
