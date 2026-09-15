extends Node

var _last_open := false
var _hud: Control
var _panel: Control
var _button: Control
var _backdrop: ColorRect
var _scan_timer := 0.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
    _scan_timer -= delta
    if _scan_timer <= 0.0 or not is_instance_valid(_panel):
        _scan_timer = 0.20
        _resolve_field_log()
    if not is_instance_valid(_panel):
        if _last_open:
            _apply_open_state(false)
        return
    var open := _panel.visible
    if open != _last_open:
        _apply_open_state(open)

func _resolve_field_log() -> void:
    var scene := get_tree().current_scene
    if scene == null:
        _clear_refs()
        return
    var panel := scene.find_child("FieldLogPanel", true, false) as Control
    if panel == null:
        _clear_refs()
        return
    _panel = panel
    _hud = panel.get_parent() as Control
    if _hud == null:
        return
    _button = _hud.get_node_or_null("FieldLogButton") as Control
    if _backdrop == null or not is_instance_valid(_backdrop) or _backdrop.get_parent() != _hud:
        _backdrop = ColorRect.new()
        _backdrop.name = "FieldLogBackdrop"
        _backdrop.position = Vector2.ZERO
        _backdrop.size = Vector2(1280, 720)
        _backdrop.color = Color(0.015, 0.035, 0.05, 0.62)
        _backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
        _backdrop.visible = false
        _backdrop.z_index = 60
        _hud.add_child(_backdrop)
    _panel.z_index = 70
    if is_instance_valid(_button):
        _button.z_index = 80

func _apply_open_state(open: bool) -> void:
    _last_open = open
    if is_instance_valid(_backdrop):
        _backdrop.visible = open
    if is_instance_valid(_hud):
        for node_name in ["MoveStick", "CameraPad", "Actions", "GadgetBar", "CaptureReadyLabel", "ToastLabel", "GadgetStatusLabel"]:
            var item := _hud.get_node_or_null(node_name) as CanvasItem
            if item != null:
                item.visible = not open
    var scene := get_tree().current_scene
    var is_qa_scene := scene != null and scene.name in ["VisualCapture", "RuntimeSmoke"]
    if not is_qa_scene:
        get_tree().paused = open

func _clear_refs() -> void:
    if _last_open:
        _apply_open_state(false)
    _hud = null
    _panel = null
    _button = null
    _backdrop = null

func _exit_tree() -> void:
    get_tree().paused = false
