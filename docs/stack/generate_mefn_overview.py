from pathlib import Path
from xml.sax.saxutils import escape


WIDTH = 2200
HEIGHT = 1300


def text_block(x, y, lines, size=22, weight="400", anchor="middle", fill="#0f172a", line_gap=8):
    line_height = size + line_gap
    start_y = y - ((len(lines) - 1) * line_height) / 2
    items = []
    for i, line in enumerate(lines):
        items.append(
            f'<text x="{x}" y="{start_y + i * line_height:.1f}" '
            f'font-size="{size}" font-weight="{weight}" text-anchor="{anchor}" '
            f'font-family="Segoe UI, Arial, sans-serif" fill="{fill}">{escape(line)}</text>'
        )
    return "\n".join(items)


def card(x, y, w, h, title, subtitle_lines, accent, tag):
    return f"""
    <g>
      <rect x="{x}" y="{y}" width="{w}" height="{h}" rx="22" fill="white" stroke="#cbd5e1" stroke-width="3"/>
      <rect x="{x}" y="{y}" width="{w}" height="16" rx="22" fill="{accent}" stroke="none"/>
      <circle cx="{x + 60}" cy="{y + 70}" r="34" fill="{accent}"/>
      {text_block(x + 60, y + 73, [tag], size=34, weight="800", fill="white")}
      {text_block(x + w / 2 + 10, y + 58, [title], size=26, weight="800")}
      {text_block(x + w / 2, y + 122, subtitle_lines, size=18, weight="500", fill="#475569", line_gap=6)}
    </g>
    """


def module_box(x, y, w, h, title, lines, fill, stroke="#94a3b8"):
    return f"""
    <g>
      <rect x="{x}" y="{y}" width="{w}" height="{h}" rx="24" fill="{fill}" stroke="{stroke}" stroke-width="3"/>
      {text_block(x + w / 2, y + 38, [title], size=28, weight="800")}
      {text_block(x + w / 2, y + h / 2 + 12, lines, size=20, weight="500", fill="#334155", line_gap=8)}
    </g>
    """


def chip(x, y, w, text, fill="#ffffff", stroke="#cbd5e1"):
    return f"""
    <g>
      <rect x="{x}" y="{y}" width="{w}" height="48" rx="24" fill="{fill}" stroke="{stroke}" stroke-width="2"/>
      {text_block(x + w / 2, y + 28, [text], size=18, weight="700", fill="#334155")}
    </g>
    """


def arrow(x1, y1, x2, y2, label=None):
    label_svg = ""
    if label:
      label_svg = f"""
      <g>
        <rect x="{(x1 + x2) / 2 - 95:.1f}" y="{(y1 + y2) / 2 - 38:.1f}" width="190" height="34" rx="10" fill="white" stroke="#cbd5e1" stroke-width="1.5"/>
        {text_block((x1 + x2) / 2, (y1 + y2) / 2 - 19, [label], size=15, weight="700", fill="#475569")}
      </g>
      """
    return f"""
    <g>
      <line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="#475569" stroke-width="4" marker-end="url(#arrow)"/>
      {label_svg}
    </g>
    """


output_dir = Path(__file__).resolve().parent
svg_path = output_dir / "mefn-stack-overview.svg"
html_path = output_dir / "mefn-stack-overview.html"

parts = []

parts.append(f'<rect x="0" y="0" width="{WIDTH}" height="{HEIGHT}" fill="#f8fafc"/>')
parts.append(text_block(WIDTH / 2, 52, ["Vue d'ensemble de la stack technologique MEFN"], size=34, weight="900"))
parts.append(text_block(WIDTH / 2, 92, ["USMBA Social - MongoDB, Express.js, Flutter, Node.js"], size=20, weight="500", fill="#475569"))

