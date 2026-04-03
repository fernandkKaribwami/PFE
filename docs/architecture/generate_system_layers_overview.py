from pathlib import Path
from xml.sax.saxutils import escape


WIDTH = 2300
HEIGHT = 1500


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


def layer(x, y, w, h, title, subtitle, chips, fill, stroke):
    chip_parts = []
    chip_x = x + 40
    chip_y = y + 110
    for chip in chips:
        chip_w = min(max(160, len(chip) * 16), w - 80)
        if chip_x + chip_w > x + w - 30:
            chip_x = x + 40
            chip_y += 54
        chip_parts.append(
            f'<g><rect x="{chip_x}" y="{chip_y}" width="{chip_w}" height="40" rx="20" fill="white" stroke="{stroke}" stroke-width="1.5"/>'
            + text_block(chip_x + chip_w / 2, chip_y + 23, [chip], size=16, weight="700", fill="#334155")
            + "</g>"
        )
        chip_x += chip_w + 14
    return f"""
    <g>
      <rect x="{x}" y="{y}" width="{w}" height="{h}" rx="26" fill="{fill}" stroke="{stroke}" stroke-width="3"/>
      {text_block(x + w / 2, y + 34, [title], size=30, weight="900")}
      {text_block(x + w / 2, y + 70, [subtitle], size=18, weight="500", fill="#475569")}
      {' '.join(chip_parts)}
    </g>
    """


def side_box(x, y, w, h, title, lines, fill, stroke):
    return f"""
    <g>
      <rect x="{x}" y="{y}" width="{w}" height="{h}" rx="24" fill="{fill}" stroke="{stroke}" stroke-width="3"/>
      {text_block(x + w / 2, y + 36, [title], size=28, weight="800")}
      {text_block(x + w / 2, y + h / 2 + 6, lines, size=20, weight="500", fill="#334155", line_gap=8)}
    </g>
    """


def arrow(x1, y1, x2, y2, label=None):
    label_svg = ""
    if label:
        label_svg = f"""
        <g>
          <rect x="{(x1 + x2) / 2 - 110:.1f}" y="{(y1 + y2) / 2 - 40:.1f}" width="220" height="34" rx="10" fill="white" stroke="#cbd5e1" stroke-width="1.5"/>
          {text_block((x1 + x2) / 2, (y1 + y2) / 2 - 21, [label], size=15, weight="700", fill="#475569")}
        </g>
        """
    return f"""
    <g>
      <line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="#475569" stroke-width="4" marker-end="url(#arrow)"/>
      {label_svg}
    </g>
    """


output_dir = Path(__file__).resolve().parent
svg_path = output_dir / "usmba-social-system-layers.svg"
html_path = output_dir / "usmba-social-system-layers.html"

parts = []
parts.append(f'<rect x="0" y="0" width="{WIDTH}" height="{HEIGHT}" fill="#f8fafc"/>')
parts.append(text_block(WIDTH / 2, 54, ["Architecture globale du systeme USMBA Social - Vue en couches"], size=34, weight="900"))
parts.append(text_block(WIDTH / 2, 94, ["Architecture client - serveur avec temps reel, persistance MongoDB et application Flutter"], size=20, weight="500", fill="#475569"))

main_x = 130
main_w = 1520
layer_h = 180
gap = 26
start_y = 150

parts.append(layer(
    main_x, start_y, main_w, layer_h,
    "1. Couche Utilisateurs",
    "Acteurs qui interagissent avec la plateforme",
    ["Etudiants", "Enseignants", "Administrateurs"],
    "#ffffff", "#cbd5e1"
))

parts.append(layer(
    main_x, start_y + (layer_h + gap), main_w, layer_h,
    "2. Couche Presentation / Client",
    "Application Flutter web et mobile",
    [
        "screens/", "widgets/", "theme/", "MultiProvider",
        "AuthProvider", "FeedProvider", "UserProvider",
        "NotificationProvider", "FacultyProvider"
    ],
    "#dbeafe", "#60a5fa"
))

parts.append(layer(
    main_x, start_y + 2 * (layer_h + gap), main_w, layer_h,
    "3. Couche Communication",
    "Echanges entre frontend et backend",
    ["HTTP / JSON", "JWT Bearer", "Socket.IO", "Multipart uploads"],
    "#ede9fe", "#8b5cf6"
))

parts.append(layer(
    main_x, start_y + 3 * (layer_h + gap), main_w, layer_h,
    "4. Couche API et services backend",
    "Serveur Node.js / Express et logique applicative",
    [
        "app.js", "server.js", "routes/auth", "routes/users", "routes/posts",
        "routes/messages", "routes/stories", "routes/notifications",
        "helmet", "cors", "compression", "rate-limit", "socket.js"
    ],
    "#dcfce7", "#22c55e"
))

parts.append(layer(
    main_x, start_y + 4 * (layer_h + gap), main_w, layer_h,
    "5. Couche Donnees et persistance",
    "Modeles Mongoose, base MongoDB Atlas et stockage des fichiers",
    [
        "models/User", "models/Post", "models/Message", "models/Story",
        "models/Notification", "models/Faculty", "models/Group", "models/Event",
        "MongoDB Atlas", "uploads/"
    ],
    "#fff7ed", "#fb923c"
))

# Side boxes
parts.append(side_box(
    1710, 220, 470, 260,
    "Plateformes clientes",
    [
        "Flutter Web",
        "Android",
        "iOS",
        "Base de code unique"
    ],
    "#ffffff", "#cbd5e1"
))

parts.append(side_box(
    1710, 570, 470, 280,
    "Modules fonctionnels",
    [
        "Authentification",
        "Profils et recherche",
        "Posts et commentaires",
        "Messagerie et stories",
        "Notifications et administration"
    ],
    "#fefce8", "#eab308"
))

parts.append(side_box(
    1710, 950, 470, 280,
    "Services externes / support",
    [
        "MongoDB Atlas",
        "Google Sign-In",
        "SMTP optionnel",
        "Temps reel Socket.IO"
    ],
    "#ffffff", "#cbd5e1"
))

# Arrows between layers
center_x = main_x + main_w / 2
parts.append(arrow(center_x, start_y + layer_h, center_x, start_y + layer_h + gap, "utilise"))
parts.append(arrow(center_x, start_y + 2 * layer_h + gap, center_x, start_y + 2 * layer_h + 2 * gap, "transite par"))
parts.append(arrow(center_x, start_y + 3 * layer_h + 2 * gap, center_x, start_y + 3 * layer_h + 3 * gap, "appelle"))
parts.append(arrow(center_x, start_y + 4 * layer_h + 3 * gap, center_x, start_y + 4 * layer_h + 4 * gap, "persiste dans"))

# Side arrows
parts.append(arrow(main_x + main_w, start_y + 270, 1710, 350, "deployment"))
parts.append(arrow(main_x + main_w, start_y + 650, 1710, 710, "modules"))
parts.append(arrow(main_x + main_w, start_y + 1020, 1710, 1090, "integrations"))

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
  <title>Architecture globale du systeme USMBA Social</title>
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
