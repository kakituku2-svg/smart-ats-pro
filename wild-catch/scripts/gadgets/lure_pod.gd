extends GadgetBase
class_name LurePod

signal pod_deployed(world_position: Vector3, affected_count: int)
signal pod_expired

@export var lure_radius := 11.0
@export var active_duration := 6.5
@export var cooldown_seconds := 5.0

var _cooldown_left := 0.0
var _active_left := 0.0
var _visual: MeshInstance3D
var _ring: MeshInstance3D

func _ready() -> void:
    add_to_group("lure_pod")
    _build_visual()
    visible = false

func _process(delta: float) -> void:
    _cooldown_left = maxf(0.0, _cooldown_left - delta)
    if _active_left <= 0.0:
        return
    _active_left = maxf(0.0, _active_left - delta)
    if is_instance_valid(_ring):
        _ring.rotation.y += delta * 2.8
        var pulse := 1.0 + sin(Time.get_ticks_msec() * 0.006) * 0.12
        _ring.scale = Vector3.ONE * pulse
    if _active_left <= 0.0:
        visible = false
        deactivate()
        pod_expired.emit()

func deploy(hunter: Node3D) -> int:
    if _cooldown_left > 0.0 or not is_instance_valid(hunter):
        return -1
    var forward := -hunter.global_transform.basis.z
    forward.y = 0.0
    if forward.length_squared() < 0.01:
        forward = Vector3.FORWARD
    global_position = hunter.global_position + forward.normalized() * 3.4 + Vector3.UP * 0.28
    visible = true
    activate()
    _active_left = active_duration
    _cooldown_left = cooldown_seconds
    AudioManager.play_event(&"lure")

    var affected := 0
    for node in get_tree().get_nodes_in_group("mimo"):
        var mimo := node as MimoBase
        if mimo == null or mimo.state == MimoBase.State.CAPTURED:
            continue
        if mimo.global_position.distance_to(global_position) > lure_radius:
            continue
        var duration := active_duration * _profile_duration_multiplier(mimo.behavior_profile)
        if mimo.apply_lure(global_position, duration):
            affected += 1
    pod_deployed.emit(global_position, affected)
    return affected

func get_profile_effectiveness(profile: StringName) -> float:
    return _profile_duration_multiplier(profile)

func get_cooldown_ratio() -> float:
    return clampf(_cooldown_left / maxf(cooldown_seconds, 0.01), 0.0, 1.0)

func _profile_duration_multiplier(profile: StringName) -> float:
    match profile:
        &"sleepy":
            return 1.65
        &"timid":
            return 1.45
        &"challenger":
            return 1.15
        &"zigzag":
            return 0.92
        &"sentinel":
            return 0.78
        &"trickster":
            return 0.68
    return 1.0

func _build_visual() -> void:
    _visual = MeshInstance3D.new()
    _visual.name = "Pod"
    var pod_mesh := CylinderMesh.new()
    pod_mesh.top_radius = 0.22
    pod_mesh.bottom_radius = 0.30
    pod_mesh.height = 0.42
    pod_mesh.radial_segments = 12
    _visual.mesh = pod_mesh
    var pod_mat := StandardMaterial3D.new()
    pod_mat.albedo_color = Color(0.16, 0.72, 0.45, 1.0)
    pod_mat.emission_enabled = true
    pod_mat.emission = Color(0.08, 0.55, 0.28, 1.0)
    pod_mat.emission_energy_multiplier = 1.5
    _visual.material_override = pod_mat
    add_child(_visual)

    _ring = MeshInstance3D.new()
    _ring.name = "SignalRing"
    _ring.position.y = 0.28
    var ring_mesh := TorusMesh.new()
    ring_mesh.inner_radius = 0.34
    ring_mesh.outer_radius = 0.40
    ring_mesh.rings = 16
    ring_mesh.ring_segments = 8
    _ring.mesh = ring_mesh
    var ring_mat := StandardMaterial3D.new()
    ring_mat.albedo_color = Color(0.42, 1.0, 0.62, 1.0)
    ring_mat.emission_enabled = true
    ring_mat.emission = Color(0.22, 1.0, 0.46, 1.0)
    ring_mat.emission_energy_multiplier = 2.2
    _ring.material_override = ring_mat
    add_child(_ring)
