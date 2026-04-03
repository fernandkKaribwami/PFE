from pathlib import Path
from xml.sax.saxutils import escape


WIDTH = 2600
HEIGHT = 1750


def text_block(x, y, lines, size=22, weight="400", anchor="middle", fill="#0f172a"):
    line_height = size + 6
    start_y = y - ((len(lines) - 1) * line_height) / 2
    parts = []
    for index, line in enumerate(lines):
        parts.append(
            f'<text x="{x}" y="{start_y + index * line_height:.1f}" '
            f'font-size="{size}" font-weight="{weight}" text-anchor="{anchor}" '
            f'font-family="Segoe UI, Arial, sans-serif" fill="{fill}">{escape(line)}</text>'
        )
    return "\n".join(parts)


def actor(x, y, label_lines):
    head_r = 24
    body_top = y + head_r
    body_bottom = y + 100
    arms_y = y + 55
    leg_y = y + 155
    label_y = y + 205
    svg = f"""
    <g>
      <circle cx="{x}" cy="{y}" r="{head_r}" fill="white" stroke="#0f172a" stroke-width="4"/>
      <line x1="{x}" y1="{body_top}" x2="{x}" y2="{body_bottom}" stroke="#0f172a" stroke-width="4"/>
      <line x1="{x - 42}" y1="{arms_y}" x2="{x + 42}" y2="{arms_y}" stroke="#0f172a" stroke-width="4"/>
      <line x1="{x}" y1="{body_bottom}" x2="{x - 38}" y2="{leg_y}" stroke="#0f172a" stroke-width="4"/>
      <line x1="{x}" y1="{body_bottom}" x2="{x + 38}" y2="{leg_y}" stroke="#0f172a" stroke-width="4"/>
      {text_block(x, label_y, label_lines, size=24, weight="600")}
    </g>
    """
    return svg


def use_case(x, y, rx, ry, lines, fill="#ffffff", stroke="#1e3a8a", text_fill="#0f172a"):
    return f"""
    <g>
      <ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="{fill}" stroke="{stroke}" stroke-width="3"/>
      {text_block(x, y, lines, size=22, weight="500", fill=text_fill)}
    </g>
    """


def section(x, y, w, h, title):
    return f"""
    <g>
      <rect x="{x}" y="{y}" width="{w}" height="{h}" rx="18" fill="#f8fafc" stroke="#cbd5e1" stroke-width="3"/>
      <rect x="{x}" y="{y}" width="{w}" height="56" rx="18" fill="#e2e8f0" stroke="#cbd5e1" stroke-width="3"/>
      <rect x="{x}" y="{y + 28}" width="{w}" height="28" fill="#e2e8f0" stroke="none"/>
      {text_block(x + w / 2, y + 30, [title], size=24, weight="700", fill="#0f172a")}
    </g>
    """


def line(x1, y1, x2, y2, dashed=False, marker_end=None, stroke="#475569", width=3):
    dash = ' stroke-dasharray="10 8"' if dashed else ""
    marker = f' marker-end="url(#{marker_end})"' if marker_end else ""
    return (
        f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" '
        f'stroke="{stroke}" stroke-width="{width}"{dash}{marker}/>'
    )


def line_label(x, y, text):
    return f"""
    <g>
      <rect x="{x - 62}" y="{y - 18}" width="124" height="34" rx="10" fill="white" stroke="#cbd5e1" stroke-width="1.5"/>
      {text_block(x, y + 1, [text], size=16, weight="700", fill="#334155")}
    </g>
    """


output_dir = Path(__file__).resolve().parent
svg_path = output_dir / "usmba-social-use-case-report.svg"
html_path = output_dir / "usmba-social-use-case-report.html"


elements = []

# Background and title
elements.append(f'<rect x="0" y="0" width="{WIDTH}" height="{HEIGHT}" fill="white"/>')
elements.append(text_block(WIDTH / 2, 46, ["Diagramme de cas d'utilisation - USMBA Social"], size=34, weight="800"))

# System boundary
elements.append(
    """
    <g>
      <rect x="320" y="120" width="1960" height="1500" rx="26" fill="none" stroke="#0f172a" stroke-width="4"/>
      <rect x="352" y="136" width="340" height="44" rx="14" fill="white"/>
    </g>
    """
)
elements.append(text_block(522, 158, ["Systeme USMBA Social"], size=24, weight="800"))

# Sections
elements.append(section(360, 190, 360, 520, "Authentification"))
elements.append(section(780, 190, 430, 520, "Profil et reseau social"))
elements.append(section(1260, 180, 920, 600, "Publications et stories"))
elements.append(section(360, 780, 750, 430, "Messagerie et notifications"))
elements.append(section(1160, 830, 1020, 470, "Facultes, groupes et evenements"))
elements.append(section(360, 1320, 1820, 250, "Administration"))

