extends Node3D
class_name PlayerVisualController

## Bridge between gameplay and production character art.
## Production priority: original GLB -> original glTF -> repository preview scene.
## If none exists, the primitive fallback remains animated by gameplay state.

@export var production_scene: PackedScene
@export var production_scale := Vector3.ONE
@export var production_offset := Vector3.ZERO

@onready var player: PlayerController = get_parent() as PlayerController
@onready var torso: Node3D = $Torso
@onready var head: Node3D = $Head
@onready var hair_front: Node3D = $HairFront
@onready var arm_l: Node3D = $ArmL
@onready var arm_r: Node3D = $ArmR
@onready var leg_l: Node3D = $LegL
@onready var leg_r: Node3D = $LegR
@onready var shoe_l: Node3D = $ShoeL
@onready var shoe_r: Node3D = $ShoeR
@onready var bag: Node3D = $Bag

var _production_root: Node3D
var _animation_player: AnimationPlayer
var _base: Dictionary = {}
var _current_semantic := ""
var _phase := 0.0
var _action_semantic := ""
var _action_time := 0.0

func _ready() -> void:
    _cache_placeholder_pose()
    _phase = float(Time.get_ticks_msec()) * 0.001
    if production_scene == null:
        production_scene = ProductionArtPaths.ren_scene()
    if production_scene != null:
        _install_production_scene()
    call_deferred("_bind_action_signals")

func _process(delta: float) -> void:
    if player == null:
        return
    _action_time = maxf(0.0, _action_time - delta)
    if _action_time <= 0.0:
        _action_semantic = ""
    if _production_root != null:
        _drive_production_animation()
    else:
        _animate_placeholder(delta)

func has_production_art() -> bool:
    return _production_root != null

func get_production_root() -> Node3D:
    return _production_root

func install_production_scene(scene: PackedScene) -> void:
    production_scene = scene
    if _production_root != null:
        _production_root.queue_free()
        _production_root = null
    _install_production_scene()

func _bind_action_signals() -> void:
    var net := get_tree().get_first_node_in_group("hex_net")
    if net != null and net.has_signal("swing_started") and not net.is_connected("swing_started", _on_net_swing):
        net.connect("swing_started", _on_net_swing)
    var scan := get_tree().get_first_node_in_group("echo_scan")
    if scan != null:
        if scan.has_signal("scan_result") and not scan.is_connected("scan_result", _on_scan_result):
            scan.connect("scan_result", _on_scan_result)
        if scan.has_signal("scan_empty") and not scan.is_connected("scan_empty", _on_scan_empty):
            scan.connect("scan_empty", _on_scan_empty)

func _on_net_swing(step: int) -> void:
    _action_semantic = "net_%d" % clampi(step, 1, 3)
    _action_time = 0.32 if step == 3 else 0.25
    _current_semantic = ""

func _on_scan_result(_payload: Dictionary) -> void:
    _trigger_scan_pose()

func _on_scan_empty() -> void:
    _trigger_scan_pose()

func _trigger_scan_pose() -> void:
    _action_semantic = "scan"
    _action_time = 0.42
    _current_semantic = ""

func _install_production_scene() -> void:
    if production_scene == null:
        return
    var instance := production_scene.instantiate()
    if not (instance is Node3D):
        push_warning("Ren production scene root must be Node3D")
        instance.queue_free()
        return
    _production_root = instance as Node3D
    _production_root.name = "ProductionArt"
    _production_root.position = production_offset
    _production_root.scale = production_scale
    add_child(_production_root)
    _animation_player = _find_animation_player(_production_root)
    _set_placeholder_visible(false)

func _drive_production_animation() -> void:
    if _animation_player == null:
        return
    var semantic := _action_semantic if _action_time > 0.0 else _locomotion_semantic()
    if semantic == _current_semantic:
        return
    _current_semantic = semantic
    for candidate in _animation_candidates(semantic):
        if _animation_player.has_animation(candidate):
            _animation_player.play(candidate, 0.08 if _action_time > 0.0 else 0.12)
            return

func _locomotion_semantic() -> String:
    var planar_speed := Vector2(player.velocity.x, player.velocity.z).length()
    if not player.is_on_floor():
        return "jump" if player.velocity.y >= 0.0 else "fall"
    if planar_speed > player.move_speed * 1.45:
        return "dash"
    if planar_speed > 0.35:
        return "run"
    return "idle"

