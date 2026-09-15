extends Node3D
class_name MimoVisualController

## Production-art bridge for Mimo.
## Production priority per Mimo: original GLB -> original glTF -> preview scene.
## If no production art exists, the primitive fallback keeps state-driven motion.
## SignatureActionDirector events are translated to semantic animation names.

@export var production_scene: PackedScene
@export var production_scale := Vector3.ONE
@export var production_offset := Vector3.ZERO

@onready var mimo: MimoBase = get_parent() as MimoBase
@onready var body: Node3D = $Body
@onready var head: Node3D = $Head
@onready var ear_l: Node3D = $EarL
@onready var ear_r: Node3D = $EarR
@onready var arm_l: Node3D = $ArmL
@onready var arm_r: Node3D = $ArmR
@onready var foot_l: Node3D = $FootL
@onready var foot_r: Node3D = $FootR
@onready var halo: Node3D = $Halo
@onready var orb: Node3D = $Orb

var _production_root: Node3D
var _animation_player: AnimationPlayer
var _current_semantic := ""
var _phase := 0.0
var _base: Dictionary = {}
var _action_semantic := ""
var _action_time := 0.0

func _ready() -> void:
    _phase = float(abs(hash(String(mimo.mimo_id))) % 628) / 100.0 if mimo != null else 0.0
    _cache_pose()
    if production_scene == null and mimo != null:
        production_scene = ProductionArtPaths.mimo_scene(mimo.mimo_id)
    if production_scene != null:
        _install_production_scene()
    call_deferred("_bind_signature_director")

func _process(delta: float) -> void:
    if mimo == null:
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

func _bind_signature_director() -> void:
    var director := get_tree().get_first_node_in_group("signature_action_director")
    if director != null and director.has_signal("signature_action") and not director.is_connected("signature_action", _on_signature_action):
        director.connect("signature_action", _on_signature_action)

func _on_signature_action(mimo_id: StringName, action_name: StringName) -> void:
    if mimo == null or mimo.mimo_id != mimo_id:
        return
    _action_semantic = _signature_semantic(action_name)
    _action_time = _signature_duration(_action_semantic)
    _current_semantic = ""

func _signature_semantic(action_name: StringName) -> String:
    match action_name:
        &"grass_hide": return "hide_grass"
        &"stone_throw": return "throw_rock"
        &"counter_charge": return "charge"
        &"spark_burst": return "shock"
        &"sleep_cloud": return "sleep"
        &"decoy_split": return "decoy"
        _: return "alert"

func _signature_duration(semantic: String) -> float:
    match semantic:
        "hide_grass": return 0.92
        "throw_rock": return 0.62
        "charge": return 0.52
        "shock": return 0.58
        "sleep": return 0.82
        "decoy": return 0.70
        _: return 0.40

func _install_production_scene() -> void:
    if production_scene == null:
        return
    var instance := production_scene.instantiate()
    if not (instance is Node3D):
        push_warning("Mimo production scene root must be Node3D")
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
    var semantic := _action_semantic if _action_time > 0.0 else _state_semantic()
    if semantic == _current_semantic:
        return
    _current_semantic = semantic
    for candidate in _animation_candidates(semantic):
        if _animation_player.has_animation(candidate):
            _animation_player.play(candidate, 0.08 if _action_time > 0.0 else 0.12)
            return

