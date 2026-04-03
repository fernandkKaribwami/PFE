from pathlib import Path
from xml.sax.saxutils import escape


WIDTH = 2400
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


def box(x, y, w, h, title, lines, fill, stroke="#94a3b8", title_size=28):
    return f"""
    <g>
      <rect x="{x}" y="{y}" width="{w}" height="{h}" rx="24" fill="{fill}" stroke="{stroke}" stroke-width="3"/>
      {text_block(x + w / 2, y + 34, [title], size=title_size, weight="800")}
      {text_block(x + w / 2, y + h / 2 + 12, lines, size=20, weight="500", fill="#334155", line_gap=8)}
    </g>
    """


def chip(x, y, w, text, fill="#ffffff", stroke="#cbd5e1"):
    return f"""
    <g>
      <rect x="{x}" y="{y}" width="{w}" height="44" rx="22" fill="{fill}" stroke="{stroke}" stroke-width="1.8"/>
      {text_block(x + w / 2, y + 25, [text], size=16, weight="700", fill="#334155")}
    </g>
    """


def arrow(x1, y1, x2, y2, label=None, dashed=False, color="#475569"):
    dash = ' stroke-dasharray="10 8"' if dashed else ""
    label_svg = ""
    if label:
        label_svg = f"""
        <g>
          <rect x="{(x1 + x2) / 2 - 130:.1f}" y="{(y1 + y2) / 2 - 38:.1f}" width="260" height="34" rx="10" fill="white" stroke="#cbd5e1" stroke-width="1.2"/>
          {text_block((x1 + x2) / 2, (y1 + y2) / 2 - 19, [label], size=14, weight="700", fill="#475569")}
        </g>
        """
    return f"""
    <g>
      <line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{color}" stroke-width="3.5" marker-end="url(#arrow)"{dash}/>
      {label_svg}
    </g>
    """


output_dir = Path(__file__).resolve().parent
svg_path = output_dir / "socketio-realtime-architecture.svg"
html_path = output_dir / "socketio-realtime-architecture.html"

parts = []
parts.append(f'<rect x="0" y="0" width="{WIDTH}" height="{HEIGHT}" fill="#f8fafc"/>')
parts.append(text_block(WIDTH / 2, 50, ["Architecture temps reel - Flux d'evenements Socket.IO"], size=34, weight="900"))
parts.append(text_block(WIDTH / 2, 90, ["USMBA Social - Client Flutter, Node.js, rooms utilisateur et emissions backend"], size=20, weight="500", fill="#475569"))

# Main client/server/db blocks
parts.append(box(
    120, 240, 520, 430,
    "Client Flutter / RealtimeService",
    [
        "Connexion avec auth.userId",
        "Transports : websocket + polling",
        "emit('join')",
        "emit('typing')",
        "StreamControllers pour messages, notifications, stories, profils"
    ],
    "#dbeafe", "#60a5fa"
))

parts.append(box(
    840, 180, 700, 560,
    "Serveur Node.js / Socket.IO",
    [
        "initializeSocket(server)",
        "io.on('connection')",
        "socket.join(userId)",
        "Gestion des events : join, typing, sendMessage, notification",
        "Emission vers les rooms utilisateur"
    ],
    "#ede9fe", "#8b5cf6"
))

parts.append(box(
    1730, 250, 520, 320,
    "Rooms Socket.IO",
    [
        "Une room par utilisateur",
        "room = userId",
        "io.to(userId).emit(...)",
        "Diffusion ciblee des evenements"
    ],
    "#dcfce7", "#22c55e"
))

parts.append(box(
    1710, 670, 540, 270,
    "MongoDB Atlas / Mongoose",
    [
        "Message.create()",
        "Message.findById()",
        "Notification.create()",
        "Stories, profils et autres donnees"
    ],
    "#fff7ed", "#fb923c"
))

# Sources backend
parts.append(box(
    120, 820, 740, 510,
    "Sources d'evenements cote backend",
    [
        "messages.js : newMessage + notification",
        "posts.js : notifications like/comment/post",
        "stories.js : storyCreated / storyDeleted",
        "users.js : profileUpdated + follow notification",
        "utils/notifications.js : emit('notification')"
    ],
    "#ffffff", "#cbd5e1"
))

parts.append(box(
    980, 870, 560, 430,
    "Evenements recus cote Flutter",
    [
        "userTyping",
        "newMessage",
        "messageSent",
        "notification",
        "followNotification",
        "postLiked / postCommented",
        "storyCreated / storyDeleted",
        "profileUpdated"
    ],
    "#ffffff", "#cbd5e1"
))

# Chips / lists
chips = [
    (165, 495, 140, "join"),
    (320, 495, 150, "typing"),
    (485, 495, 190, "sendMessage"),
    (1030, 495, 170, "connection"),
    (1220, 495, 120, "join"),
    (1355, 495, 150, "typing"),
    (1755, 500, 170, "room userId"),
    (1945, 500, 220, "emission ciblee"),
]
for c in chips:
    parts.append(chip(*c))

# Arrows
parts.append(arrow(640, 420, 840, 420, "connexion et emissions client"))
parts.append(arrow(1540, 420, 1730, 420, "join + io.to(roomId).emit"))
parts.append(arrow(1540, 760, 1710, 790, "CRUD async Mongoose"))
parts.append(arrow(860, 1070, 980, 1070, "emissions backend / notifications"))
parts.append(arrow(860, 980, 980, 980, "routes HTTP et utils"))
parts.append(arrow(860, 930, 840, 610, "messages / posts / stories / users"))
parts.append(arrow(1540, 610, 1730, 450, "emission vers room"))
parts.append(arrow(840, 560, 640, 560, "events pousses au client"))
parts.append(arrow(840, 1140, 980, 1140, "liste des events observes"))

# Category notes
parts.append(box(
    1710, 1040, 540, 240,
    "Flux temps reel principaux",
    [
        "1. Client se connecte puis rejoint sa room",
        "2. typing est relaie vers le destinataire",
        "3. sendMessage cree un message puis emet newMessage",
        "4. Les routes HTTP declenchent des notifications et updates temps reel"
    ],
    "#fefce8", "#eab308"
))

# Legend
parts.append(
    '<rect x="120" y="1370" width="2130" height="90" rx="18" fill="white" stroke="#cbd5e1" stroke-width="2"/>'
)
parts.append(text_block(1185, 1400, ["Schema base sur socket.js, realtime_service.dart, messages.js, posts.js, stories.js, users.js et utils/notifications.js"], size=17, weight="500", fill="#475569"))
parts.append(text_block(1185, 1430, ["Le backend utilise a la fois des evenements Socket.IO directs et des emissions declenchees depuis les routes HTTP."], size=17, weight="700", fill="#334155"))

svg = f"""<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="{WIDTH}" height="{HEIGHT}" viewBox="0 0 {WIDTH} {HEIGHT}">
  <defs>
    <marker id="arrow" markerWidth="12" markerHeight="12" refX="10" refY="6" orient="auto" markerUnits="strokeWidth">
      <path d="M 0 0 L 12 6 L 0 12 z" fill="#475569"/>
    </marker>
  </defs>
  {' '.join(parts)}
</svg>
"""

html = f"""<!doctype html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <title>Architecture temps reel Socket.IO</title>
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
