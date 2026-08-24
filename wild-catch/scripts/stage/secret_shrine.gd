extends Node3D
class_name SecretShrine

signal shrine_awakened(reward_id: StringName)

const REQUIRED_UNLOCK := &"ruins_cartographer"
const REWARD_UNLOCK := &"hex_resonance"

@export var activation_radius := 4.8

var is_available := false
var is_awakened := false
var _core: MeshInstance3D
var _ring: MeshInstance3D
var _material: StandardMaterial3D

func _ready() -> void:
    add_to_group("secret_shrine")
    _build_visual()
    if not GameState.reward_unlocked.is_connected(_on_reward_unlocked):
        GameState.reward_unlocked.connect(_on_reward_unlocked)
    _refresh_availability()

func _process(delta: float) -> void:
    if not is_available or is_awakened:
        return
    if is_instance_valid(_ring):
        _ring.rotation.y += delta * 1.5
        _ring.rotation.z += delta * 0.55
    if is_instance_valid(_core):
        _core.position.y = 1.5 + sin(Time.get_ticks_msec() * 0.003) * 0.13

func trigger_pulse(pulse_origin: Vector3) -> bool:
    if not is_available or is_awakened:
        return false
    if global_position.distance_to(pulse_origin) > activation_radius:
        return false
    is_awakened = true
    var first_unlock := SaveManager.unlock_reward(REWARD_UNLOCK)
    if first_unlock:
        AudioManager.play_event(&"unlock")
    _play_awaken_fx()
    shrine_awakened.emit(REWARD_UNLOCK)
    return true

func _refresh_availability() -> void:
    is_available = SaveManager.has_unlock(REQUIRED_UNLOCK)
    is_awakened = SaveManager.has_unlock(REWARD_UNLOCK)
    visible = is_available
    set_process(is_available and not is_awakened)
    _sync_pulse_group()
    if is_awakened:
        _set_awakened_visual()

func _sync_pulse_group() -> void:
    if is_available and not is_awakened:
        if not is_in_group("pulse_target"):
            add_to_group("pulse_target")
    elif is_in_group("pulse_target"):
        remove_from_group("pulse_target")

func _on_reward_unlocked(reward_id: StringName) -> void:
    if reward_id == REQUIRED_UNLOCK:
        is_available = true
        visible = true
        set_process(true)
        _sync_pulse_group()
        _pulse_reveal()

func _pulse_reveal() -> void:
    scale = Vector3.ZERO
    var tween := create_tween()
    tween.tween_property(self, "scale", Vector3.ONE * 1.18, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_property(self, "scale", Vector3.ONE, 0.12)

func _play_awaken_fx() -> void:
    set_process(false)
    _sync_pulse_group()
    if is_instance_valid(_material):
        _material.albedo_color = Color(0.35, 1.0, 0.72, 1.0)
        _material.emission = Color(0.18, 1.0, 0.58, 1.0)
        _material.emission_energy_multiplier = 4.5
    var tween := create_tween()
    tween.tween_property(self, "scale", Vector3.ONE * 1.35, 0.14).set_trans(Tween.TRANS_BACK)
    tween.tween_property(self, "scale", Vector3.ONE, 0.22)

func _set_awakened_visual() -> void:
    if is_instance_valid(_material):
        _material.albedo_color = Color(0.30, 0.82, 0.62, 1.0)
        _material.emission = Color(0.16, 0.76, 0.48, 1.0)
        _material.emission_energy_multiplier = 2.0

func _build_visual() -> void:
    var base := MeshInstance3D.new()
    var base_mesh := CylinderMesh.new()
    base_mesh.top_radius = 0.80
    base_mesh.bottom_radius = 1.05
    base_mesh.height = 1.25
    base_mesh.radial_segments = 8
    base.mesh = base_mesh
    base.position.y = 0.62
    var stone := StandardMaterial3D.new()
    stone.albedo_color = Color(0.22, 0.30, 0.28, 1.0)
    stone.roughness = 0.92
    base.material_override = stone
    add_child(base)

    _core = MeshInstance3D.new()
    var core_mesh := SphereMesh.new()
    core_mesh.radius = 0.38
    core_mesh.height = 0.76
    core_mesh.radial_segments = 12
    core_mesh.rings = 6
    _core.mesh = core_mesh
    _core.position.y = 1.5
    _material = StandardMaterial3D.new()
    _material.albedo_color = Color(0.18, 0.72, 1.0, 1.0)
    _material.emission_enabled = true
    _material.emission = Color(0.08, 0.62, 1.0, 1.0)
    _material.emission_energy_multiplier = 3.0
    _core.material_override = _material
    add_child(_core)

    _ring = MeshInstance3D.new()
    var torus := TorusMesh.new()
    torus.inner_radius = 0.68
    torus.outer_radius = 0.78
    torus.rings = 20
    torus.ring_segments = 8
    _ring.mesh = torus
    _ring.position.y = 1.5
    _ring.rotation_degrees.x = 90.0
    _ring.material_override = _material
    add_child(_ring)
