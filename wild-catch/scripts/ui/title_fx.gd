extends Control
class_name TitleFX

var _time := 0.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
    _time += delta
    queue_redraw()

func _draw() -> void:
    var s := size
    if s.x <= 0.0 or s.y <= 0.0:
        return
    # Soft tropical light blobs.
    _glow(Vector2(s.x * 0.18, s.y * 0.24), 115.0, Color(0.20, 0.92, 0.72, 0.13))
    _glow(Vector2(s.x * 0.80, s.y * 0.18), 145.0, Color(0.22, 0.70, 1.0, 0.13))
    _glow(Vector2(s.x * 0.72, s.y * 0.76), 125.0, Color(1.0, 0.66, 0.24, 0.10))

    # Floating gadget bubbles — original motifs, not branded replicas.
    var bubbles := [
        [Vector2(s.x * 0.11, s.y * 0.70), 42.0, Color(0.28, 1.0, 0.52, 0.78)],
        [Vector2(s.x * 0.86, s.y * 0.63), 47.0, Color(0.22, 0.72, 1.0, 0.78)],
        [Vector2(s.x * 0.90, s.y * 0.34), 34.0, Color(0.62, 0.88, 1.0, 0.74)],
        [Vector2(s.x * 0.13, s.y * 0.35), 31.0, Color(1.0, 0.72, 0.22, 0.72)],
    ]
    for i in range(bubbles.size()):
        var base: Vector2 = bubbles[i][0]
        var radius: float = bubbles[i][1]
        var color: Color = bubbles[i][2]
        var p := base + Vector2(0, sin(_time * (1.4 + i * 0.18) + i) * (5.0 + i))
        draw_circle(p, radius * 1.18, Color(color.r, color.g, color.b, 0.10))
        draw_circle(p, radius, Color(0.02, 0.10, 0.13, 0.72))
        draw_arc(p, radius, 0, TAU, 40, color, 4.0, true)
        if i == 0:
            _draw_signal_pod(p, radius * 0.62, color)
        elif i == 1:
            _draw_disc(p, radius * 0.62, color)
        elif i == 2:
            _draw_drone(p, radius * 0.62, color)
        else:
            _draw_net(p, radius * 0.62, color)

    # Moving scan line arcs.
    var center := Vector2(s.x * 0.5, s.y * 0.54)
    for i in range(3):
        var rr := 250.0 + i * 72.0 + sin(_time * 1.2 + i) * 8.0
        draw_arc(center, rr, PI * 1.08, PI * 1.92, 56, Color(0.28, 1.0, 0.82, 0.08 - i * 0.015), 3.0, true)

func _glow(pos: Vector2, radius: float, color: Color) -> void:
    for i in range(4, 0, -1):
        var alpha := color.a * (0.26 / float(i))
        draw_circle(pos, radius * float(i) / 4.0, Color(color.r, color.g, color.b, alpha))

func _draw_signal_pod(c: Vector2, r: float, col: Color) -> void:
    draw_rect(Rect2(c + Vector2(-r * 0.26, -r * 0.05), Vector2(r * 0.52, r * 0.58)), col, true)
    draw_line(c + Vector2(0, -r * 0.08), c + Vector2(0, -r * 0.52), Color.WHITE, 3.0, true)
    draw_arc(c + Vector2(0, -r * 0.50), r * 0.25, PI * 1.08, PI * 1.92, 14, Color.WHITE, 3.0, true)

func _draw_disc(c: Vector2, r: float, col: Color) -> void:
    draw_circle(c, r * 0.48, col)
    draw_arc(c, r * 0.48, 0, TAU, 24, Color.WHITE, 3.0, true)
    draw_circle(c, r * 0.14, Color.WHITE)

func _draw_drone(c: Vector2, r: float, col: Color) -> void:
    draw_circle(c, r * 0.28, col)
    draw_line(c + Vector2(-r * 0.25, 0), c + Vector2(-r * 0.70, 0), Color.WHITE, 3.0, true)
    draw_line(c + Vector2(r * 0.25, 0), c + Vector2(r * 0.70, 0), Color.WHITE, 3.0, true)
    draw_circle(c + Vector2(-r * 0.76, 0), r * 0.16, col)
    draw_circle(c + Vector2(r * 0.76, 0), r * 0.16, col)

func _draw_net(c: Vector2, r: float, col: Color) -> void:
    var pts := PackedVector2Array()
    for i in range(7):
        var a := -PI * 0.5 + float(i) / 6.0 * TAU
        pts.append(c + Vector2(cos(a), sin(a)) * r * 0.58)
    draw_polyline(pts, Color.WHITE, 3.0, true)
    draw_line(c + Vector2(r * 0.38, r * 0.38), c + Vector2(r * 0.78, r * 0.78), col, 4.0, true)
