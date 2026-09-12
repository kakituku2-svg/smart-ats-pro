extends Node3D
class_name FieldCheckpoint

signal activated(checkpoint: FieldCheckpoint)

@export var checkpoint_label := "チェックポイント"
@export var activation_radius := 1.8
@export var accent_color := Color(0.20, 0.90, 0.78, 1.0)

var _active := false
var _ring: MeshInstance3D
var _orb: MeshInstance3D
var _time := 0.0

func _ready() -> void:
    add_to_group("field_checkpoint")
    _build_visual()

func _process(delta: float) -> void:
    _time += delta
    if is_instance_valid(_ring):
        _ring.rotation.y += delta * 0.65
        var pulse := 1.0 + sin(_time * 3.2) * 0.06
        _ring.scale = Vector3.ONE * pulse
    if is_instance_valid(_orb):
        _orb.position.y = 1.08 + sin(_time * 2.5) * 0.08
    if _active:
        return
    var player := get_tree().get_first_node_in_group("player") as PlayerController
    if player == null:
        return
    var flat_delta := player.global_position - global_position
    flat_delta.y = 0.0
    if flat_delta.length() <= activation_radius:
        _activate(player)

func _activate(player: PlayerController) -> void:
    _active = true
    player.set_checkpoint(global_position + Vector3.UP * 0.35, checkpoint_label)
    if is_instance_valid(_ring):
        var tween := create_tween()
        tween.tween_property(_ring, "scale", Vector3.ONE * 1.45, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        tween.tween_property(_ring, "scale", Vector3.ONE * 1.05, 0.18)
    if is_instance_valid(_orb):
        _orb.material_override = _material(accent_color.lightened(0.18), 2.5)
    _notify_hud("チェックポイント更新  •  %s" % checkpoint_label)
    AudioManager.play_event(&"unlock")
    activated.emit(self)

func is_activated() -> bool:
    return _active

func _build_visual() -> void:
    var base := MeshInstance3D.new()
    base.name = "Pedestal"
    var base_mesh := CylinderMesh.new()
    base_mesh.top_radius = 0.55
    base_mesh.bottom_radius = 0.72
    base_mesh.height = 0.22
    base_mesh.radial_segments = 12
    base.mesh = base_mesh
    base.position.y = 0.12
    base.material_override = _material(Color(0.25, 0.34, 0.32, 1.0), 0.0)
    add_child(base)

    _ring = MeshInstance3D.new()
    _ring.name = "CheckpointRing"
    var ring_mesh := TorusMesh.new()
    ring_mesh.inner_radius = 0.48
    ring_mesh.outer_radius = 0.56
    ring_mesh.rings = 8
    ring_mesh.ring_segments = 28
    _ring.mesh = ring_mesh
    _ring.position.y = 0.38
    _ring.rotation_degrees.x = 90.0
    _ring.material_override = _material(accent_color, 1.8)
    add_child(_ring)

    _orb = MeshInstance3D.new()
    _orb.name = "CheckpointOrb"
    var orb_mesh := SphereMesh.new()
    orb_mesh.radius = 0.13
    orb_mesh.height = 0.26
    orb_mesh.radial_segments = 10
    orb_mesh.rings = 5
    _orb.mesh = orb_mesh
    _orb.position.y = 1.08
    _orb.material_override = _material(accent_color, 2.0)
    add_child(_orb)

    var stem := MeshInstance3D.new()
    stem.name = "LightStem"
    var stem_mesh := CylinderMesh.new()
    stem_mesh.top_radius = 0.018
    stem_mesh.bottom_radius = 0.045
    stem_mesh.height = 0.76
    stem_mesh.radial_segments = 6
    stem.mesh = stem_mesh
    stem.position.y = 0.68
    stem.material_override = _material(Color(accent_color.r, accent_color.g, accent_color.b, 0.45), 1.2)
    add_child(stem)

func _material(color: Color, emission_energy: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.56
    if color.a < 0.99:
        material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    if emission_energy > 0.0:
        material.emission_enabled = true
        material.emission = Color(color.r, color.g, color.b, 1.0)
        material.emission_energy_multiplier = emission_energy
    return material

func _notify_hud(message: String) -> void:
    var current := get_tree().current_scene
    if current == null:
        return
    var hud := current.find_child("MobileHUD", true, false)
    if hud != null and hud.has_method("show_toast"):
        hud.call("show_toast", message)
