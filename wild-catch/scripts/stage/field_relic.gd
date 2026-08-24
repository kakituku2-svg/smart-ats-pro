extends Node3D
class_name FieldRelic

signal collected(relic: FieldRelic)

@export var relic_id: StringName = &"relic"
@export var display_name := "Ancient Relic"
@export var pickup_radius := 1.45
@export var accent_color := Color(0.95, 0.72, 0.18, 1.0)

var _player: Node3D
var _visual: Node3D
var _collected := false
var _base_y := 0.0

func _ready() -> void:
    add_to_group("field_relic")
    _player = get_tree().get_first_node_in_group("player") as Node3D
    _base_y = position.y
    _build_visual()
    if SaveManager.has_relic(relic_id):
        _collected = true
        visible = false
        set_process(false)

func _process(delta: float) -> void:
    if _collected:
        return
    if not is_instance_valid(_player):
        _player = get_tree().get_first_node_in_group("player") as Node3D
        return
    rotation.y += delta * 1.4
    position.y = _base_y + sin(Time.get_ticks_msec() * 0.003) * 0.12
    if global_position.distance_to(_player.global_position) <= pickup_radius:
        collect()

func collect() -> void:
    if _collected:
        return
    _collected = true
    GameState.mark_relic_found(relic_id)
    collected.emit(self)
    var tween := create_tween()
    tween.tween_property(self, "scale", Vector3.ONE * 1.45, 0.10).set_trans(Tween.TRANS_BACK)
    tween.tween_property(self, "scale", Vector3.ZERO, 0.20)
    tween.tween_callback(func() -> void:
        visible = false
        set_process(false)
    )

func _build_visual() -> void:
    _visual = Node3D.new()
    _visual.name = "Visual"
    add_child(_visual)

    var core := MeshInstance3D.new()
    var core_mesh := SphereMesh.new()
    core_mesh.radius = 0.34
    core_mesh.height = 0.68
    core_mesh.radial_segments = 12
    core_mesh.rings = 6
    core.mesh = core_mesh
    var core_mat := StandardMaterial3D.new()
    core_mat.albedo_color = accent_color
    core_mat.emission_enabled = true
    core_mat.emission = accent_color
    core_mat.emission_energy_multiplier = 2.1
    core.material_override = core_mat
    _visual.add_child(core)

    var ring := MeshInstance3D.new()
    var torus := TorusMesh.new()
    torus.inner_radius = 0.48
    torus.outer_radius = 0.58
    torus.rings = 18
    torus.ring_segments = 8
    ring.mesh = torus
    ring.rotation_degrees.x = 90.0
    var ring_mat := StandardMaterial3D.new()
    ring_mat.albedo_color = accent_color.lightened(0.25)
    ring_mat.emission_enabled = true
    ring_mat.emission = accent_color
    ring_mat.emission_energy_multiplier = 1.8
    ring.material_override = ring_mat
    _visual.add_child(ring)
