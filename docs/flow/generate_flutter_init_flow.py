from pathlib import Path
from xml.sax.saxutils import escape


WIDTH = 1800
HEIGHT = 2200


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


def process_box(x, y, w, h, lines, fill="#ffffff", stroke="#94a3b8"):
    return f"""
    <g>
      <rect x="{x}" y="{y}" width="{w}" height="{h}" rx="18" fill="{fill}" stroke="{stroke}" stroke-width="2.5"/>
      {text_block(x + w / 2, y + h / 2 + 2, lines, size=22, weight="700", fill="#0f172a")}
    </g>
    """


def terminator(x, y, w, h, lines):
    return f"""
    <g>
      <rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{h/2:.1f}" fill="#dbeafe" stroke="#60a5fa" stroke-width="3"/>
      {text_block(x + w / 2, y + h / 2 + 2, lines, size=24, weight="800")}
    </g>
    """


def decision(x, y, w, h, lines):
    cx = x + w / 2
    cy = y + h / 2
    return f"""
    <g>
      <polygon points="{cx},{y} {x+w},{cy} {cx},{y+h} {x},{cy}" fill="#fef3c7" stroke="#f59e0b" stroke-width="3"/>
      {text_block(cx, cy + 2, lines, size=21, weight="800", fill="#92400e")}
    </g>
    """


def arrow(x1, y1, x2, y2, label=None):
    label_svg = ""
    if label:
        label_svg = f"""
        <g>
          <rect x="{(x1 + x2) / 2 - 54:.1f}" y="{(y1 + y2) / 2 - 34:.1f}" width="108" height="28" rx="8" fill="white" stroke="#cbd5e1" stroke-width="1.5"/>
          {text_block((x1 + x2) / 2, (y1 + y2) / 2 - 18, [label], size=14, weight="800", fill="#475569")}
        </g>
        """
    return f"""
    <g>
      <line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="#334155" stroke-width="3" marker-end="url(#arrow)"/>
      {label_svg}
    </g>
    """


def note(x, y, w, h, title, lines):
    return f"""
    <g>
      <rect x="{x}" y="{y}" width="{w}" height="{h}" rx="18" fill="#fff7ed" stroke="#fdba74" stroke-width="2"/>
      {text_block(x + w / 2, y + 22, [title], size=18, weight="800", fill="#9a3412")}
      {text_block(x + w / 2, y + h / 2 + 8, lines, size=16, weight="500", fill="#7c2d12")}
    </g>
    """


output_dir = Path(__file__).resolve().parent
svg_path = output_dir / "flutter-app-initialization-flow.svg"
html_path = output_dir / "flutter-app-initialization-flow.html"

parts = []
parts.append(f'<rect x="0" y="0" width="{WIDTH}" height="{HEIGHT}" fill="#f8fafc"/>')
parts.append(text_block(WIDTH / 2, 46, ["Diagramme de flux - Initialisation de l'application Flutter"], size=34, weight="900"))
parts.append(text_block(WIDTH / 2, 84, ["USMBA Social - Flux base sur main.dart et AppInitializer"], size=19, weight="500", fill="#475569"))

center_x = 670
box_w = 500
box_h = 74
start_x = center_x - box_w / 2
y = 120
gap = 32

parts.append(terminator(start_x + 95, y, 310, 64, ["Debut"]))
y += 96
parts.append(process_box(start_x, y, box_w, box_h, ["main()"]))
y += box_h + gap
parts.append(process_box(start_x, y, box_w, box_h, ["WidgetsFlutterBinding", "ensureInitialized()"], fill="#ffffff"))
y += box_h + gap
parts.append(process_box(start_x, y, box_w, box_h, ["Configurer les orientations"], fill="#ffffff"))
y += box_h + gap
parts.append(process_box(start_x, y, box_w, box_h, ["Configurer System UI Overlay Style"], fill="#ffffff"))
y += box_h + gap
parts.append(process_box(start_x, y, box_w, box_h, ["runApp(MyApp)"], fill="#e0f2fe", stroke="#38bdf8"))
y += box_h + gap
parts.append(process_box(start_x, y, box_w, box_h, ["Creer MultiProvider", "et MaterialApp"], fill="#dbeafe", stroke="#60a5fa"))
y += box_h + gap
parts.append(process_box(start_x, y, box_w, box_h, ["Afficher AppInitializer"], fill="#dbeafe", stroke="#60a5fa"))
y += box_h + gap
parts.append(process_box(start_x, y, box_w, box_h, ["AppInitializer.initState()", "appelle _initializeApp()"], fill="#ede9fe", stroke="#8b5cf6"))
y_init = y
y += box_h + gap
parts.append(process_box(start_x, y, box_w, box_h, ["Lire SharedPreferences", "token + userId"], fill="#ede9fe", stroke="#8b5cf6"))
y += box_h + gap
parts.append(decision(start_x + 45, y, box_w - 90, 140, ["token et userId", "existent ?"]))
decision1_y = y
y += 172
parts.append(process_box(start_x, y, box_w, box_h, ["Recuperer AuthProvider"], fill="#f5f3ff", stroke="#a78bfa"))
y += box_h + gap
parts.append(process_box(start_x, y, box_w, box_h, ["Valider le token", "via /users/profile"], fill="#f5f3ff", stroke="#a78bfa"))
y += box_h + gap
parts.append(decision(start_x + 45, y, box_w - 90, 140, ["token", "valide ?"]))
decision2_y = y