# Top MEFN cards
parts.append(card(110, 140, 430, 185, "MongoDB", ["Base de donnees documentaire", "MongoDB Atlas + Mongoose"], "#22c55e", "M"))
parts.append(card(600, 140, 430, 185, "Express.js", ["API REST, routes, middlewares", "CORS, Helmet, rate limit"], "#f59e0b", "E"))
parts.append(card(1090, 140, 430, 185, "Flutter", ["Application web et mobile", "Dart + Provider + UI reactive"], "#3b82f6", "F"))
parts.append(card(1580, 140, 430, 185, "Node.js", ["Runtime backend", "Socket.IO, JWT, Multer"], "#6366f1", "N"))

# Main flow
parts.append(module_box(120, 430, 280, 220, "Utilisateurs", ["Etudiants", "Enseignants", "Administrateurs"], "#ffffff"))
parts.append(module_box(470, 390, 500, 310, "Frontend Flutter / Dart", ["Web, Android, iOS", "Provider pour l'etat", "SharedPreferences pour le token", "socket_io_client pour le temps reel", "google_sign_in pour OAuth"], "#dbeafe", "#60a5fa"))
parts.append(module_box(1040, 390, 560, 310, "Backend Node.js + Express", ["API REST centralisee", "JWT pour l'authentification", "Multer pour les uploads", "Socket.IO pour messages et notifications", "Helmet, CORS, compression, rate limiting"], "#ede9fe", "#8b5cf6"))
parts.append(module_box(1670, 430, 400, 220, "MongoDB Atlas", ["Collections :", "users, posts, messages,", "stories, notifications,", "reports, groupes, evenements"], "#dcfce7", "#4ade80"))

parts.append(arrow(400, 540, 470, 540, "Interaction"))
parts.append(arrow(970, 540, 1040, 540, "HTTP REST + WebSocket"))
parts.append(arrow(1600, 540, 1670, 540, "Mongoose ODM"))

# Bottom chips
parts.append(text_block(WIDTH / 2, 780, ["Technologies complementaires utilisees dans le projet"], size=24, weight="800"))

chip_specs = [
    (170, 830, 180, "Socket.IO", "#ffffff"),
    (380, 830, 170, "JWT", "#ffffff"),
    (580, 830, 190, "Multer", "#ffffff"),
    (800, 830, 240, "SharedPreferences", "#ffffff"),
    (1070, 830, 220, "Google Sign-In", "#ffffff"),
    (1320, 830, 260, "Cached Network Image", "#ffffff"),
    (1610, 830, 160, "Helmet", "#ffffff"),
    (1800, 830, 140, "CORS", "#ffffff"),
    (420, 900, 210, "Compression", "#ffffff"),
    (660, 900, 200, "Rate Limit", "#ffffff"),
    (890, 900, 170, "Sharp", "#ffffff"),
    (1090, 900, 170, "Supertest", "#ffffff"),
    (1290, 900, 210, "Node Test", "#ffffff"),
    (1530, 900, 180, "HTTP", "#ffffff"),
    (1740, 900, 170, "Provider", "#ffffff"),
]

for spec in chip_specs:
    parts.append(chip(*spec))

parts.append(
    module_box(
        250,
        1000,
        1700,
        180,
        "Role de chaque composant dans l'architecture",
        [
            "Flutter gere l'interface utilisateur et l'experience multi-plateforme.",
            "Express structure les routes et la logique API du backend.",
            "Node.js execute le serveur et les communications temps reel.",
            "MongoDB stocke les donnees sociales de l'application USMBA Social."
        ],
        "#ffffff",
        "#cbd5e1",
    )
)

svg = f"""<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="{WIDTH}" height="{HEIGHT}" viewBox="0 0 {WIDTH} {HEIGHT}">
  <defs>
    <marker id="arrow" markerWidth="14" markerHeight="14" refX="10" refY="7" orient="auto" markerUnits="strokeWidth">
      <path d="M 0 0 L 14 7 L 0 14 z" fill="#475569"/>
    </marker>
  </defs>
  {' '.join(parts)}
</svg>
"""

html = f"""<!doctype html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <title>Vue d'ensemble de la stack MEFN</title>
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
