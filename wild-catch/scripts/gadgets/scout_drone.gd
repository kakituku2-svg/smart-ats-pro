extends GadgetBase
class_name ScoutDrone

signal intel_ready(payloads: Array)
signal drone_launched(revealed_count: int)

@export var scan_radius := 34.0
@export var active_duration := 8.0
@export var cooldown_seconds := 9.0
@export var max_reveals := 3

var _cooldown_left := 0.0
var _active_left := 0.0
var _visual: Node3D
var _cartographer_upgraded := false

func _ready() -> void:
    add_to_group("scout_drone")
    _apply_persistent_upgrades()
    _build_visual()
    visible = false

func _process(delta: float) -> void:
    _cooldown_left = maxf(0.0, _cooldown_left - delta)
    if _active_left <= 0.0:
        return
    _active_left = maxf(0.0, _active_left - delta)
    if is_instance_valid(_visual):
        _visual.rotation.y += delta * (2.3 if _cartographer_upgraded else 1.8)
        _visual.position.y = 0.15 + sin(Time.get_ticks_msec() * 0.004) * 0.12
    if _active_left <= 0.0:
        visible = false
        deactivate()

func launch(hunter: Node3D) -> int:
    if _cooldown_left > 0.0 or not is_instance_valid(hunter):
        return -1
    _cooldown_left = cooldown_seconds
    _active_left = active_duration
    global_position = hunter.global_position + Vector3(0.0, 4.4, 0.0)
    visible = true
    activate()
    AudioManager.play_event(&"drone")

    var candidates: Array[Dictionary] = []
    for node in get_tree().get_nodes_in_group("mimo"):
        var mimo := node as MimoBase
        if mimo == null or mimo.state == MimoBase.State.CAPTURED:
            continue
        var distance := mimo.global_position.distance_to(hunter.global_position)
        if distance > scan_radius:
            continue
        var payload := mimo.get_scan_payload(hunter.global_position)
        payload["drone_reveal"] = true
        payload["distance"] = distance
        payload["world_position"] = mimo.global_position
        payload["cartographer_upgrade"] = _cartographer_upgraded
        candidates.append(payload)
    candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.get("distance", 9999.0)) < float(b.get("distance", 9999.0)))
    var revealed: Array = []
    for i in mini(max_reveals, candidates.size()):
        revealed.append(candidates[i])
    intel_ready.emit(revealed)
    drone_launched.emit(revealed.size())
    return revealed.size()

func is_cartographer_upgraded() -> bool:
    return _cartographer_upgraded

func get_cooldown_ratio() -> float:
    return clampf(_cooldown_left / maxf(cooldown_seconds, 0.01), 0.0, 1.0)

func _apply_persistent_upgrades() -> void:
    _cartographer_upgraded = SaveManager.has_unlock(&"ruins_cartographer")
    if _cartographer_upgraded:
        scan_radius = maxf(scan_radius, 44.0)
        cooldown_seconds = minf(cooldown_seconds, 6.8)
        max_reveals = maxi(max_reveals, 4)
        active_duration = maxf(active_duration, 9.5)

func _build_visual() -> void:
    _visual = Node3D.new()
    _visual.name = "DroneVisual"
    add_child(_visual)

    var core := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.23
    sphere.height = 0.46
    core.mesh = sphere
    var core_mat := StandardMaterial3D.new()
    core_mat.albedo_color = Color(0.16, 0.30, 0.36, 1.0) if _cartographer_upgraded else Color(0.10, 0.22, 0.30, 1.0)
    core_mat.metallic = 0.45
    core_mat.roughness = 0.28
    core.material_override = core_mat
    _visual.add_child(core)

    for x in [-0.38, 0.38]:
        var orb := MeshInstance3D.new()
        orb.position = Vector3(x, 0.0, 0.0)
        var orb_mesh := SphereMesh.new()
        orb_mesh.radius = 0.10
        orb_mesh.height = 0.20
        orb.mesh = orb_mesh
        var glow := StandardMaterial3D.new()
        glow.albedo_color = Color(0.38, 1.0, 0.62, 1.0) if _cartographer_upgraded else Color(0.18, 0.82, 1.0, 1.0)
        glow.emission_enabled = true
        glow.emission = glow.albedo_color
        glow.emission_energy_multiplier = 2.6 if _cartographer_upgraded else 2.4
        orb.material_override = glow
        _visual.add_child(orb)
