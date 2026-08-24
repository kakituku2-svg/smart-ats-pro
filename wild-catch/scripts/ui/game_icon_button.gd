extends Button
class_name GameIconButton

## Lightweight vector-drawn game button.
## No external texture is required, so the HUD stays crisp on Android and can
## later be replaced with authored icon textures without changing gameplay.

@export_enum("lure", "pulse", "drone", "jump", "dash", "net", "scan") var icon_kind := "net"
@export var accent_color := Color(0.30, 1.0, 0.78, 1.0)
@export var icon_color := Color(0.96, 1.0, 0.98, 1.0)
@export var float_amount := 3.0
@export var float_speed := 2.4
@export var draw_shortcut_dot := false
@export var shortcut_number := 0

var _phase := 0.0
var _press_pop := 0.0
var _cooldown_ratio := 0.0
var _source: Node

func _ready() -> void:
    mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    focus_mode = Control.FOCUS_NONE
    pivot_offset = size * 0.5
    pressed.connect(_on_pressed_visual)
    _phase = float(abs(hash(icon_kind))) * 0.013
    queue_redraw()

func _process(delta: float) -> void:
    _phase += delta * float_speed
    _press_pop = move_toward(_press_pop, 0.0, delta * 5.8)
    _resolve_source_if_needed()
    _update_cooldown()
    queue_redraw()

func _draw() -> void:
    var c := size * 0.5 + Vector2(0.0, sin(_phase) * float_amount)
    var min_side := minf(size.x, size.y)
    var radius := min_side * 0.42
    var pop := 1.0 + _press_pop * 0.10
    radius *= pop

    var halo_alpha := 0.22 + (sin(_phase * 1.7) + 1.0) * 0.045
    draw_circle(c, radius * 1.12, Color(accent_color.r, accent_color.g, accent_color.b, halo_alpha))
    draw_circle(c, radius, Color(0.025, 0.10, 0.13, 0.90))
    draw_arc(c, radius, 0.0, TAU, 48, Color(accent_color.r, accent_color.g, accent_color.b, 0.88), maxf(2.0, min_side * 0.035), true)

    # Cooldown is a readable circular meter instead of a text timer.
    if _cooldown_ratio > 0.001:
        draw_arc(c, radius * 0.91, -PI * 0.5, -PI * 0.5 + TAU * _cooldown_ratio, 40, Color(0.02, 0.025, 0.035, 0.82), maxf(5.0, min_side * 0.10), true)

    _draw_icon(c, radius * 0.62)

    if draw_shortcut_dot and shortcut_number > 0:
        var dot_pos := c + Vector2(-radius * 0.72, -radius * 0.72)
        draw_circle(dot_pos, radius * 0.23, Color(0.98, 0.73, 0.20, 1.0))
        var font := get_theme_default_font()
        var fs := int(maxf(11.0, radius * 0.30))
        draw_string(font, dot_pos + Vector2(-radius * 0.08, radius * 0.10), str(shortcut_number), HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs, Color(0.08, 0.07, 0.04, 1.0))

func _draw_icon(c: Vector2, r: float) -> void:
    match icon_kind:
        "lure":
            _draw_lure(c, r)
        "pulse":
            _draw_pulse(c, r)
        "drone":
            _draw_drone(c, r)
        "jump":
            _draw_jump(c, r)
        "dash":
            _draw_dash(c, r)
        "scan":
            _draw_scan(c, r)
        _:
            _draw_net(c, r)

func _draw_lure(c: Vector2, r: float) -> void:
    var body := Rect2(c + Vector2(-r * 0.32, -r * 0.12), Vector2(r * 0.64, r * 0.58))
    draw_style_box(_rounded_box(Color(0.13, 0.74, 0.42, 1.0), r * 0.18), body)
    draw_line(c + Vector2(0, -r * 0.10), c + Vector2(0, -r * 0.55), icon_color, r * 0.12, true)
    draw_arc(c + Vector2(0, -r * 0.58), r * 0.30, PI * 1.08, PI * 1.92, 14, icon_color, r * 0.10, true)
    draw_arc(c + Vector2(0, -r * 0.58), r * 0.52, PI * 1.12, PI * 1.88, 14, Color(icon_color.r, icon_color.g, icon_color.b, 0.68), r * 0.07, true)

