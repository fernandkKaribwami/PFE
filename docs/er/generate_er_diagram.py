from pathlib import Path
from xml.sax.saxutils import escape


WIDTH = 2700
HEIGHT = 1850


ENTITIES = {
    "Faculty": {
        "x": 980, "y": 90, "w": 300, "h": 220, "fill": "#dcfce7",
        "attrs": ["_id", "name", "slug", "description", "location", "image"]
    },
    "Group": {
        "x": 1950, "y": 220, "w": 320, "h": 230, "fill": "#fce7f3",
        "attrs": ["_id", "name", "category", "privacy", "admin", "members[]"]
    },
    "Event": {
        "x": 1950, "y": 560, "w": 320, "h": 250, "fill": "#fef3c7",
        "attrs": ["_id", "title", "category", "startDate", "endDate", "faculty", "createdBy"]
    },
    "User": {
        "x": 180, "y": 430, "w": 360, "h": 360, "fill": "#dbeafe",
        "attrs": ["_id", "name", "email", "role", "avatar", "bio", "faculty", "level", "followers[]", "following[]"]
    },
    "Post": {
        "x": 980, "y": 430, "w": 330, "h": 300, "fill": "#ede9fe",
        "attrs": ["_id", "user", "content", "media[]", "hashtags[]", "mentions[]", "likes[]", "comments[]", "group", "faculty"]
    },
    "Comment": {
        "x": 980, "y": 840, "w": 320, "h": 220, "fill": "#e0f2fe",
        "attrs": ["_id", "user", "post", "content", "likes[]"]
    },
    "Save": {
        "x": 660, "y": 1210, "w": 260, "h": 170, "fill": "#f3f4f6",
        "attrs": ["_id", "user", "post"]
    },
    "Report": {
        "x": 1030, "y": 1190, "w": 380, "h": 230, "fill": "#fee2e2",
        "attrs": ["_id", "post", "comment", "user", "reportedBy", "reason", "status"]
    },
    "Story": {
        "x": 180, "y": 920, "w": 330, "h": 250, "fill": "#fae8ff",
        "attrs": ["_id", "user", "mediaUrl", "mediaType", "caption", "viewers[]", "expiresAt"]
    },
    "Message": {
        "x": 1650, "y": 980, "w": 360, "h": 260, "fill": "#fff7ed",
        "attrs": ["_id", "sender", "receiver", "content", "attachments[]", "read"]
    },
    "Notification": {
        "x": 2030, "y": 1180, "w": 380, "h": 240, "fill": "#cffafe",
        "attrs": ["_id", "user", "type", "referenceId", "content", "read"]
    },
}


RELATIONS = [
    ("Faculty", "User", "1", "N", "appartenance"),
    ("User", "Post", "1", "N", "publie"),
    ("Post", "Comment", "1", "N", "contient"),
    ("User", "Comment", "1", "N", "ecrit"),
    ("User", "Message", "1", "N", "envoie"),
    ("User", "Message", "1", "N", "recoit", 1),
    ("User", "Story", "1", "N", "publie"),
    ("User", "Notification", "1", "N", "recoit"),
    ("User", "Save", "1", "N", "sauvegarde"),
    ("Post", "Save", "1", "N", "est sauvegarde"),
    ("Post", "Report", "1", "N", "peut etre signale"),
    ("Comment", "Report", "1", "N", "peut etre signale"),
    ("User", "Report", "1", "N", "reportedBy"),
    ("Faculty", "Post", "1", "N", "filtre faculte"),
    ("Group", "Post", "1", "N", "contient"),
    ("User", "Group", "1", "N", "administre"),
    ("User", "Event", "1", "N", "cree"),
    ("Faculty", "Event", "1", "N", "organise"),
]

MANY_TO_MANY = [
    ("User", "User", "N", "N", "follow / followers"),
    ("User", "Post", "N", "N", "likes / mentions"),
    ("User", "Story", "N", "N", "viewers"),
    ("User", "Group", "N", "N", "membres"),
    ("User", "Event", "N", "N", "attendees"),
]


def text_block(x, y, lines, size=22, weight="400", anchor="middle", fill="#0f172a", line_gap=6):
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


