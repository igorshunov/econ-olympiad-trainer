"""Рисуем красивый PNG-снимок структуры таблиц БД (вывод \\d+ psql)
через HTML→Playwright."""
import os, subprocess
from playwright.sync_api import sync_playwright

TXT = "/home/igor/study/diploma/database/table_structures.txt"
OUT_DIR = "/home/igor/study/diploma/database/screenshots"
os.makedirs(OUT_DIR, exist_ok=True)

CSS = """
<style>
  body { background:#0f172a; color:#e2e8f0; font-family:"JetBrains Mono","Fira Code","Courier New",monospace; margin:0; padding:24px; }
  .table-block { background:#1e293b; border:1px solid #334155; border-radius:8px; padding:16px 20px; margin-bottom:20px; }
  .table-block h2 { font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif; color:#60a5fa; margin:0 0 12px; font-size:18px; }
  pre { font-size:12px; line-height:1.45; white-space:pre; overflow-x:auto; margin:0; color:#cbd5e1; }
  .prompt { color:#10b981; }
  .keyword { color:#fbbf24; font-weight:600; }
  .note { color:#94a3b8; font-style:italic; }
</style>
"""

# Highlight some keywords
def highlight(text):
    import html
    out = html.escape(text)
    out = out.replace('PRIMARY KEY', '<span class="keyword">PRIMARY KEY</span>')
    out = out.replace('FOREIGN KEY', '<span class="keyword">FOREIGN KEY</span>')
    out = out.replace('UNIQUE', '<span class="keyword">UNIQUE</span>')
    out = out.replace('not null', '<span class="keyword">not null</span>')
    out = out.replace('Check constraints:', '<span class="keyword">Check constraints:</span>')
    out = out.replace('Indexes:', '<span class="keyword">Indexes:</span>')
    out = out.replace('Referenced by:', '<span class="keyword">Referenced by:</span>')
    out = out.replace('Foreign-key constraints:', '<span class="keyword">Foreign-key constraints:</span>')
    return out

# Parse table-by-table
import re
with open(TXT) as f:
    content = f.read()

# Pattern: "===\nTABLE: name\n===\n<body>\n===" (next block) or EOF
blocks = []
pattern = re.compile(
    r'={50,}\s*\n(?:TABLE|VIEW):\s*(\S+)\s*\n={50,}\s*\n(.*?)(?=\n={50,}\s*\n(?:TABLE|VIEW):|\Z)',
    re.DOTALL)
for m in pattern.finditer(content):
    name = m.group(1).strip()
    body = m.group(2).strip()
    blocks.append((name, body))

print(f"Parsed {len(blocks)} tables")

def render(name, body, out_path):
    html = f"""<!doctype html><html><head><meta charset="utf-8">{CSS}</head><body>
<div class="table-block">
  <h2>{name}</h2>
  <pre>$ <span class="prompt">psql econtrainer=#</span> \\d+ {name}
{highlight(body)}</pre>
</div>
</body></html>"""
    with open("/tmp/_struct.html","w") as f:
        f.write(html)
    with sync_playwright() as p:
        b = p.chromium.launch(channel='chrome', headless=True)
        page = b.new_page(viewport={"width": 1280, "height": 200})
        page.goto("file:///tmp/_struct.html")
        page.wait_for_load_state("networkidle")
        # Auto-resize to content
        h = page.evaluate("document.body.scrollHeight")
        page.set_viewport_size({"width": 1280, "height": int(h)})
        page.screenshot(path=out_path, full_page=True)
        b.close()
    print(f"  {out_path}")

for name, body in blocks:
    out_path = os.path.join(OUT_DIR, f"table_{name}.png")
    render(name, body, out_path)
