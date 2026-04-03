from pathlib import Path
from xml.sax.saxutils import escape


WIDTH = 2300
HEIGHT = 1450


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


def layer(x, y, w, h, title, subtitle, items, fill, stroke):
    chips = []
    chip_x = x + 40
    chip_y = y + 118
    for item in items:
        chip_w = min(max(140, 18 * len(item)), w - 80)
        if chip_x + chip_w > x + w - 30:
            chip_x = x + 40
            chip_y += 56
        chips.append(
            f'<g><rect x="{chip_x}" y="{chip_y}" width="{chip_w}" height="40" rx="20" fill="white" stroke="{stroke}" stroke-width="1.5"/>'
            + text_block(chip_x + chip_w / 2, chip_y + 23, [item], size=16, weight="700", fill="#334155")
            + "</g>"
        )
        chip_x += chip_w + 14
    return f"""
    <g>
      <rect x="{x}" y="{y}" width="{w}" height="{h}" rx="26" fill="{fill}" stroke="{stroke}" stroke-width="3"/>
      {text_block(x + w / 2, y + 34, [title], size=30, weight="900")}
      {text_block(x + w / 2, y + 72, [subtitle], size=18, weight="500", fill="#475569")}
      {' '.join(chips)}
    </g>
    """


def side_box(x, y, w, h, title, lines, fill, stroke):
    return f"""
    <g>
      <rect x="{x}" y="{y}" width="{w}" height="{h}" rx="24" fill="{fill}" stroke="{stroke}" stroke-width="3"/>
      {text_block(x + w / 2, y + 36, [title], size=28, weight="800")}
      {text_block(x + w / 2, y + h / 2 + 10, lines, size=20, weight="500", fill="#334155", line_gap=8)}
    </g>
    """


def arrow(x1, y1, x2, y2, label=None):
    label_svg = ""
    if label:
        label_svg = f"""
        <g>
          <rect x="{(x1 + x2) / 2 - 115:.1f}" y="{(y1 + y2) / 2 - 42:.1f}" width="230" height="34" rx="10" fill="white" stroke="#cbd5e1" stroke-width="1.5"/>
          {text_block((x1 + x2) / 2, (y1 + y2) / 2 - 23, [label], size=15, weight="700", fill="#475569")}
        </g>
        """
    return f"""
    <g>
      <line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="#475569" stroke-width="4" marker-end="url(#arrow)"/>
      {label_svg}
    </g>
    """


output_dir = Path(__file__).resolve().parent
svg_path = output_dir / "flutter-layers-usmba-social.svg"
html_path = output_dir / "flutter-layers-usmba-social.html"


parts = []
parts.append(f'<rect x="0" y="0" width="{WIDTH}" height="{HEIGHT}" fill="#f8fafc"/>')
parts.append(text_block(WIDTH / 2, 56, ["Architecture Flutter - Couches du framework pour USMBA Social"], size=34, weight="900"))
parts.append(text_block(WIDTH / 2, 96, ["Representation adaptee a l'application web et mobile realisee avec Flutter"], size=20, weight="500", fill="#475569"))

# Main layers
main_x = 170
main_w = 1350
layer_h = 215
gap = 28
start_y = 160

parts.append(layer(
    main_x, start_y, main_w, layer_h,
    "1. Couche Application USMBA Social",
    "Logique specifique du projet et composants fonctionnels",
    [
        "main.dart", "screens/", "widgets/", "theme/",
        "AuthProvider", "FeedProvider", "UserProvider",
        "NotificationProvider", "FacultyProvider"
    ],
    "#dbeafe", "#60a5fa"
))

parts.append(layer(
    main_x, start_y + (layer_h + gap), main_w, layer_h,
    "2. Couche Flutter Framework",
    "Widgets, Material Design, navigation, rendering, animations",
    [
        "MaterialApp", "Scaffold", "Navigator", "Widgets",
        "StatefulWidget", "StatelessWidget", "Provider",
        "Animations", "Gestures", "Rendering"
    ],
    "#e0f2fe", "#38bdf8"
))

parts.append(layer(
    main_x, start_y + 2 * (layer_h + gap), main_w, layer_h,
    "3. Couche Services et communication",
    "Acces aux API, temps reel, stockage local et plugins",
    [
        "api_service.dart", "auth_service.dart", "post_service.dart",
        "chat_service.dart", "story_service.dart", "realtime_service.dart",
        "http", "socket_io_client", "shared_preferences",
        "google_sign_in", "image_picker", "file_picker"
    ],
    "#ede9fe", "#8b5cf6"
))

parts.append(layer(
    main_x, start_y + 3 * (layer_h + gap), main_w, layer_h,
    "4. Couche Platform / Engine",
    "Execution multi-plateforme sur Web, Android et iOS",
    [
        "Flutter Engine", "Dart Runtime", "Skia / rendu",
        "Web Browser", "Android Embedder", "iOS Embedder",
        "Platform Channels", "Plugins natifs"
    ],
    "#dcfce7", "#22c55e"
))

# Right side boxes
parts.append(side_box(
    1630, 270, 520, 250,
    "Backend et donnees",
    [
        "API REST Node.js / Express",
        "Socket.IO pour le temps reel",
        "MongoDB Atlas pour la persistance",
        "JWT pour l'authentification"
    ],
    "#fff7ed", "#fb923c"
))

parts.append(side_box(
    1630, 620, 520, 250,
    "Flux de fonctionnement",
    [
        "Screens et widgets consomment les Providers",
        "Les Providers pilotent les services",
        "Les services appellent l'API ou le WebSocket",
        "Les reponses mettent a jour l'interface"
    ],
    "#ffffff", "#cbd5e1"
))

parts.append(side_box(
    1630, 970, 520, 250,
    "Plateformes cibles",
    [
        "Application Web",
        "Application Android",
        "Application iOS",
        "Base de code Flutter unique"
    ],
    "#fefce8", "#eab308"
))

# Arrows between layers
center_x = main_x + main_w / 2
parts.append(arrow(center_x, start_y + layer_h, center_x, start_y + layer_h + gap, "s'appuie sur"))
parts.append(arrow(center_x, start_y + 2 * layer_h + gap, center_x, start_y + 2 * layer_h + 2 * gap, "utilise"))
parts.append(arrow(center_x, start_y + 3 * layer_h + 2 * gap, center_x, start_y + 3 * layer_h + 3 * gap, "s'execute sur"))

# Arrows to backend and platforms
parts.append(arrow(main_x + main_w, start_y + 2 * (layer_h + gap) + 100, 1630, 395, "HTTP / WebSocket"))
parts.append(arrow(main_x + main_w, start_y + 3 * (layer_h + gap) + 110, 1630, 1095, "Web / Android / iOS"))

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
  <title>Architecture Flutter - Couches du framework</title>
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
