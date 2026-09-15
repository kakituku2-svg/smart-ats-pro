extends GadgetBase
class_name HexNet

signal swing_started(step: int)
signal combo_finished
signal net_contact(mimo: MimoBase, captured: bool, step: int)
signal net_miss(step: int)
signal persistent_upgrade_applied(upgrade_id: StringName)

@export var combo_reset_seconds := 0.72
@export var swing_cooldown := 0.22

@onready var net_visual: Node3D = $NetVisual

var combo_step := 0
var _combo_timer := 0.0
var _cooldown := 0.0
var _player: Node3D
var _tool_tween: Tween
var _resonance_upgraded := false

func _ready() -> void:
    add_to_group("hex_net")
    _player = get_tree().get_first_node_in_group("player") as Node3D
    refresh_persistent_upgrade()

func _process(delta: float) -> void:
    if not is_instance_valid(_player):
        _player = get_tree().get_first_node_in_group("player") as Node3D
    _follow_player()
    _cooldown = maxf(0.0, _cooldown - delta)
    if _combo_timer > 0.0:
        _combo_timer -= delta
        if _combo_timer <= 0.0:
            combo_step = 0
    if Input.is_action_just_pressed("net"):
        request_swing()

func request_swing() -> void:
    if _cooldown > 0.0 or not is_instance_valid(_player):
        return
    _cooldown = swing_cooldown
    combo_step = (combo_step % 3) + 1
    _combo_timer = combo_reset_seconds
    swing_started.emit(combo_step)
    _animate_swing(combo_step)
    _perform_capture_check(combo_step)
    if combo_step == 3:
        combo_finished.emit()

func refresh_persistent_upgrade() -> void:
    var was_upgraded := _resonance_upgraded
    _resonance_upgraded = SaveManager.has_unlock(&"hex_resonance")
    if _resonance_upgraded:
        combo_reset_seconds = maxf(combo_reset_seconds, 0.96)
        swing_cooldown = minf(swing_cooldown, 0.19)
        if is_instance_valid(net_visual):
            net_visual.scale = Vector3.ONE * 1.08
        if not was_upgraded:
            persistent_upgrade_applied.emit(&"hex_resonance")

func is_resonance_upgraded() -> bool:
    return _resonance_upgraded

func get_step_three_reach() -> float:
    return 4.05 if _resonance_upgraded else 3.55

func _follow_player() -> void:
    if not is_instance_valid(_player):
        return
    var forward := -_player.global_transform.basis.z
    forward.y = 0.0
    if forward.length_squared() < 0.01:
        forward = Vector3.FORWARD
    forward = forward.normalized()
    global_position = _player.global_position + Vector3.UP * 1.15 + forward * 0.95
    rotation.y = _player.rotation.y

func _perform_capture_check(step: int) -> void:
    var forward := -_player.global_transform.basis.z
    forward.y = 0.0
    forward = forward.normalized()
    var reach := 2.7
    var min_dot := 0.35
    var yaw_offset := deg_to_rad(-18.0)
    if step == 2:
        reach = 3.15
        min_dot = 0.10
        yaw_offset = deg_to_rad(18.0)
    elif step == 3:
        reach = get_step_three_reach()
        min_dot = 0.48
        yaw_offset = 0.0
    var sweep_dir := forward.rotated(Vector3.UP, yaw_offset)

    var best: MimoBase
    var best_distance := INF
    for node in get_tree().get_nodes_in_group("mimo"):
        var mimo := node as MimoBase
        if mimo == null or mimo.state == MimoBase.State.CAPTURED:
            continue
        var delta := mimo.global_position - _player.global_position
        delta.y = 0.0
        var distance := delta.length()
        if distance <= 0.001 or distance > reach:
            continue
        var dot := sweep_dir.dot(delta.normalized())
        if dot >= min_dot and distance < best_distance:
            best = mimo
            best_distance = distance
    if best != null:
        var captured_now := best.attempt_capture(step, _player)
        net_contact.emit(best, captured_now, step)
    else:
        net_miss.emit(step)

func _animate_swing(step: int) -> void:
    if _tool_tween != null and _tool_tween.is_running():
        _tool_tween.kill()
    net_visual.rotation = Vector3.ZERO
    net_visual.position = Vector3.ZERO
    _tool_tween = create_tween()
    if step == 1:
        net_visual.rotation.y = deg_to_rad(-65.0)
        _tool_tween.tween_property(net_visual, "rotation:y", deg_to_rad(65.0), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    elif step == 2:
        net_visual.rotation.y = deg_to_rad(80.0)
        _tool_tween.tween_property(net_visual, "rotation:y", deg_to_rad(-85.0), 0.21).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    else:
        net_visual.rotation.x = deg_to_rad(-95.0)
        net_visual.position.y = 0.55
        _tool_tween.tween_property(net_visual, "rotation:x", deg_to_rad(35.0), 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
        _tool_tween.parallel().tween_property(net_visual, "position:y", -0.15, 0.24)
