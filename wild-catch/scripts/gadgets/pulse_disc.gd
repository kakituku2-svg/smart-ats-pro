extends GadgetBase
class_name PulseDisc

signal pulse_fired(world_position: Vector3, affected_count: int)

@export var throw_distance := 6.2
@export var pulse_radius := 3.6
@export var stamina_damage := 26.0
@export var stun_seconds := 0.72
@export var cooldown_seconds := 2.2

var _cooldown_left := 0.0
var _disc: MeshInstance3D

func _ready() -> void:
    add_to_group("pulse_disc")
    _build_visual()
    visible = false

func _process(delta: float) -> void:
    _cooldown_left = maxf(0.0, _cooldown_left - delta)

func fire(hunter: Node3D) -> int:
    if _cooldown_left > 0.0 or not is_instance_valid(hunter):
        return -1
    _cooldown_left = cooldown_seconds
    var forward := -hunter.global_transform.basis.z
    forward.y = 0.0
    if forward.length_squared() < 0.01:
        forward = Vector3.FORWARD
    forward = forward.normalized()
    var start := hunter.global_position + Vector3.UP * 1.0 + forward * 0.8
    var target := hunter.global_position + forward * throw_distance + Vector3.UP * 0.35
    global_position = start
    visible = true
    activate()
    var tween := create_tween()
    tween.tween_property(self, "global_position", target, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.parallel().tween_property(_disc, "rotation:y", TAU * 2.5, 0.18)
    tween.tween_callback(func() -> void:
        _apply_pulse(target)
        visible = false
        deactivate()
    )
    return 0

func debug_fire_at(target: Vector3) -> int:
    global_position = target
    return _apply_pulse(target)

func _apply_pulse(target: Vector3) -> int:
    AudioManager.play_event(&"pulse")
    var affected := 0
    for node in get_tree().get_nodes_in_group("mimo"):
        var mimo := node as MimoBase
        if mimo == null or mimo.state == MimoBase.State.CAPTURED:
            continue
        if mimo.global_position.distance_to(target) > pulse_radius:
            continue
        var multiplier := _profile_effectiveness(mimo.behavior_profile)
        if mimo.apply_pulse(target, stamina_damage * multiplier, stun_seconds * multiplier):
            affected += 1
    for node in get_tree().get_nodes_in_group("pulse_target"):
        if node is MimoBase:
            continue
        if not node.has_method("trigger_pulse"):
            continue
        var result = node.call("trigger_pulse", target)
        if result is bool and bool(result):
            affected += 1
    pulse_fired.emit(target, affected)
    return affected

func get_profile_effectiveness(profile: StringName) -> float:
    return _profile_effectiveness(profile)

func get_cooldown_ratio() -> float:
    return clampf(_cooldown_left / maxf(cooldown_seconds, 0.01), 0.0, 1.0)

func _profile_effectiveness(profile: StringName) -> float:
    match profile:
        &"zigzag":
            return 1.38
        &"sentinel":
            return 1.32
        &"trickster":
            return 1.16
        &"challenger":
            return 0.96
        &"timid":
            return 0.86
        &"sleepy":
            return 0.78
    return 1.0

func _build_visual() -> void:
    _disc = MeshInstance3D.new()
    _disc.name = "Disc"
    var mesh := CylinderMesh.new()
    mesh.top_radius = 0.34
    mesh.bottom_radius = 0.34
    mesh.height = 0.08
    mesh.radial_segments = 18
    _disc.mesh = mesh
    _disc.rotation_degrees.x = 90.0
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.14, 0.58, 0.98, 1.0)
    mat.emission_enabled = true
    mat.emission = Color(0.08, 0.48, 1.0, 1.0)
    mat.emission_energy_multiplier = 2.5
    _disc.material_override = mat
    add_child(_disc)