# Right branch boxes
right_x = 1120
parts.append(note(
    1170, y_init - 20, 500, 170,
    "Affichage de l'interface",
    [
        "Pendant l'initialisation,",
        "AppInitializer retourne SplashScreen.",
        "Le logo et l'animation sont affiches",
        "en attendant la suite du flux."
    ]
))

yes_box_y = decision2_y + 190
parts.append(process_box(start_x - 10, yes_box_y, 250, 80, ["Naviguer vers", "/main"], fill="#dcfce7", stroke="#22c55e"))
parts.append(process_box(start_x + 270, yes_box_y, 250, 80, ["Effacer prefs"], fill="#fee2e2", stroke="#ef4444"))
parts.append(process_box(start_x + 270, yes_box_y + 115, 250, 80, ["Naviguer vers", "/auth"], fill="#fee2e2", stroke="#ef4444"))

no_branch_y = decision1_y + 44
parts.append(process_box(1120, no_branch_y, 320, 80, ["Naviguer vers", "/auth"], fill="#fee2e2", stroke="#ef4444"))

end_y = yes_box_y + 260
parts.append(terminator(start_x + 95, end_y, 310, 64, ["Fin du flux d'initialisation"]))

# Arrows vertically
positions = [
    (152, 216), (248, 312), (344, 408), (440, 504),
    (536, 600), (632, 696), (728, 792), (824, 888),
]

# Manual arrows
parts.append(arrow(center_x, 184, center_x, 216))
parts.append(arrow(center_x, 290, center_x, 312))
parts.append(arrow(center_x, 386, center_x, 408))
parts.append(arrow(center_x, 482, center_x, 504))
parts.append(arrow(center_x, 578, center_x, 600))
parts.append(arrow(center_x, 674, center_x, 696))
parts.append(arrow(center_x, 770, center_x, 792))
parts.append(arrow(center_x, 866, center_x, 888))
parts.append(arrow(center_x, 962, center_x, decision1_y))

# Decision1 branches
parts.append(arrow(start_x + box_w / 2, decision1_y + 140, center_x, decision1_y + 172, "Oui"))
parts.append(arrow(start_x + box_w - 45, decision1_y + 70, 1120, no_branch_y + 40, "Non"))

# Continue success path to validate
parts.append(arrow(center_x, decision1_y + 172, center_x, decision1_y + 214))
parts.append(arrow(center_x, decision1_y + 288, center_x, decision1_y + 310))
parts.append(arrow(center_x, decision1_y + 384, center_x, decision2_y))

# Decision2 branches
parts.append(arrow(start_x + 125, decision2_y + 140, start_x + 115, yes_box_y, "Oui"))
parts.append(arrow(start_x + box_w - 125, decision2_y + 140, start_x + 395, yes_box_y, "Non"))

# From clear prefs to auth
parts.append(arrow(start_x + 395, yes_box_y + 80, start_x + 395, yes_box_y + 115))

# To end
parts.append(arrow(start_x + 115, yes_box_y + 80, start_x + 250, end_y, None))
parts.append(arrow(start_x + 395, yes_box_y + 195, start_x + 250, end_y, None))
parts.append(arrow(1280, no_branch_y + 80, 1280, end_y - 40, None))
parts.append(arrow(1280, end_y - 40, start_x + 250, end_y - 40, None))
parts.append(arrow(start_x + 250, end_y - 40, start_x + 250, end_y, None))

parts.append(note(
    1080, 1530, 570, 150,
    "Conformite au code actuel",
    [
        "Le flux suit le comportement observe dans main.dart.",
        "La verification du token passe par AuthProvider.validateToken().",
        "La navigation finale se fait vers /main ou /auth."
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
  <title>Diagramme de flux - Initialisation Flutter</title>
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