func _draw_pulse(c: Vector2, r: float) -> void:
    draw_circle(c, r * 0.53, Color(0.10, 0.48, 0.96, 0.92))
    draw_arc(c, r * 0.53, 0, TAU, 30, icon_color, r * 0.10, true)
    draw_circle(c, r * 0.18, icon_color)
    for i in range(4):
        var a := float(i) * PI * 0.5 + PI * 0.25
        var a0 := c + Vector2(cos(a), sin(a)) * r * 0.65
        var a1 := c + Vector2(cos(a), sin(a)) * r * 0.90
        draw_line(a0, a1, icon_color, r * 0.09, true)

func _draw_drone(c: Vector2, r: float) -> void:
    draw_circle(c, r * 0.30, Color(0.12, 0.40, 0.52, 1.0))
    draw_circle(c, r * 0.12, icon_color)
    draw_line(c + Vector2(-r * 0.30, 0), c + Vector2(-r * 0.72, 0), icon_color, r * 0.11, true)
    draw_line(c + Vector2(r * 0.30, 0), c + Vector2(r * 0.72, 0), icon_color, r * 0.11, true)
    draw_circle(c + Vector2(-r * 0.78, 0), r * 0.18, accent_color)
    draw_circle(c + Vector2(r * 0.78, 0), r * 0.18, accent_color)
    draw_arc(c, r * 0.72, PI * 1.10, PI * 1.90, 16, Color(icon_color.r, icon_color.g, icon_color.b, 0.52), r * 0.06, true)

func _draw_jump(c: Vector2, r: float) -> void:
    var pts := PackedVector2Array([
        c + Vector2(-r * 0.52, r * 0.26), c + Vector2(0, -r * 0.50), c + Vector2(r * 0.52, r * 0.26),
        c + Vector2(r * 0.25, r * 0.26), c + Vector2(r * 0.25, r * 0.55), c + Vector2(-r * 0.25, r * 0.55), c + Vector2(-r * 0.25, r * 0.26)
    ])
    draw_colored_polygon(pts, icon_color)

func _draw_dash(c: Vector2, r: float) -> void:
    for offset in [-0.26, 0.18]:
        var x := r * offset
        var pts := PackedVector2Array([
            c + Vector2(x - r * 0.40, -r * 0.50), c + Vector2(x + r * 0.34, 0), c + Vector2(x - r * 0.40, r * 0.50),
            c + Vector2(x - r * 0.18, 0)
        ])
        draw_colored_polygon(pts, icon_color)

func _draw_net(c: Vector2, r: float) -> void:
    var pts := PackedVector2Array()
    for i in range(7):
        var a := -PI * 0.5 + float(i) / 6.0 * TAU
        pts.append(c + Vector2(cos(a), sin(a)) * r * 0.62)
    draw_polyline(pts, icon_color, r * 0.11, true)
    draw_line(c + Vector2(r * 0.42, r * 0.42), c + Vector2(r * 0.88, r * 0.88), icon_color, r * 0.14, true)
    draw_line(c + Vector2(-r * 0.42, 0), c + Vector2(r * 0.42, 0), Color(icon_color.r, icon_color.g, icon_color.b, 0.58), r * 0.055, true)
    draw_line(c + Vector2(0, -r * 0.48), c + Vector2(0, r * 0.48), Color(icon_color.r, icon_color.g, icon_color.b, 0.58), r * 0.055, true)

func _draw_scan(c: Vector2, r: float) -> void:
    draw_circle(c, r * 0.13, icon_color)
    for rr in [0.38, 0.66, 0.92]:
        draw_arc(c, r * rr, -PI * 0.78, PI * 0.78, 24, Color(icon_color.r, icon_color.g, icon_color.b, 1.0 - rr * 0.35), r * 0.08, true)

func _rounded_box(color: Color, radius: float) -> StyleBoxFlat:
    var box := StyleBoxFlat.new()
    box.bg_color = color
    var cr := int(maxf(2.0, radius))
    box.corner_radius_top_left = cr
    box.corner_radius_top_right = cr
    box.corner_radius_bottom_left = cr
    box.corner_radius_bottom_right = cr
    return box

func _on_pressed_visual() -> void:
    _press_pop = 1.0

func _resolve_source_if_needed() -> void:
    if is_instance_valid(_source):
        return
    match icon_kind:
        "lure": _source = get_tree().get_first_node_in_group("lure_pod")
        "pulse": _source = get_tree().get_first_node_in_group("pulse_disc")
        "drone": _source = get_tree().get_first_node_in_group("scout_drone")

func _update_cooldown() -> void:
    if is_instance_valid(_source) and _source.has_method("get_cooldown_ratio"):
        _cooldown_ratio = float(_source.call("get_cooldown_ratio"))
    else:
        _cooldown_ratio = 0.0
