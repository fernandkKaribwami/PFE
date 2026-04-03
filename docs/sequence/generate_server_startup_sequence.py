from pathlib import Path
from xml.sax.saxutils import escape


WIDTH = 2500
HEIGHT = 1700


PARTICIPANTS = [
    ("Node.js Runtime", 150),
    ("server.js", 420),
    ("app.js / createApp()", 700),
    ("Express App", 980),
    ("HTTP Server", 1260),
    ("socket.js", 1540),
    ("Socket.IO", 1820),
    ("MongoDB Atlas", 2100),
    ("userMaintenance", 2370),
]


def text_block(x, y, lines, size=20, weight="400", anchor="middle", fill="#0f172a", line_gap=6):
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


def participant_box(x, y, label):
    width = 190
    return f"""
    <g>
      <rect x="{x - width/2}" y="{y}" width="{width}" height="58" rx="16" fill="#ffffff" stroke="#94a3b8" stroke-width="2.5"/>
      {text_block(x, y + 34, label.split(' / ') if ' / ' in label else [label], size=18, weight="800")}
    </g>
    """


def lifeline(x, y1, y2):
    return f'<line x1="{x}" y1="{y1}" x2="{x}" y2="{y2}" stroke="#cbd5e1" stroke-width="2.5" stroke-dasharray="10 8"/>'


def message(x1, x2, y, label, dashed=False):
    dash = ' stroke-dasharray="10 8"' if dashed else ""
    return f"""
    <g>
      <line x1="{x1}" y1="{y}" x2="{x2}" y2="{y}" stroke="#334155" stroke-width="3" marker-end="url(#arrow)"{dash}/>
      {text_block((x1 + x2) / 2, y - 12, [label], size=15, weight="700", fill="#475569")}
    </g>
    """


def self_message(x, y, label):
    return f"""
    <g>
      <path d="M {x} {y} h 72 v 32 h -72" fill="none" stroke="#334155" stroke-width="3" marker-end="url(#arrow)"/>
      {text_block(x + 120, y + 12, [label], size=15, weight="700", anchor="start", fill="#475569")}
    </g>
    """


def note(x, y, w, h, title, lines):
    return f"""
    <g>
      <rect x="{x}" y="{y}" width="{w}" height="{h}" rx="18" fill="#fff7ed" stroke="#fdba74" stroke-width="2"/>
      {text_block(x + w / 2, y + 24, [title], size=18, weight="800", fill="#9a3412")}
      {text_block(x + w / 2, y + h / 2 + 12, lines, size=16, weight="500", fill="#7c2d12")}
    </g>
    """


output_dir = Path(__file__).resolve().parent
svg_path = output_dir / "server-startup-sequence.svg"
html_path = output_dir / "server-startup-sequence.html"

parts = []
parts.append(f'<rect x="0" y="0" width="{WIDTH}" height="{HEIGHT}" fill="#f8fafc"/>')
parts.append(text_block(WIDTH / 2, 46, ["Diagramme de sequence - Flux de demarrage du serveur"], size=34, weight="900"))
parts.append(text_block(WIDTH / 2, 84, ["Backend USMBA Social - server.js, app.js, socket.js, MongoDB Atlas"], size=19, weight="500", fill="#475569"))

header_y = 125
lifeline_top = 184
lifeline_bottom = 1450

for label, x in PARTICIPANTS:
    parts.append(participant_box(x, header_y, label))
    parts.append(lifeline(x, lifeline_top, lifeline_bottom))

y = 235
step = 58

parts.append(message(150, 420, y, "Executer le backend"))
y += step
parts.append(self_message(420, y, "Charger .env"))
y += step
parts.append(message(420, 700, y, "createApp()"))
y += step
parts.append(message(700, 980, y, "Initialiser Express"))
y += step
parts.append(message(700, 980, y, "Configurer middlewares"))
y += step
parts.append(message(700, 980, y, "Monter les routes API"))
y += step
parts.append(message(700, 980, y, "Ajouter notFound + errorHandler"))
y += step
parts.append(message(980, 420, y, "Retourner app", dashed=True))
y += step
parts.append(message(420, 1260, y, "http.createServer(app)"))
y += step
parts.append(message(420, 1540, y, "initializeSocket(server)"))
y += step
parts.append(message(1540, 1820, y, "Initialiser Socket.IO"))
y += step
parts.append(message(1820, 420, y, "Retourner io", dashed=True))
y += step
parts.append(message(420, 980, y, "app.set('io', io)"))
y += step
parts.append(self_message(420, y, "connectDB()"))
y += step
parts.append(message(420, 2100, y, "mongoose.connect(MONGODB_URI)"))

# Success block
success_top = y + 28
success_h = 260
parts.append(
    f'<rect x="320" y="{success_top}" width="1900" height="{success_h}" rx="18" fill="none" stroke="#86efac" stroke-width="2.5"/>'
)
parts.append(text_block(455, success_top + 18, ["[Succes]"], size=16, weight="800", fill="#166534"))
y += step + 26
parts.append(message(2100, 420, y, "Connexion OK", dashed=True))
y += step
parts.append(message(420, 2370, y, "backfillEmailVerificationIfDisabled()"))
y += step
parts.append(message(2370, 420, y, "Resultat de synchronisation", dashed=True))
y += step
parts.append(message(420, 2100, y, "Enregistrer listeners error/disconnected/reconnected"))
y += step + 16

# Failure note
parts.append(note(
    1730, success_top + success_h + 20, 420, 110,
    "Cas d'echec de connexion",
    [
        "Si MongoDB n'est pas joignable,",
        "server.js relance connectDB()",
        "apres 5 secondes avec setTimeout."
    ]
))

y += 34
parts.append(self_message(420, y, "Enregistrer SIGTERM et SIGINT"))
y += step
parts.append(message(420, 1260, y, "server.listen(PORT)"))
y += step
parts.append(message(1260, 420, y, "Serveur en ecoute", dashed=True))
y += step
parts.append(self_message(420, y, "Logger le port de demarrage"))

parts.append(note(
    210, 1495, 2080, 120,
    "Resume",
    [
        "Le serveur demarre en initialisant Express, le serveur HTTP, Socket.IO, puis la connexion MongoDB.",
        "Une fois ces etapes preparees, le backend USMBA Social ecoute sur le port configure."
    ]
))

svg = f"""<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="{WIDTH}" height="{HEIGHT}" viewBox="0 0 {WIDTH} {HEIGHT}">
  <defs>
    <marker id="arrow" markerWidth="12" markerHeight="12" refX="10" refY="6" orient="auto" markerUnits="strokeWidth">
      <path d="M 0 0 L 12 6 L 0 12 z" fill="#334155"/>
    </marker>
  </defs>
  {' '.join(parts)}
</svg>
"""

html = f"""<!doctype html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <title>Diagramme de sequence - Flux de demarrage du serveur</title>
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