# Actors
elements.append(actor(130, 270, ["Visiteur"]))
elements.append(actor(130, 620, ["Utilisateur", "authentifie"]))
elements.append(actor(130, 1150, ["Administrateur"]))
elements.append(actor(2450, 360, ["Service", "Google"]))
elements.append(actor(2450, 760, ["Service", "Email"]))

# Admin inherits user
elements.append(line(130, 1126, 130, 800, marker_end="triangle-open", stroke="#475569", width=3))

# Use cases
ucs = {
    "register": (540, 285, 125, 46, ["S'inscrire"], "#eff6ff"),
    "login": (540, 395, 130, 46, ["Se connecter"], "#eff6ff"),
    "google": (450, 520, 145, 42, ["Connexion", "Google"], "#eff6ff"),
    "verify": (630, 520, 145, 42, ["Verifier", "l'email"], "#eff6ff"),
    "reset": (540, 625, 195, 46, ["Reinitialiser le", "mot de passe"], "#eff6ff"),
    "manage_profile": (995, 285, 150, 46, ["Gerer le profil"], "#fefce8"),
    "view_profiles": (995, 395, 162, 46, ["Consulter les", "profils"], "#fefce8"),
    "follow": (995, 515, 176, 46, ["Suivre / se", "desabonner"], "#fefce8"),
    "search": (995, 625, 180, 46, ["Rechercher sur", "la plateforme"], "#fefce8"),
    "feed": (1505, 260, 150, 42, ["Consulter le feed"], "#f0fdf4"),
    "create_post": (1505, 395, 145, 42, ["Publier un post"], "#f0fdf4"),
    "add_media": (1950, 395, 125, 34, ["Ajouter un media"], "#ffffff"),
    "post_interaction": (1505, 535, 180, 46, ["Interagir avec", "un post"], "#f0fdf4"),
    "like": (1835, 470, 108, 32, ["Aimer"], "#ffffff"),
    "comment": (2025, 470, 120, 32, ["Commenter"], "#ffffff"),
    "save": (1835, 560, 132, 32, ["Sauvegarder"], "#ffffff"),
    "report": (2025, 560, 108, 32, ["Signaler"], "#ffffff"),
    "share": (1930, 650, 165, 36, ["Partager en", "conversation"], "#ffffff"),
    "stories": (1505, 665, 155, 42, ["Gerer les stories"], "#f0fdf4"),
    "messaging": (610, 900, 170, 42, ["Utiliser la", "messagerie"], "#fef2f2"),
    "view_conversations": (860, 845, 145, 34, ["Voir les", "conversations"], "#ffffff"),
    "send_message": (860, 945, 145, 34, ["Envoyer un", "message"], "#ffffff"),
    "attach_file": (860, 1045, 135, 34, ["Joindre un", "fichier"], "#ffffff"),
    "notifications": (610, 1070, 185, 42, ["Consulter les", "notifications"], "#fef2f2"),
    "mark_read": (610, 1160, 165, 34, ["Marquer comme", "lues"], "#ffffff"),
    "view_faculties": (1340, 960, 160, 38, ["Consulter les", "facultes"], "#faf5ff"),
    "use_groups": (1570, 965, 155, 40, ["Utiliser les", "groupes"], "#faf5ff"),
    "create_group": (1885, 900, 122, 32, ["Creer un", "groupe"], "#ffffff"),
    "view_group": (2070, 900, 130, 32, ["Consulter un", "groupe"], "#ffffff"),
    "join_leave_group": (1975, 1000, 175, 34, ["Rejoindre / quitter", "un groupe"], "#ffffff"),
    "use_events": (1570, 1130, 155, 40, ["Utiliser les", "evenements"], "#faf5ff"),
    "create_event": (1885, 1080, 122, 32, ["Creer un", "evenement"], "#ffffff"),
    "view_events": (2070, 1080, 136, 32, ["Consulter les", "evenements"], "#ffffff"),
    "rsvp": (1975, 1180, 90, 32, ["RSVP"], "#ffffff"),
    "admin_dashboard": (620, 1435, 180, 40, ["Acceder au dashboard", "administrateur"], "#fff7ed"),
    "admin_stats": (935, 1435, 160, 34, ["Consulter les", "statistiques"], "#ffffff"),
    "manage_users": (1245, 1435, 160, 40, ["Gerer les", "utilisateurs"], "#fff7ed"),
    "block_user": (1165, 1525, 150, 32, ["Bloquer / debloquer"], "#ffffff"),
    "delete_user": (1360, 1525, 130, 32, ["Supprimer", "utilisateur"], "#ffffff"),
    "manage_posts": (1555, 1435, 165, 40, ["Gerer les", "publications"], "#fff7ed"),
    "delete_post": (1555, 1525, 120, 32, ["Supprimer", "post"], "#ffffff"),
    "handle_reports": (1865, 1435, 170, 40, ["Traiter les", "signalements"], "#fff7ed"),
    "view_reports": (1790, 1525, 132, 32, ["Consulter les", "signalements"], "#ffffff"),
    "update_report": (1995, 1525, 152, 32, ["Mettre a jour", "le statut"], "#ffffff"),
}

