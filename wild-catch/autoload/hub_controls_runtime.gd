extends Node

var _hub: Node3D
var _player: PlayerController
var _camera_pad: Control
var _stick: VirtualStick
var _camera_touch_index := -1

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
    if node is Node3D and node.name == "FieldBase":
        call_deferred("_install", node)

func _install(hub: Node3D) -> void:
    await get_tree().process_frame
    if not is_instance_valid(hub) or hub.get_node_or_null("HubControls") != null:
        return
    _hub = hub
    _player = get_tree().get_first_node_in_group("player") as PlayerController
    if _player == null:
        return

    var canvas := CanvasLayer.new()
    canvas.name = "HubControls"
    canvas.layer = 18
    hub.add_child(canvas)

    var root := Control.new()
    root.name = "Root"
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    canvas.add_child(root)

    _stick = VirtualStick.new()
    _stick.name = "MoveStick"
    _stick.position = Vector2(34, 520)
    _stick.size = Vector2(168, 168)
    _stick.radius = 70.0
    _stick.deadzone = 0.08
    _stick.value_changed.connect(_on_stick_value)
    root.add_child(_stick)

    _camera_pad = Control.new()
    _camera_pad.name = "CameraPad"
    _camera_pad.position = Vector2(260, 150)
    _camera_pad.size = Vector2(500, 530)
    _camera_pad.mouse_filter = Control.MOUSE_FILTER_STOP
    _camera_pad.gui_input.connect(_on_camera_input)
    root.add_child(_camera_pad)

    var hint := Label.new()
    hint.name = "HubMoveHint"
    hint.position = Vector2(28, 475)
    hint.size = Vector2(220, 36)
    hint.text = "本拠地を移動"
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    GameUISkin.style_body(hint, 14)
    root.add_child(hint)

func _on_stick_value(value: Vector2) -> void:
    if is_instance_valid(_player):
        _player.set_touch_move_vector(value)

func _on_camera_input(event: InputEvent) -> void:
    if not is_instance_valid(_player):
        return
    if event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch
        if touch.pressed and _camera_touch_index == -1:
            _camera_touch_index = touch.index
        elif not touch.pressed and touch.index == _camera_touch_index:
            _camera_touch_index = -1
            _player.clear_camera_look_input()
    elif event is InputEventScreenDrag:
        var drag := event as InputEventScreenDrag
        if drag.index == _camera_touch_index:
            _player.add_camera_look_delta(drag.relative)
    elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
        var motion := event as InputEventMouseMotion
        _player.add_camera_look_delta(motion.relative)

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
        _camera_touch_index = -1
        if is_instance_valid(_player):
            _player.clear_transient_input_state()
        if is_instance_valid(_stick):
            _stick.clear_input()
