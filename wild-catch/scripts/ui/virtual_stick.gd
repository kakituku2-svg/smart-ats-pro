extends Control
class_name VirtualStick

signal value_changed(value: Vector2)

@export var radius := 72.0
@export var deadzone := 0.08
@export var response_exponent := 0.88

var value := Vector2.ZERO
var _touch_index := -1
var _mouse_active := false
var _touch_positions_are_local := true
var _mouse_positions_are_local := true
var _time := 0.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    queue_redraw()

func _process(delta: float) -> void:
    _time += delta
    queue_redraw()

func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch
        if touch.pressed and _touch_index == -1:
            _touch_index = touch.index
            _touch_positions_are_local = _looks_like_local_position(touch.position)
            _set_from_input_position(touch.position, _touch_positions_are_local)
            accept_event()
        elif not touch.pressed and touch.index == _touch_index:
            _touch_index = -1
            _set_value(Vector2.ZERO)
            accept_event()
    elif event is InputEventScreenDrag:
        var drag := event as InputEventScreenDrag
        if drag.index == _touch_index:
            _set_from_input_position(drag.position, _touch_positions_are_local)
            accept_event()
    elif event is InputEventMouseButton:
        var button := event as InputEventMouseButton
        if button.button_index == MOUSE_BUTTON_LEFT:
            _mouse_active = button.pressed
            if button.pressed:
                _mouse_positions_are_local = _looks_like_local_position(button.position)
                _set_from_input_position(button.position, _mouse_positions_are_local)
            else:
                _set_value(Vector2.ZERO)
            accept_event()
    elif event is InputEventMouseMotion and _mouse_active:
        var motion := event as InputEventMouseMotion
        _set_from_input_position(motion.position, _mouse_positions_are_local)
        accept_event()

func _looks_like_local_position(input_pos: Vector2) -> bool:
    return Rect2(Vector2.ZERO, size).grow(6.0).has_point(input_pos)

func _set_from_input_position(input_pos: Vector2, already_local: bool) -> void:
    var local_pos := input_pos
    if not already_local:
        local_pos = get_global_transform_with_canvas().affine_inverse() * input_pos
    _set_from_local(local_pos)

func _set_from_local(local_pos: Vector2) -> void:
    var center := size * 0.5
    var raw := (local_pos - center) / maxf(radius, 1.0)
    raw = raw.limit_length(1.0)
    var magnitude := raw.length()
    if magnitude <= deadzone:
        _set_value(Vector2.ZERO)
        return
    var scaled_magnitude := clampf((magnitude - deadzone) / maxf(1.0 - deadzone, 0.001), 0.0, 1.0)
    scaled_magnitude = pow(scaled_magnitude, response_exponent)
    _set_value(raw.normalized() * scaled_magnitude)

func _set_value(next: Vector2) -> void:
    value = next.limit_length(1.0)
    value_changed.emit(value)
    queue_redraw()

func _draw() -> void:
    var center := size * 0.5
    var active := value.length() > 0.05
    var glow := 0.10 + (0.07 if active else 0.0) + sin(_time * 2.4) * 0.015

    draw_circle(center, radius * 1.10, Color(0.18, 0.92, 0.82, glow))
    draw_circle(center, radius, Color(0.018, 0.075, 0.10, 0.60))
    draw_arc(center, radius, 0, TAU, 48, Color(0.28, 0.94, 0.86, 0.48), 3.0, true)
    draw_arc(center, radius * 0.72, _time * 0.35, _time * 0.35 + PI * 0.72, 22, Color(0.38, 1.0, 0.90, 0.38), 3.0, true)
    draw_arc(center, radius * 0.72, _time * 0.35 + PI, _time * 0.35 + PI * 1.72, 22, Color(0.38, 1.0, 0.90, 0.38), 3.0, true)

    _draw_direction_tick(center, Vector2.UP, active)
    _draw_direction_tick(center, Vector2.DOWN, active)
    _draw_direction_tick(center, Vector2.LEFT, active)
    _draw_direction_tick(center, Vector2.RIGHT, active)

    var knob_pos := center + value * radius * 0.64
    var knob_radius := radius * 0.29
    draw_circle(knob_pos, knob_radius * 1.18, Color(0.30, 1.0, 0.88, 0.17))
    draw_circle(knob_pos, knob_radius, Color(0.10, 0.42, 0.43, 0.94))
    draw_arc(knob_pos, knob_radius, 0, TAU, 32, Color(0.64, 1.0, 0.92, 0.92), 3.0, true)
    draw_circle(knob_pos, knob_radius * 0.24, Color(0.85, 1.0, 0.94, 0.86))

func _draw_direction_tick(center: Vector2, direction: Vector2, active: bool) -> void:
    var tangent := Vector2(-direction.y, direction.x)
    var p := center + direction * radius * 0.83
    var alpha := 0.52 if active else 0.30
    var color := Color(0.70, 1.0, 0.94, alpha)
    draw_line(p - tangent * 5.5, p + direction * 6.0, color, 2.2, true)
    draw_line(p + tangent * 5.5, p + direction * 6.0, color, 2.2, true)

func clear_input() -> void:
    _touch_index = -1
    _mouse_active = false
    _set_value(Vector2.ZERO)

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
        clear_input()