def entity(name, spec):
    x, y, w, h = spec["x"], spec["y"], spec["w"], spec["h"]
    fill = spec["fill"]
    attrs = spec["attrs"]
    parts = [
        f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="18" fill="{fill}" stroke="#475569" stroke-width="2.5"/>',
        f'<rect x="{x}" y="{y}" width="{w}" height="52" rx="18" fill="white" stroke="#475569" stroke-width="2.5"/>',
        f'<rect x="{x}" y="{y+34}" width="{w}" height="18" fill="white" stroke="none"/>',
        text_block(x + w / 2, y + 31, [name], size=24, weight="900"),
    ]
    attr_y = y + 76
    for attr in attrs:
        parts.append(text_block(x + 18, attr_y, [attr], size=16, weight="500", anchor="start", fill="#334155"))
        attr_y += 22
    return f'<g>{"".join(parts)}</g>'


def center(name):
    s = ENTITIES[name]
    return s["x"] + s["w"] / 2, s["y"] + s["h"] / 2


def edge_point(name, target_name, variant=0):
    sx, sy = center(name)
    tx, ty = center(target_name)
    spec = ENTITIES[name]
    x, y, w, h = spec["x"], spec["y"], spec["w"], spec["h"]

    dx = tx - sx
    dy = ty - sy
    if abs(dx) > abs(dy):
        px = x + w if dx > 0 else x
        py = sy + variant * 18
    else:
        px = sx + variant * 18
        py = y + h if dy > 0 else y
    return px, py


def relation_line(a, b, card_a, card_b, label, color="#64748b", dashed=False, variant=0):
    x1, y1 = edge_point(a, b, variant=variant)
    x2, y2 = edge_point(b, a, variant=-variant)
    dash = ' stroke-dasharray="10 8"' if dashed else ""
    mx = (x1 + x2) / 2
    my = (y1 + y2) / 2
    return f"""
    <g>
      <line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{color}" stroke-width="2.5"{dash}/>
      <rect x="{mx - 82:.1f}" y="{my - 18:.1f}" width="164" height="28" rx="8" fill="white" stroke="#cbd5e1" stroke-width="1.2"/>
      {text_block(mx, my, [label], size=13, weight="700", fill="#475569")}
      {text_block(x1 + (10 if x2 > x1 else -10), y1 - 10, [card_a], size=16, weight="900", anchor="start" if x2 > x1 else "end", fill="#0f172a")}
      {text_block(x2 + (10 if x1 > x2 else -10), y2 - 10, [card_b], size=16, weight="900", anchor="start" if x1 > x2 else "end", fill="#0f172a")}
    </g>
    """


output_dir = Path(__file__).resolve().parent
svg_path = output_dir / "usmba-social-er-diagram.svg"
html_path = output_dir / "usmba-social-er-diagram.html"

parts = []
parts.append(f'<rect x="0" y="0" width="{WIDTH}" height="{HEIGHT}" fill="#f8fafc"/>')
parts.append(text_block(WIDTH / 2, 46, ["Diagramme Entite-Relation - Modele de donnees USMBA Social"], size=34, weight="900"))
parts.append(text_block(WIDTH / 2, 84, ["Diagramme conceptuel base sur les modeles Mongoose du backend"], size=19, weight="500", fill="#475569"))

parts.append('<rect x="40" y="120" width="2620" height="1660" rx="26" fill="none" stroke="#cbd5e1" stroke-width="2"/>')

for name, spec in ENTITIES.items():
    parts.append(entity(name, spec))

for rel in RELATIONS:
    a, b, ca, cb, label, *rest = rel
    variant = rest[0] if rest else 0
    parts.append(relation_line(a, b, ca, cb, label, dashed=False, variant=variant))

for idx, rel in enumerate(MANY_TO_MANY):
    a, b, ca, cb, label = rel
    parts.append(relation_line(a, b, ca, cb, label, color="#8b5cf6", dashed=True, variant=(idx % 2) * 1))

parts.append(
    f'<rect x="1740" y="70" width="820" height="110" rx="18" fill="#ffffff" stroke="#cbd5e1" stroke-width="2"/>'
)
parts.append(text_block(2150, 100, ["Legende"], size=22, weight="800"))
parts.append(text_block(2150, 136, ["Trait plein : relation principale", "Trait pointille violet : relation many-to-many ou tableau de references"], size=16, weight="500", fill="#475569"))

svg = f"""<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="{WIDTH}" height="{HEIGHT}" viewBox="0 0 {WIDTH} {HEIGHT}">
  {' '.join(parts)}
</svg>
"""

html = f"""<!doctype html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <title>Diagramme ER - USMBA Social</title>
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
