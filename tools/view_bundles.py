#!/usr/bin/env python3
"""Render every landed bundle into one browsable HTML page.

    python3 tools/view_bundles.py && xdg-open ARIS_OUTPUT/view/index.html

This is a VIEWER, not the report. It exists because a 141,735-line TSV is unreadable in
a terminal and you cannot review what you cannot see.

It reads `results/*/tables/*.tsv`, `results/*/figures/*.png` and each bundle's README
STATUS line, and writes one self-contained page to ARIS_OUTPUT/view/ (gitignored, scratch,
regenerate any time). It computes NOTHING: every number on the page is copied from a
landed table, so the page cannot introduce a figure that no bundle produced.

The report proper is a different thing — a bundle, assembled after r04 from these same
tables, rendered through docs/specs/report_template.html.j2, with its own claims and its
own acceptance. This page is how you read the evidence in the meantime.

Stdlib only. No install.
"""
from __future__ import annotations

import base64
import html
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "ARIS_OUTPUT" / "view"
MAX_ROWS = 200          # a table longer than this is truncated, and says so


def read_tsv(path: Path, max_rows: int = MAX_ROWS) -> tuple[list[str], list[list[str]], int]:
    """Return (header, rows, total_data_rows). Rows are truncated to max_rows."""
    with path.open(encoding="utf-8", errors="replace") as fh:
        lines = fh.read().splitlines()
    if not lines:
        return [], [], 0
    header = lines[0].split("\t")
    body = [ln.split("\t") for ln in lines[1:] if ln.strip()]
    return header, body[:max_rows], len(body)


def table_html(path: Path) -> str:
    header, rows, total = read_tsv(path)
    if not header:
        return f"<p class=empty>{html.escape(path.name)} is empty.</p>"
    head = "".join(f"<th>{html.escape(c)}</th>" for c in header)
    body = "".join(
        "<tr>" + "".join(f"<td>{html.escape(c)}</td>" for c in r) + "</tr>" for r in rows
    )
    note = ""
    if total > len(rows):
        note = (f"<p class=note>Showing the first {len(rows):,} of {total:,} data rows. "
                f"The full table is in the bundle.</p>")
    return (f"<details><summary>{html.escape(path.name)} "
            f"<span class=dim>{total:,} rows</span></summary>{note}"
            f"<div class=scroll><table><thead><tr>{head}</tr></thead>"
            f"<tbody>{body}</tbody></table></div></details>")


def figure_html(png: Path) -> str:
    b64 = base64.b64encode(png.read_bytes()).decode("ascii")
    return (f"<figure><img src='data:image/png;base64,{b64}' alt='{html.escape(png.stem)}'>"
            f"<figcaption>{html.escape(png.stem)}</figcaption></figure>")


def status_line(readme: Path) -> str:
    if not readme.exists():
        return "no README"
    for line in readme.read_text(encoding="utf-8", errors="replace").splitlines():
        if line.startswith("STATUS:"):
            return line
    return "no STATUS line"


def main() -> int:
    bundles = sorted(p for p in (ROOT / "results").iterdir() if p.is_dir())
    if not bundles:
        print("no bundles in results/", file=sys.stderr)
        return 1

    OUT.mkdir(parents=True, exist_ok=True)
    parts: list[str] = []
    nav: list[str] = []

    for b in bundles:
        nav.append(f"<a href='#{b.name}'>{html.escape(b.name)}</a>")
        figs = sorted((b / "figures").glob("*.png")) if (b / "figures").is_dir() else []
        tabs = sorted((b / "tables").glob("*.tsv")) if (b / "tables").is_dir() else []
        parts.append(
            f"<section id='{b.name}'><h2>{html.escape(b.name)}</h2>"
            f"<p class=status>{html.escape(status_line(b / 'README.md'))}</p>"
            + (f"<div class=figs>{''.join(figure_html(f) for f in figs)}</div>" if figs else "")
            + (f"<h3>Tables <span class=dim>{len(tabs)}</span></h3>"
               + "".join(table_html(t) for t in tabs) if tabs else "<p class=empty>No tables.</p>")
            + "</section>"
        )

    css = """
:root{--bg:#fbfbf9;--fg:#1a1a1a;--dim:#6b6b6b;--line:#e0dedb;--accent:#7a3b2e}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--fg);
 font:14px/1.55 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif}
header{position:sticky;top:0;background:var(--bg);border-bottom:1px solid var(--line);
 padding:14px 24px;z-index:2}
header h1{margin:0 0 6px;font-size:17px;font-weight:650}
nav a{margin-right:14px;color:var(--accent);text-decoration:none;font-size:13px}
nav a:hover{text-decoration:underline}
main{padding:24px;max-width:1400px}
section{margin-bottom:56px}
h2{font-size:20px;margin:0 0 4px;border-bottom:2px solid var(--accent);
 display:inline-block;padding-bottom:3px}
h3{font-size:14px;text-transform:uppercase;letter-spacing:.07em;color:var(--dim);
 margin:26px 0 10px}
.status{color:var(--dim);font-size:13px;margin:8px 0 18px}
.dim{color:var(--dim);font-weight:400}
.note,.empty{color:var(--dim);font-size:12.5px;margin:8px 0}
.figs{display:flex;flex-wrap:wrap;gap:20px;margin:18px 0}
figure{margin:0;max-width:560px}
figure img{width:100%;border:1px solid var(--line);background:#fff;border-radius:3px}
figcaption{font-size:12px;color:var(--dim);margin-top:5px}
details{border:1px solid var(--line);border-radius:3px;margin-bottom:7px;background:#fff}
summary{cursor:pointer;padding:8px 12px;font-weight:550;font-size:13px}
summary:hover{background:#f4f2ef}
.scroll{overflow-x:auto;max-height:520px;overflow-y:auto;border-top:1px solid var(--line)}
table{border-collapse:collapse;font-size:12px;font-variant-numeric:tabular-nums;width:100%}
th,td{border-bottom:1px solid var(--line);padding:4px 9px;text-align:left;white-space:nowrap}
th{background:#f4f2ef;position:sticky;top:0;font-weight:600}
tbody tr:hover{background:#faf8f5}
@media(prefers-color-scheme:dark){
 :root{--bg:#17181a;--fg:#e8e6e3;--dim:#9a9894;--line:#33353a;--accent:#d98b74}
 figure img{background:#e8e6e3}
 summary:hover,tbody tr:hover{background:#1f2124}
 th{background:#1f2124}
 details{background:#1c1e21}}
"""
    page = (
        "<!doctype html><meta charset=utf-8>"
        "<meta name=viewport content='width=device-width,initial-scale=1'>"
        "<title>Landed bundles</title>"
        f"<style>{css}</style>"
        "<header><h1>Landed bundles</h1>"
        "<p class=status style='margin:0 0 6px'>Every number here is copied from a table "
        "in <code>results/</code>. This page computes nothing. It is not the report.</p>"
        f"<nav>{' '.join(nav)}</nav></header><main>{''.join(parts)}</main>"
    )
    dest = OUT / "index.html"
    dest.write_text(page, encoding="utf-8")
    print(f"wrote {dest}  ({dest.stat().st_size / 1024:.0f} KB, {len(bundles)} bundles)")
    print(f"open it:  xdg-open {dest}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