for _, (x, y, rx, ry, lines, fill) in ucs.items():
    elements.append(use_case(x, y, rx, ry, lines, fill=fill))

# Actor to use-case links
elements.extend(
    [
        line(172, 320, 415, 285),
        line(172, 320, 410, 395),
        line(172, 320, 305, 520),
        line(172, 320, 485, 520),
        line(172, 320, 345, 625),
        line(172, 670, 845, 285),
        line(172, 670, 835, 395),
        line(172, 670, 825, 515),
        line(172, 670, 820, 625),
        line(172, 670, 1360, 260),
        line(172, 670, 1360, 395),
        line(172, 670, 1325, 535),
        line(172, 670, 1350, 665),
        line(172, 670, 440, 900),
        line(172, 670, 425, 1070),
        line(172, 670, 1180, 960),
        line(172, 670, 1415, 965),
        line(172, 670, 1415, 1130),
        line(172, 1200, 440, 1435),
        line(172, 1200, 1085, 1435),
        line(172, 1200, 1390, 1435),
        line(172, 1200, 1695, 1435),
        line(2410, 410, 1595, 395),
        line(2410, 810, 775, 520),
        line(2410, 810, 735, 625),
    ]
)

# Include / extend relations
relations = [
    ("create_post", "add_media", "<<extend>>", (1735, 380)),
    ("post_interaction", "like", "<<include>>", (1672, 485)),
    ("post_interaction", "comment", "<<include>>", (1778, 450)),
    ("post_interaction", "save", "<<include>>", (1688, 560)),
    ("post_interaction", "report", "<<include>>", (1792, 575)),
    ("post_interaction", "share", "<<include>>", (1778, 652)),
    ("messaging", "view_conversations", "<<include>>", (736, 848)),
    ("messaging", "send_message", "<<include>>", (736, 924)),
    ("send_message", "attach_file", "<<extend>>", (860, 995)),
    ("notifications", "mark_read", "<<extend>>", (610, 1120)),
    ("use_groups", "create_group", "<<include>>", (1722, 900)),
    ("use_groups", "view_group", "<<include>>", (1832, 868)),
    ("use_groups", "join_leave_group", "<<include>>", (1778, 1010)),
    ("use_events", "create_event", "<<include>>", (1722, 1082)),
    ("use_events", "view_events", "<<include>>", (1832, 1055)),
    ("use_events", "rsvp", "<<include>>", (1778, 1180)),
    ("admin_dashboard", "admin_stats", "<<include>>", (782, 1435)),
    ("manage_users", "block_user", "<<include>>", (1205, 1482)),
    ("manage_users", "delete_user", "<<include>>", (1310, 1482)),
    ("manage_posts", "delete_post", "<<include>>", (1555, 1482)),
    ("handle_reports", "view_reports", "<<include>>", (1828, 1482)),
    ("handle_reports", "update_report", "<<include>>", (1932, 1482)),
]

for source, target, label, label_pos in relations:
    x1, y1 = ucs[source][0], ucs[source][1]
    x2, y2 = ucs[target][0], ucs[target][1]
    elements.append(line(x1, y1, x2, y2, dashed=True, marker_end="arrow", stroke="#64748b", width=2.5))
    elements.append(line_label(label_pos[0], label_pos[1], label))

svg = f"""<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="{WIDTH}" height="{HEIGHT}" viewBox="0 0 {WIDTH} {HEIGHT}">
  <defs>
    <marker id="arrow" markerWidth="12" markerHeight="12" refX="10" refY="6" orient="auto" markerUnits="strokeWidth">
      <path d="M 0 0 L 12 6 L 0 12 z" fill="#64748b"/>
    </marker>
    <marker id="triangle-open" markerWidth="16" markerHeight="16" refX="8" refY="8" orient="auto" markerUnits="strokeWidth">
      <path d="M 16 8 L 0 0 L 0 16 z" fill="white" stroke="#475569" stroke-width="1.5"/>
    </marker>
  </defs>
  {' '.join(elements)}
</svg>
"""

html = f"""<!doctype html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <title>USMBA Social - Diagramme de cas d'utilisation</title>
  <style>
    html, body {{
      margin: 0;
      padding: 0;
      background: #ffffff;
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