func _animate_placeholder(delta: float) -> void:
    _phase += delta
    if _action_time > 0.0:
        _animate_placeholder_action(delta)
        return
    var planar_speed := Vector2(player.velocity.x, player.velocity.z).length()
    var move_amount := clampf(planar_speed / maxf(player.move_speed, 0.01), 0.0, 1.35)
    var target_weight := smoothstep(0.05, 0.75, move_amount)

    if not player.is_on_floor():
        var rising := player.velocity.y >= 0.0
        _set_rot_x(arm_l, -0.42 if rising else 0.22)
        _set_rot_x(arm_r, -0.42 if rising else 0.22)
        _set_rot_x(leg_l, 0.28 if rising else -0.18)
        _set_rot_x(leg_r, -0.16 if rising else 0.26)
        torso.position.y = float(_base["torso_y"]) + (0.025 if rising else -0.02)
        head.rotation.z = lerp_angle(head.rotation.z, 0.0, clampf(delta * 8.0, 0.0, 1.0))
        return

    if target_weight > 0.05:
        var cadence := 7.0 + move_amount * 4.5
        var wave := sin(_phase * cadence)
        var wave2 := sin(_phase * cadence * 2.0)
        var swing := wave * 0.68 * target_weight
        _set_rot_x(arm_l, swing)
        _set_rot_x(arm_r, -swing)
        _set_rot_x(leg_l, -swing * 0.72)
        _set_rot_x(leg_r, swing * 0.72)
        shoe_l.rotation.x = -swing * 0.26
        shoe_r.rotation.x = swing * 0.26
        torso.position.y = float(_base["torso_y"]) + absf(wave2) * 0.035 * target_weight
        torso.rotation.z = wave * 0.035 * target_weight
        head.rotation.z = -wave * 0.025 * target_weight
        bag.rotation.x = wave * 0.11 * target_weight
        hair_front.rotation.x = -0.04 + wave2 * 0.025 * target_weight
    else:
        var breathe := sin(_phase * 2.1)
        _set_rot_x(arm_l, breathe * 0.025)
        _set_rot_x(arm_r, -breathe * 0.025)
        _set_rot_x(leg_l, 0.0)
        _set_rot_x(leg_r, 0.0)
        shoe_l.rotation.x = 0.0
        shoe_r.rotation.x = 0.0
        torso.position.y = float(_base["torso_y"]) + breathe * 0.012
        torso.rotation.z = breathe * 0.006
        head.rotation.z = -breathe * 0.005
        bag.rotation.x = breathe * 0.02
        hair_front.rotation.x = -0.04 + breathe * 0.01

func _animate_placeholder_action(delta: float) -> void:
    var progress := clampf(_action_time / 0.32, 0.0, 1.0)
    match _action_semantic:
        "net_1":
            arm_r.rotation.y = lerp_angle(arm_r.rotation.y, -1.0 + progress * 2.0, 0.52)
            _set_rot_x(arm_r, -0.38)
            _set_rot_x(arm_l, 0.18)
            torso.rotation.z = -0.08 + progress * 0.16
        "net_2":
            arm_r.rotation.y = lerp_angle(arm_r.rotation.y, 1.15 - progress * 2.3, 0.52)
            _set_rot_x(arm_r, -0.52)
            _set_rot_x(arm_l, 0.22)
            torso.rotation.z = 0.09 - progress * 0.18
        "net_3":
            _set_rot_x(arm_r, -1.05 + (1.0 - progress) * 1.65)
            _set_rot_x(arm_l, -0.70 + (1.0 - progress) * 0.9)
            torso.rotation.x = -0.08 + (1.0 - progress) * 0.16
        "scan":
            _set_rot_x(arm_l, -0.62)
            _set_rot_x(arm_r, -0.62)
            arm_l.rotation.z = -0.30
            arm_r.rotation.z = 0.30
            head.rotation.x = -0.06
        _:
            pass
    torso.position.y = float(_base["torso_y"]) + sin(_phase * 12.0) * 0.01
    head.rotation.z = lerp_angle(head.rotation.z, 0.0, clampf(delta * 10.0, 0.0, 1.0))

func _cache_placeholder_pose() -> void:
    _base["torso_y"] = torso.position.y

func _set_rot_x(node: Node3D, value: float) -> void:
    node.rotation.x = lerp_angle(node.rotation.x, value, 0.38)

func _set_placeholder_visible(value: bool) -> void:
    for child in get_children():
        if child == _production_root:
            continue
        if child is VisualInstance3D:
            (child as VisualInstance3D).visible = value

func _find_animation_player(root: Node) -> AnimationPlayer:
    if root is AnimationPlayer:
        return root as AnimationPlayer
    for child in root.get_children():
        var found := _find_animation_player(child)
        if found != null:
            return found
    return null

func _animation_candidates(semantic: String) -> Array[StringName]:
    match semantic:
        "run": return [&"Run", &"run", &"RUN", &"Locomotion_Run"]
        "dash": return [&"Dash", &"dash", &"Sprint", &"Run"]
        "jump": return [&"Jump", &"jump", &"Jump_Up"]
        "fall": return [&"Fall", &"fall", &"Jump_Fall", &"Jump"]
        "net_1": return [&"Net_1", &"Net1", &"net_1"]
        "net_2": return [&"Net_2", &"Net2", &"net_2"]
        "net_3": return [&"Net_3", &"Net3", &"net_3"]
        "scan": return [&"Scan", &"scan", &"EchoScan"]
        _: return [&"Idle", &"idle", &"IDLE"]