func _animate_placeholder(delta: float) -> void:
    _phase += delta
    if _action_time > 0.0:
        _animate_placeholder_signature()
        return
    var planar_speed := Vector2(mimo.velocity.x, mimo.velocity.z).length()
    var move_weight := clampf(planar_speed / maxf(mimo.panic_speed, 0.01), 0.0, 1.0)
    var tired := mimo.state == MimoBase.State.FATIGUED
    var alert := mimo.state == MimoBase.State.ALERT
    var panic := mimo.state == MimoBase.State.PANIC

    if tired:
        var pant := sin(_phase * 4.8)
        body.position.y = float(_base["body_y"]) - 0.10 + pant * 0.018
        head.position.y = float(_base["head_y"]) - 0.12 + pant * 0.012
        head.rotation.x = 0.18 + pant * 0.035
        ear_l.rotation.z = -0.42 + pant * 0.05
        ear_r.rotation.z = 0.42 - pant * 0.05
        arm_l.rotation.z = -0.62 + pant * 0.06
        arm_r.rotation.z = 0.62 - pant * 0.06
        arm_l.rotation.x = 0.14
        arm_r.rotation.x = 0.14
        foot_l.rotation.x = -0.10
        foot_r.rotation.x = 0.10
        halo.position.y = float(_base["halo_y"]) - 0.08
        orb.position.y = float(_base["orb_y"]) - 0.08
        return

    var cadence := 3.0
    if panic:
        cadence = 10.5
    elif alert:
        cadence = 6.2
    elif move_weight > 0.08:
        cadence = 7.2
    var wave := sin(_phase * cadence)
    var bounce := absf(sin(_phase * cadence * 0.5))
    var intensity := 0.18 + move_weight * 0.82
    if panic:
        intensity = 1.0
    elif alert:
        intensity = maxf(intensity, 0.55)

    body.position.y = float(_base["body_y"]) + bounce * 0.055 * intensity
    head.position.y = float(_base["head_y"]) + bounce * 0.065 * intensity
    head.rotation.z = wave * 0.07 * intensity
    ear_l.rotation.z = -0.12 + wave * 0.20 * intensity
    ear_r.rotation.z = 0.12 + wave * 0.20 * intensity
    arm_l.rotation.x = -wave * 0.62 * intensity
    arm_r.rotation.x = wave * 0.62 * intensity
    arm_l.rotation.z = -0.18 - absf(wave) * 0.10 * intensity
    arm_r.rotation.z = 0.18 + absf(wave) * 0.10 * intensity
    foot_l.rotation.x = -wave * 0.45 * intensity
    foot_r.rotation.x = wave * 0.45 * intensity
    halo.position.y = float(_base["halo_y"]) + bounce * 0.045 * intensity
    orb.position.y = float(_base["orb_y"]) + bounce * 0.075 * intensity

    if mimo.state == MimoBase.State.RECOVER:
        head.rotation.x = -0.05 + sin(_phase * 2.4) * 0.025
        arm_l.rotation.z = -0.28
        arm_r.rotation.z = 0.28
    else:
        head.rotation.x = 0.0

func _animate_placeholder_signature() -> void:
    var pulse := sin(_phase * 15.0)
    match _action_semantic:
        "hide_grass":
            body.scale.y = 0.72
            head.position.y = float(_base["head_y"]) - 0.18
            ear_l.rotation.z = -0.48
            ear_r.rotation.z = 0.48
        "throw_rock":
            arm_r.rotation.x = -1.05 + pulse * 0.10
            body.rotation.z = -0.10
        "charge":
            body.rotation.x = -0.16
            head.rotation.x = 0.12
            arm_l.rotation.x = 0.55
            arm_r.rotation.x = 0.55
        "shock":
            arm_l.rotation.z = -0.72
            arm_r.rotation.z = 0.72
            orb.scale = Vector3.ONE * (1.0 + absf(pulse) * 0.30)
        "sleep":
            head.rotation.x = 0.28
            body.position.y = float(_base["body_y"]) - 0.08
            arm_l.rotation.z = -0.50
            arm_r.rotation.z = 0.50
        "decoy":
            head.rotation.z = pulse * 0.18
            body.rotation.z = -pulse * 0.12
        _:
            pass

func _cache_pose() -> void:
    _base["body_y"] = body.position.y
    _base["head_y"] = head.position.y
    _base["halo_y"] = halo.position.y
    _base["orb_y"] = orb.position.y

func _set_placeholder_visible(value: bool) -> void:
    for child in get_children():
        if child == _production_root:
            continue
        if child is VisualInstance3D:
            (child as VisualInstance3D).visible = value

func _state_semantic() -> String:
    match mimo.state:
        MimoBase.State.ALERT: return "alert"
        MimoBase.State.PANIC: return "run"
        MimoBase.State.FATIGUED: return "tired"
        MimoBase.State.RECOVER: return "recover"
        MimoBase.State.CAPTURED: return "capture"
        _: return "idle"

func _animation_candidates(semantic: String) -> Array[StringName]:
    match semantic:
        "alert": return [&"Alert", &"alert", &"Notice", &"Idle"]
        "run": return [&"Run", &"run", &"Panic", &"Sprint"]
        "tired": return [&"Tired", &"Fatigued", &"fatigued", &"Idle"]
        "recover": return [&"Recover", &"recover", &"Idle"]
        "capture": return [&"Capture", &"Captured", &"capture"]
        "hide_grass": return [&"HideGrass", &"Hide", &"Alert", &"Idle"]
        "throw_rock": return [&"ThrowRock", &"Throw", &"Alert", &"Idle"]
        "charge": return [&"Charge", &"ChargeTell", &"Run", &"Alert"]
        "shock": return [&"Shock", &"ShockTell", &"Alert", &"Idle"]
        "sleep": return [&"Sleep", &"DrowsyField", &"Tired", &"Idle"]
        "decoy": return [&"Decoy", &"Feint", &"Alert", &"Idle"]
        _: return [&"Idle", &"idle", &"IDLE"]

func _find_animation_player(root: Node) -> AnimationPlayer:
    if root is AnimationPlayer:
        return root as AnimationPlayer
    for child in root.get_children():
        var found := _find_animation_player(child)
        if found != null:
            return found
    return null
