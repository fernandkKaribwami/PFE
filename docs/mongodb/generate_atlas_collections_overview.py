from pathlib import Path
from xml.sax.saxutils import escape


WIDTH = 2200
HEIGHT = 1450

COLLECTIONS = [
    ("comments", 4, "#e0f2fe"),
    ("events", 0, "#fef3c7"),
    ("faculties", 11, "#dcfce7"),
    ("groups", 0, "#fce7f3"),
    ("messages", 6, "#ede9fe"),
    ("notifications", 13, "#dbeafe"),
    ("posts", 3, "#fef9c3"),
    ("reports", 0, "#fee2e2"),
    ("saves", 0, "#f3f4f6"),
    ("stories", 0, "#fae8ff"),
    ("users", 8, "#cffafe"),
]


def text_block(x, y, lines, size=22, weight="400", anchor="middle", fill="#0f172a", line_gap=8):
    line_height = size + line_gap
    start_y = y - ((len(lines) - 1) * line_height) / 2
    parts = []
    for i, line in enumerate(lines):
        parts.append(
            f'<text x="{x}" y="{start_y + i * line_height:.1f}" '
            f'font-size="{size}" font-weight="{weight}" text-anchor="{anchor}" '
            f'font-family="Segoe UI, Arial, sans-serif" fill="{fill}">{escape(line)}</text>'
        )
    return "\n".join(parts)


def card(x, y, w, h, title, count, fill):
    return f"""
    <g>
      <rect x="{x}" y="{y}" width="{w}" height="{h}" rx="22" fill="{fill}" stroke="#cbd5e1" stroke-width="2.5"/>
      <rect x="{x+18}" y="{y+18}" width="{w-36}" height="44" rx="14" fill="white" stroke="#e2e8f0" stroke-width="1.5"/>
      {text_block(x + 34, y + 42, [title], size=22, weight="800", anchor="start")}
      <circle cx="{x + w - 54}" cy="{y + 40}" r="22" fill="#0f172a"/>
      {text_block(x + w - 54, y + 42, [str(count)], size=18, weight="800", fill="white")}
      {text_block(x + w / 2, y + 100, ["Collection MongoDB"], size=18, weight="600", fill="#475569")}
      {text_block(x + w / 2, y + 146, [f"{count} document(s)"], size=24, weight="800", fill="#0f172a")}
    </g>
    """


output_dir = Path(__file__).resolve().parent
svg_path = output_dir / "mongodb-atlas-collections-usmba.svg"
html_path = output_dir / "mongodb-atlas-collections-usmba.html"

parts = []
parts.append(f'<rect x="0" y="0" width="{WIDTH}" height="{HEIGHT}" fill="#f8fafc"/>')
parts.append(text_block(WIDTH / 2, 54, ["Interface MongoDB Atlas - Visualisation des collections"], size=34, weight="900"))
parts.append(text_block(WIDTH / 2, 94, ["Cluster0 - Base de donnees : usmba_db"], size=20, weight="500", fill="#475569"))

# Header area
parts.append(
    """
    <g>
      <rect x="120" y="150" width="1960" height="150" rx="28" fill="#ffffff" stroke="#cbd5e1" stroke-width="3"/>
      <rect x="155" y="185" width="280" height="52" rx="18" fill="#dcfce7" stroke="#86efac" stroke-width="2"/>
    </g>
    """
)
parts.append(text_block(295, 214, ["MongoDB Atlas"], size=24, weight="900", fill="#166534"))
parts.append(text_block(1110, 212, ["Projet : USMBA Social"], size=28, weight="800"))
parts.append(text_block(1715, 212, ["Total collections : 11"], size=24, weight="700", fill="#334155"))
parts.append(text_block(1110, 254, ["Visualisation reelle des collections presentes dans la base usmba_db"], size=18, weight="500", fill="#64748b"))

# Main panel
parts.append(
    """
    <g>
      <rect x="120" y="350" width="1960" height="930" rx="30" fill="#ffffff" stroke="#cbd5e1" stroke-width="3"/>
      <rect x="160" y="385" width="420" height="56" rx="18" fill="#f1f5f9" stroke="#cbd5e1" stroke-width="2"/>
    </g>
    """
)
parts.append(text_block(370, 416, ["Collections / Tables"], size=26, weight="800"))

# Cards grid
start_x = 170
start_y = 480
card_w = 320
card_h = 180
gap_x = 28
gap_y = 28

for idx, (name, count, fill) in enumerate(COLLECTIONS):
    row = idx // 5
    col = idx % 5
    x = start_x + col * (card_w + gap_x)
    y = start_y + row * (card_h + gap_y)
    parts.append(card(x, y, card_w, card_h, name, count, fill))

# Insight panel
parts.append(
    """
    <g>
      <rect x="160" y="1125" width="1880" height="115" rx="22" fill="#f8fafc" stroke="#e2e8f0" stroke-width="2"/>
    </g>
    """
)
parts.append(text_block(1100, 1158, ["Collections les plus alimentees : notifications (13), faculties (11), users (8), messages (6), comments (4), posts (3)"], size=19, weight="700", fill="#334155"))
parts.append(text_block(1100, 1200, ["Les collections events, groups, reports, saves et stories sont presentes mais actuellement vides."], size=18, weight="500", fill="#64748b"))

svg = f"""<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="{WIDTH}" height="{HEIGHT}" viewBox="0 0 {WIDTH} {HEIGHT}">
  {' '.join(parts)}
</svg>
"""

html = f"""<!doctype html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <title>MongoDB Atlas - Collections usmba_db</title>
  <style>
    html, body {{
      margin: 0;
      padding: 0;
      background: #f8fafc;
      width: {WIDTH}px;
      height: {HEIGHT}px;
      overflow: hidden;
    }}
    .wrap {{
      width: {WIDTH}px;
      height: {HEIGHT}px;
    }}
    svg {{
      display: block;
      width: {WIDTH}px;
      height: {HEIGHT}px;
    }}
  </style>
</head>
<body>
  <div class="wrap">
    {svg}
  </div>
</body>
</html>
"""

svg_path.write_text(svg, encoding="utf-8")
html_path.write_text(html, encoding="utf-8")

print(svg_path)
print(html_path)
