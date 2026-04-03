from pathlib import Path
from xml.sax.saxutils import escape


WIDTH = 2300
HEIGHT = 1450


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


def box(x, y, w, h, title, lines, fill, stroke, title_size=28):
    return f"""
    <g>
      <rect x="{x}" y="{y}" width="{w}" height="{h}" rx="24" fill="{fill}" stroke="{stroke}" stroke-width="3"/>
      {text_block(x + w / 2, y + 36, [title], size=title_size, weight="800")}
      {text_block(x + w / 2, y + h / 2 + 10, lines, size=20, weight="500", fill="#334155", line_gap=8)}
    </g>
    """


def pill(x, y, w, h, title, fill, stroke="#94a3b8", size=18):
    return f"""
    <g>
      <rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{h/2:.1f}" fill="{fill}" stroke="{stroke}" stroke-width="2"/>
      {text_block(x + w / 2, y + h / 2 + 1, [title], size=size, weight="700", fill="#0f172a")}
    </g>
    """


def arrow(x1, y1, x2, y2, label=None, dashed=False):
    dash = ' stroke-dasharray="10 8"' if dashed else ""
    label_svg = ""
    if label:
        label_svg = f"""
        <g>
          <rect x="{(x1 + x2) / 2 - 120:.1f}" y="{(y1 + y2) / 2 - 40:.1f}" width="240" height="34" rx="10" fill="white" stroke="#cbd5e1" stroke-width="1.5"/>
          {text_block((x1 + x2) / 2, (y1 + y2) / 2 - 21, [label], size=15, weight="700", fill="#475569")}
        </g>
        """
    return f"""
    <g>
      <line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="#475569" stroke-width="4" marker-end="url(#arrow)"{dash}/>
      {label_svg}
    </g>
    """


output_dir = Path(__file__).resolve().parent
svg_path = output_dir / "node-event-loop-usmba-social.svg"
html_path = output_dir / "node-event-loop-usmba-social.html"


parts = []
parts.append(f'<rect x="0" y="0" width="{WIDTH}" height="{HEIGHT}" fill="#f8fafc"/>')
parts.append(text_block(WIDTH / 2, 54, ["Modele d'execution Node.js - Event Loop"], size=34, weight="900"))
parts.append(text_block(WIDTH / 2, 94, ["Application USMBA Social - Express, Socket.IO, MongoDB, Mongoose"], size=20, weight="500", fill="#475569"))

# Left input box
parts.append(box(
    80, 250, 460, 260,
    "Entrees de l'application",
    [
        "Requetes HTTP vers Express",
        "Connexion des clients Socket.IO",
        "Actions utilisateur : login, posts, messages, stories",
        "Uploads et appels API depuis Flutter"
    ],
    "#dbeafe", "#60a5fa"
))

# Call stack
parts.append(box(
    640, 270, 340, 220,
    "Call Stack",
    [
        "Execution JavaScript",
        "Handlers Express",
        "Socket.IO callbacks",
        "Fonctions synchrones"
    ],
    "#ffffff", "#cbd5e1"
))

# Event loop container
parts.append(
    """
    <g>
      <rect x="1040" y="170" width="820" height="760" rx="34" fill="#ffffff" stroke="#cbd5e1" stroke-width="3"/>
    </g>
    """
)
parts.append(text_block(1450, 205, ["Event Loop Node.js"], size=32, weight="900"))
parts.append(text_block(1450, 240, ["Coordonne les callbacks et les operations asynchrones"], size=18, weight="500", fill="#475569"))

# Loop phases
phases = [
    (1350, 300, 220, 70, "Timers", "#fef3c7"),
    (1600, 395, 220, 70, "Pending Callbacks", "#fde68a"),
    (1610, 515, 200, 60, "Idle / Prepare", "#f3f4f6"),
    (1350, 610, 220, 80, "Poll", "#dbeafe"),
    (1090, 515, 200, 60, "Check", "#ede9fe"),
    (1080, 395, 220, 70, "Close Callbacks", "#fee2e2"),
]

for x, y, w, h, title, fill in phases:
    parts.append(pill(x, y, w, h, title, fill))

parts.append(
    """
    <g>
      <ellipse cx="1450" cy="495" rx="180" ry="95" fill="#ecfeff" stroke="#22d3ee" stroke-width="3"/>
    </g>
    """
)
parts.append(text_block(1450, 495, ["Boucle d'evenements", "Event Loop"], size=24, weight="800"))

# Microtasks
parts.append(box(
    1180, 760, 540, 120,
    "File de microtaches",
    [
        "Promises, async/await, process.nextTick",
        "Executees entre les phases de la boucle"
    ],
    "#f5f3ff", "#a78bfa",
    title_size=26
))

# Right async resources
parts.append(box(
    1910, 250, 320, 250,
    "Sources asynchrones",
    [
        "MongoDB / Mongoose",
        "Sockets reseau",
        "Fichiers uploades",
        "Timers",
        "Operations I/O"
    ],
    "#dcfce7", "#4ade80"
))

parts.append(box(
    1910, 600, 320, 250,
    "Callback Queues",
    [
        "Callbacks prets a etre executes",
        "Evenements reseau",
        "Reponses MongoDB",
        "Messages Socket.IO"
    ],
    "#fff7ed", "#fb923c"
))

# Bottom project adaptation
parts.append(box(
    180, 1040, 1940, 250,
    "Adaptation au backend USMBA Social",
    [
        "Les routes Express gerent les requetes HTTP entrantes du frontend Flutter.",
        "Les acces MongoDB via Mongoose sont non bloquants et reviennent dans l'Event Loop apres completion.",
        "Socket.IO ecoute les evenements comme typing, sendMessage et notification.",
        "Le modele Node.js permet de traiter plusieurs operations concurrentes sans bloquer le thread principal."
    ],
    "#ffffff", "#cbd5e1",
    title_size=30
))

# Extra project pills
parts.append(pill(250, 870, 240, 52, "Express Routes", "#ffffff"))
parts.append(pill(520, 870, 220, 52, "Socket.IO", "#ffffff"))
parts.append(pill(770, 870, 250, 52, "MongoDB / Mongoose", "#ffffff"))
parts.append(pill(1770, 760, 110, 46, "libuv", "#ffffff"))

# Arrows
parts.append(arrow(540, 380, 640, 380, "callbacks JS"))
parts.append(arrow(980, 380, 1040, 380, "alimente la boucle"))
parts.append(arrow(1860, 380, 1910, 380, "I/O externe"))
parts.append(arrow(1910, 725, 1860, 640, "callbacks prets"))
parts.append(arrow(1450, 690, 1450, 760, "entre les phases", dashed=True))
parts.append(arrow(1570, 650, 1910, 725, "retour des operations async", dashed=True))
parts.append(arrow(1450, 930, 1450, 1040, "impact sur l'application"))
parts.append(arrow(980, 870, 1800, 870, "operations asynchrones typiques", dashed=True))

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
  <title>Modele d'execution Node.js - Event Loop</title>
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
