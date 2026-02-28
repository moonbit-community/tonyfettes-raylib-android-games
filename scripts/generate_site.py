#!/usr/bin/env python3
"""generate_site.py — Generate docs/index.html from APK objects in S3.

Usage:
    python3 scripts/generate_site.py

Environment:
    S3_BUCKET   — source bucket  (default: moonbit-raylib-android-games)
    AWS_REGION  — AWS region     (default: us-west-2)
    OUTPUT_DIR  — output dir     (default: docs/)
"""

import os
import re
import json
import subprocess

S3_BUCKET  = os.environ.get("S3_BUCKET",  "moonbit-raylib-android-games")
AWS_REGION = os.environ.get("AWS_REGION", "us-west-2")
OUTPUT_DIR = os.environ.get("OUTPUT_DIR", os.path.join(os.path.dirname(__file__), "..", "docs"))
BASE_URL   = f"https://{S3_BUCKET}.s3.{AWS_REGION}.amazonaws.com"

CLASSIC_NAMES = {
    "RaylibBattleCity", "RaylibMinesweeper", "RaylibContra1987Lite",
    "RaylibSuperMario1985Lite", "RaylibFighter97Lite",
    "RaylibJackal1988Lite", "RaylibBomberman1983Lite",
}

# ── Fetch APK list from S3 ────────────────────────────────────────────────────

def list_apks():
    """Return list of (name, size_mb) sorted by name."""
    result = subprocess.run(
        ["aws", "s3api", "list-objects-v2",
         "--bucket", S3_BUCKET,
         "--region", AWS_REGION,
         "--query", "Contents[?ends_with(Key, '.apk')].[Key,Size]",
         "--output", "json"],
        capture_output=True, text=True, check=True
    )
    objects = json.loads(result.stdout) or []
    entries = []
    for key, size in objects:
        name = key.removesuffix(".apk")
        if name.endswith("2026") or name in CLASSIC_NAMES:
            entries.append((name, f"{size / 1024 / 1024:.1f}"))
    return sorted(entries)

# ── HTML helpers ──────────────────────────────────────────────────────────────

def display_name(name):
    n = name.removeprefix("Raylib").removesuffix("2026").removesuffix("Lite")
    return re.sub(r"([A-Z])", r" \1", n).strip()

def card(name, size_mb):
    url   = f"{BASE_URL}/{name}.apk"
    dname = display_name(name)
    return f"""\
      <div class="card">
        <div class="card-body">
          <h6 class="card-title">{dname}</h6>
          <small class="text-muted">{size_mb} MB</small>
        </div>
        <div class="card-footer">
          <a href="{url}" class="btn btn-sm btn-primary w-100" download="{name}.apk">
            &#x2B07; Download APK
          </a>
        </div>
      </div>"""

# ── Build page ────────────────────────────────────────────────────────────────

def build_html(entries):
    classics = [(n, s) for n, s in entries if n in CLASSIC_NAMES]
    games    = [(n, s) for n, s in entries if n not in CLASSIC_NAMES]
    total    = len(entries)

    cards_classics = "\n".join(card(n, s) for n, s in classics)
    cards_games    = "\n".join(card(n, s) for n, s in games)

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>MoonBit Raylib Android Games</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
  <style>
    body {{ background: #0d1117; color: #e6edf3; }}
    .hero {{ background: linear-gradient(135deg,#1f2a3c,#0d1117); padding: 3rem 0; }}
    .hero h1 {{ font-size: 2.5rem; font-weight: 700; }}
    .hero p {{ color: #8b949e; }}
    .section-title {{ color: #58a6ff; border-bottom: 1px solid #30363d; padding-bottom: .5rem; margin: 2rem 0 1rem; }}
    .card {{
      background: #161b22; border: 1px solid #30363d;
      border-radius: 8px; overflow: hidden;
      display: flex; flex-direction: column;
    }}
    .card-body {{ padding: .75rem; flex: 1; }}
    .card-title {{ color: #e6edf3; font-size: .85rem; margin: 0 0 .25rem; line-height: 1.3; }}
    .card-footer {{ background: transparent; border-top: 1px solid #30363d; padding: .5rem; }}
    .btn-primary {{ background: #238636; border-color: #238636; font-size: .78rem; }}
    .btn-primary:hover {{ background: #2ea043; border-color: #2ea043; }}
    .grid {{ display: grid; grid-template-columns: repeat(auto-fill, minmax(180px, 1fr)); gap: .75rem; }}
    .badge-count {{ background: #21262d; color: #8b949e; font-size: .8rem; padding: .2rem .6rem; border-radius: 12px; }}
    input#search {{ background: #21262d; border: 1px solid #30363d; color: #e6edf3; border-radius: 6px; padding: .4rem .8rem; width: 100%; max-width: 400px; }}
    input#search::placeholder {{ color: #8b949e; }}
    input#search:focus {{ outline: none; border-color: #58a6ff; }}
  </style>
</head>
<body>
  <div class="hero text-center">
    <div class="container">
      <h1>&#x1F3AE; MoonBit Raylib Android Games</h1>
      <p class="lead">{total} games built with <strong>MoonBit</strong> + <strong>Raylib</strong> for Android</p>
      <input id="search" type="text" placeholder="&#x1F50D; Search games..." oninput="filterCards(this.value)">
    </div>
  </div>

  <div class="container py-4">

    <h5 class="section-title">Classic Ports <span class="badge-count">{len(classics)}</span></h5>
    <div class="grid" id="classics-grid">
{cards_classics}
    </div>

    <h5 class="section-title">2026 Original Games <span class="badge-count">{len(games)}</span></h5>
    <div class="grid" id="games-grid">
{cards_games}
    </div>

    <p class="text-center mt-5" style="color:#8b949e;font-size:.8rem">
      Built from <a href="https://github.com/moonbit-community/tonyfettes-raylib-android-games" style="color:#58a6ff">moonbit-community/tonyfettes-raylib-android-games</a>
    </p>
  </div>

  <script>
    function filterCards(q) {{
      q = q.toLowerCase();
      document.querySelectorAll('.card').forEach(c => {{
        const title = c.querySelector('.card-title').textContent.toLowerCase();
        c.style.display = title.includes(q) ? '' : 'none';
      }});
    }}
  </script>
</body>
</html>"""

# ── Main ──────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    print(f"Listing APKs from s3://{S3_BUCKET} ({AWS_REGION})...")
    entries = list_apks()
    print(f"Found {len(entries)} APKs.")

    html = build_html(entries)

    os.makedirs(OUTPUT_DIR, exist_ok=True)
    out = os.path.join(OUTPUT_DIR, "index.html")
    with open(out, "w") as f:
        f.write(html)
    print(f"Written: {out}")
