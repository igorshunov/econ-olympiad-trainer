#!/usr/bin/env python3
"""Сборка PDF из markdown-отчётов через markdown + weasyprint."""
import os, sys, base64, re
import markdown
from pathlib import Path

CSS = """
@page { size: A4; margin: 1.8cm 1.6cm; }
body { font-family: "DejaVu Sans", "Liberation Sans", sans-serif; font-size: 11pt; line-height: 1.45; color: #111827; }
h1 { font-size: 22pt; margin-top: 0; color: #111827; border-bottom: 2px solid #1d4ed8; padding-bottom: 6pt; }
h2 { font-size: 16pt; margin-top: 18pt; color: #1d4ed8; }
h3 { font-size: 13pt; margin-top: 12pt; color: #1e3a8a; }
h4 { font-size: 12pt; }
p, li { font-size: 11pt; }
code { background: #f1f5f9; padding: 1px 4px; border-radius: 3px; font-size: 10pt; }
pre { background: #f8fafc; padding: 8pt; border-radius: 6pt; border: 1px solid #e2e8f0; font-size: 9pt; overflow-wrap: break-word; white-space: pre-wrap; }
pre code { background: none; padding: 0; }
table { width: 100%; border-collapse: collapse; font-size: 10pt; margin: 8pt 0; }
th, td { border: 1px solid #cbd5e1; padding: 4pt 6pt; text-align: left; }
th { background: #e2e8f0; }
img { max-width: 100%; height: auto; }
a { color: #1d4ed8; word-break: break-all; }
blockquote { border-left: 3px solid #cbd5e1; padding-left: 8pt; color: #475569; }
"""

def md_to_html(md_path):
    md_text = Path(md_path).read_text(encoding="utf-8")
    def replace_img(match):
        alt, src = match.group(1), match.group(2)
        if src.startswith(("http://","https://")): return match.group(0)
        path = (Path(md_path).parent / src).resolve()
        if not path.exists():
            print(f"  WARN: image not found: {path}", file=sys.stderr)
            return match.group(0)
        ext = path.suffix.lstrip(".").lower()
        mime = {"png":"png","jpg":"jpeg","jpeg":"jpeg","gif":"gif","svg":"svg+xml"}.get(ext, "octet-stream")
        data = base64.b64encode(path.read_bytes()).decode()
        return f'![{alt}](data:image/{mime};base64,{data})'
    md_text = re.sub(r'!\[([^\]]*)\]\(([^)]+)\)', replace_img, md_text)
    html_body = markdown.markdown(md_text, extensions=['tables','fenced_code'])
    return f"<!DOCTYPE html><html><head><meta charset='utf-8'><style>{CSS}</style></head><body>{html_body}</body></html>"

def main():
    here = Path(__file__).parent
    for src_name, out_name in [("up02_report.md", "up02_report.pdf"),
                                ("up11_report.md", "up11_report.pdf")]:
        src = here / src_name
        if not src.exists():
            print(f"missing {src}", file=sys.stderr); continue
        html = md_to_html(src)
        out = here / out_name
        from weasyprint import HTML
        HTML(string=html, base_url=str(here)).write_pdf(str(out))
        print(f"  built {out.name} ({out.stat().st_size//1024} KB)")

if __name__ == "__main__":
    main()
