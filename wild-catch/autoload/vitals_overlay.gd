extends CanvasLayer

var _player: PlayerController
var _label: Label
var _message: Label
var _message_time := 0.0
var _scan_time := 0.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    layer = 30
    _build_ui()
    _label.visible = false
    _message.visible = false

func _process(delta: float) -> void:
    _scan_time -= delta
    if _scan_time <= 0.0 or not is_instance_valid(_player):
        _scan_time = 0.25
        _resolve_player()
    if _message_time > 0.0:
        _message_time -= delta
        if _message_time <= 0.0:
            _message.visible = false

func _resolve_player() -> void:
    var candidate := get_tree().get_first_node_in_group("player") as PlayerController
    if candidate == _player:
        _label.visible = is_instance_valid(_player)
        return
    _player = candidate
    if not is_instance_valid(_player):
        _label.visible = false
        return
    if not _player.health_changed.is_connected(_on_health_changed):
        _player.health_changed.connect(_on_health_changed)
    if not _player.knocked_out.is_connected(_on_knocked_out):
        _player.knocked_out.connect(_on_knocked_out)
    _label.visible = true
    _on_health_changed(_player.health, _player.max_health)

func _build_ui() -> void:
    _label = Label.new()
    _label.name = "VitalsLabel"
    _label.position = Vector2(20, 176)
    _label.size = Vector2(230, 50)
    _label.add_theme_font_size_override("font_size", 26)
    _label.add_theme_color_override("font_color", Color(1.0, 0.42, 0.47, 1.0))
    _label.add_theme_color_override("font_outline_color", Color(0.13, 0.02, 0.03, 1.0))
    _label.add_theme_constant_override("outline_size", 7)
    _label.add_theme_stylebox_override("normal", GameUISkin.panel(Color(1.0, 0.36, 0.42, 1.0), 0.72, 15))
    _label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    add_child(_label)

    _message = Label.new()
    _message.name = "KnockoutMessage"
    _message.position = Vector2(365, 278)
    _message.size = Vector2(550, 86)
    _message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _message.add_theme_font_size_override("font_size", 30)
    _message.add_theme_color_override("font_color", Color(1.0, 0.86, 0.44, 1.0))
    _message.add_theme_color_override("font_outline_color", Color(0.12, 0.05, 0.01, 1.0))
    _message.add_theme_constant_override("outline_size", 8)
    _message.add_theme_stylebox_override("normal", GameUISkin.panel(Color(1.0, 0.66, 0.25, 1.0), 0.90, 20))
    add_child(_message)

func _on_health_changed(current: int, maximum: int) -> void:
    var full := "♥".repeat(maxi(current, 0))
    var empty := "♡".repeat(maxi(maximum - current, 0))
    _label.text = "%s%s" % [full, empty]
    _label.scale = Vector2(1.08, 1.08)
    var tween := create_tween()
    tween.tween_property(_label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_knocked_out() -> void:
    _message.text = "気絶！  チェックポイントへ戻ります"
    _message.visible = true
    _message.scale = Vector2(0.88, 0.88)
    var tween := create_tween()
    tween.tween_property(_message, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    _message_time = 2.2
