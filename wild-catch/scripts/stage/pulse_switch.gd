extends Node3D
class_name PulseSwitch

signal opened

@export var activation_radius := 2.8
@export var gate_size := Vector3(5.8, 3.2, 0.8)

var is_open := false
var _gate_body: StaticBody3D
var _gate_collision: CollisionShape3D
var _switch_orb: MeshInstance3D

func _ready() -> void:
    add_to_group("pulse_target")
    add_to_group("stage_gimmick")
    _build_visuals()

func trigger_pulse(pulse_position: Vector3) -> bool:
    if is_open:
        return false
    if global_position.distance_to(pulse_position) > activation_radius:
        return false
    is_open = true
    if is_instance_valid(_gate_collision):
        _gate_collision.set_deferred("disabled", true)
    if is_instance_valid(_switch_orb):
        var mat := _switch_orb.material_override as StandardMaterial3D
        if mat != null:
            mat.albedo_color = Color(0.22, 1.0, 0.48, 1.0)
            mat.emission = Color(0.12, 1.0, 0.35, 1.0)
    if is_instance_valid(_gate_body):
        var tween := create_tween()
        tween.tween_property(_gate_body, "position:y", -2.7, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    opened.emit()
    return true

func _build_visuals() -> void:
    _switch_orb = MeshInstance3D.new()
    _switch_orb.name = "PulseSwitchOrb"
    _switch_orb.position = Vector3(0.0, 0.65, 0.0)
    var orb_mesh := SphereMesh.new()
    orb_mesh.radius = 0.32
    orb_mesh.height = 0.64
    _switch_orb.mesh = orb_mesh
    var orb_mat := StandardMaterial3D.new()
    orb_mat.albedo_color = Color(0.10, 0.48, 1.0, 1.0)
    orb_mat.emission_enabled = true
    orb_mat.emission = Color(0.08, 0.38, 1.0, 1.0)
    orb_mat.emission_energy_multiplier = 2.4
    _switch_orb.material_override = orb_mat
    add_child(_switch_orb)

    var pedestal := MeshInstance3D.new()
    pedestal.position = Vector3(0.0, 0.22, 0.0)
    var pedestal_mesh := CylinderMesh.new()
    pedestal_mesh.top_radius = 0.42
    pedestal_mesh.bottom_radius = 0.55
    pedestal_mesh.height = 0.44
    pedestal.mesh = pedestal_mesh
    var pedestal_mat := StandardMaterial3D.new()
    pedestal_mat.albedo_color = Color(0.28, 0.34, 0.32, 1.0)
    pedestal_mat.roughness = 0.92
    pedestal.material_override = pedestal_mat
    add_child(pedestal)

    _gate_body = StaticBody3D.new()
    _gate_body.name = "AncientBarrier"
    _gate_body.position = Vector3(0.0, gate_size.y * 0.5, -3.2)
    add_child(_gate_body)

    var gate_mesh_instance := MeshInstance3D.new()
    var gate_mesh := BoxMesh.new()
    gate_mesh.size = gate_size
    gate_mesh_instance.mesh = gate_mesh
    var gate_mat := StandardMaterial3D.new()
    gate_mat.albedo_color = Color(0.30, 0.36, 0.33, 1.0)
    gate_mat.roughness = 0.96
    gate_mesh_instance.material_override = gate_mat
    _gate_body.add_child(gate_mesh_instance)

    _gate_collision = CollisionShape3D.new()
    var gate_shape := BoxShape3D.new()
    gate_shape.size = gate_size
    _gate_collision.shape = gate_shape
    _gate_body.add_child(_gate_collision)
