extends Node3D
class_name MimoPreviewArt

@onready var rig: Node3D = $Rig
@onready var body: MeshInstance3D = $Rig/Body
@onready var head: MeshInstance3D = $Rig/Head
@onready var ear_l: MeshInstance3D = $Rig/EarL
@onready var ear_r: MeshInstance3D = $Rig/EarR
@onready var eye_l: MeshInstance3D = $Rig/EyeL
@onready var eye_r: MeshInstance3D = $Rig/EyeR
@onready var arm_l: MeshInstance3D = $Rig/ArmL
@onready var arm_r: MeshInstance3D = $Rig/ArmR
@onready var foot_l: MeshInstance3D = $Rig/FootL
@onready var foot_r: MeshInstance3D = $Rig/FootR
@onready var halo: MeshInstance3D = $Rig/Halo
@onready var orb: MeshInstance3D = $Rig/Orb
@onready var stone_band: MeshInstance3D = $Rig/StoneBand
@onready var boxer_band: MeshInstance3D = $Rig/BoxerBand
@onready var spark_fin: MeshInstance3D = $Rig/SparkFin
@onready var sleepy_leaf: MeshInstance3D = $Rig/SleepyLeaf
@onready var trick_tail: MeshInstance3D = $Rig/TrickTail

func _ready() -> void:
    var mimo := _find_mimo_owner()
    if mimo == null:
        return
    _apply_palette(mimo)
    _apply_identity(mimo.mimo_id, mimo.accent_color)
    _add_face_finish(mimo.mimo_id, mimo.accent_color)

func _find_mimo_owner() -> MimoBase:
    var node: Node = get_parent()
    while node != null:
        if node is MimoBase:
            return node as MimoBase
        node = node.get_parent()
    return null

func _apply_palette(mimo: MimoBase) -> void:
    var accent := mimo.accent_color
    var body_color := accent.darkened(0.46).lerp(Color(0.42, 0.25, 0.15, 1.0), 0.42)
    body.material_override = _material(body_color, false)
    arm_l.material_override = _material(body_color.darkened(0.04), false)
    arm_r.material_override = _material(body_color.darkened(0.04), false)
    var cream := Color(0.94, 0.82, 0.64, 1.0)
    head.material_override = _material(cream, false)
    ear_l.material_override = _material(cream.lerp(accent, 0.12), false)
    ear_r.material_override = _material(cream.lerp(accent, 0.12), false)
    foot_l.material_override = _material(cream.darkened(0.05), false)
    foot_r.material_override = _material(cream.darkened(0.05), false)
    halo.material_override = _material(accent.lightened(0.18), true)
    orb.material_override = _material(accent.lightened(0.08), true)

func _apply_identity(mimo_id: StringName, accent: Color) -> void:
    stone_band.visible = mimo_id == &"goro"
    boxer_band.visible = mimo_id == &"boka"
    spark_fin.visible = mimo_id == &"nera"
    sleepy_leaf.visible = mimo_id == &"moku"
    trick_tail.visible = mimo_id == &"raku"
    match mimo_id:
        &"goro":
            _build_goro(accent)
        &"boka":
            _build_boka(accent)
        &"nera":
            _build_nera(accent)
        &"moku":
            _build_moku(accent)
        &"raku":
            _build_raku(accent)
        _:
            pass

func _build_goro(_accent: Color) -> void:
    stone_band.material_override = _material(Color(0.47, 0.50, 0.46, 1.0), false)
    body.scale *= Vector3(1.12, 0.96, 1.10)
    head.scale *= Vector3(1.08, 0.94, 1.08)
    ear_l.scale *= Vector3(1.08, 0.78, 1.10)
    ear_r.scale *= Vector3(1.08, 0.78, 1.10)
    arm_l.scale *= Vector3(1.20, 1.12, 1.20)
    arm_r.scale *= Vector3(1.20, 1.12, 1.20)
    _add_sphere("StoneShoulderL", Vector3(-0.39, 0.66, 0.02), Vector3(1.35, 0.85, 1.15), Color(0.40, 0.43, 0.40, 1.0))
    _add_sphere("StoneShoulderR", Vector3(0.39, 0.66, 0.02), Vector3(1.35, 0.85, 1.15), Color(0.40, 0.43, 0.40, 1.0))
    _add_box("StoneBrowL", Vector3(-0.14, 1.15, -0.43), Vector3(0.19, 0.055, 0.06), Vector3(0, 0, -0.18), Color(0.32, 0.34, 0.32, 1.0))
    _add_box("StoneBrowR", Vector3(0.14, 1.15, -0.43), Vector3(0.19, 0.055, 0.06), Vector3(0, 0, 0.18), Color(0.32, 0.34, 0.32, 1.0))
    _add_sphere("ForeheadStone", Vector3(0, 1.36, -0.23), Vector3(0.72, 0.48, 0.42), Color(0.50, 0.52, 0.47, 1.0))

func _build_boka(_accent: Color) -> void:
    boxer_band.material_override = _material(Color(0.95, 0.28, 0.18, 1.0), false)
    body.scale *= Vector3(1.05, 1.02, 0.98)
    head.scale *= Vector3(0.96, 0.95, 0.94)
    arm_l.scale *= Vector3(1.34, 1.24, 1.34)
    arm_r.scale *= Vector3(1.34, 1.24, 1.34)
    ear_l.rotation.z += 0.10
    ear_r.rotation.z -= 0.10
    var glove := Color(0.96, 0.22, 0.12, 1.0)
    _add_sphere("GloveL", Vector3(-0.43, 0.34, -0.06), Vector3(1.48, 1.18, 1.34), glove)
    _add_sphere("GloveR", Vector3(0.43, 0.34, -0.06), Vector3(1.48, 1.18, 1.34), glove)
    _add_box("ChestStripe", Vector3(0, 0.68, -0.33), Vector3(0.48, 0.08, 0.06), Vector3(0, 0, 0), Color(1.0, 0.74, 0.22, 1.0))

func _build_nera(accent: Color) -> void:
    spark_fin.material_override = _material(Color(0.45, 0.70, 1.0, 1.0), true)
    body.scale *= Vector3(0.86, 1.10, 0.84)
    head.scale *= Vector3(0.90, 1.02, 0.88)
    ear_l.scale *= Vector3(0.72, 1.40, 0.72)
    ear_r.scale *= Vector3(0.72, 1.40, 0.72)
    ear_l.rotation.z -= 0.08
    ear_r.rotation.z += 0.08
    foot_l.scale *= Vector3(0.88, 0.92, 1.12)
    foot_r.scale *= Vector3(0.88, 0.92, 1.12)
    _add_prism("SparkFinL", Vector3(-0.26, 1.28, 0.08), Vector3(0.20, 0.34, 0.26), Vector3(0, 0, -0.42), accent.lightened(0.18), true)
    _add_prism("SparkFinR", Vector3(0.26, 1.28, 0.08), Vector3(0.20, 0.34, 0.26), Vector3(0, 0, 0.42), accent.lightened(0.18), true)
    _add_sphere("ShockCheekL", Vector3(-0.25, 0.98, -0.42), Vector3(0.55, 0.30, 0.20), accent.lightened(0.24), true)
    _add_sphere("ShockCheekR", Vector3(0.25, 0.98, -0.42), Vector3(0.55, 0.30, 0.20), accent.lightened(0.24), true)

func _build_moku(_accent: Color) -> void:
    sleepy_leaf.material_override = _material(Color(0.30, 0.64, 0.25, 1.0), false)
    body.scale *= Vector3(1.16, 0.90, 1.10)
    body.position.y -= 0.04
    head.position.y -= 0.07
    head.rotation.x = 0.12
    head.scale *= Vector3(1.04, 0.90, 1.02)
    ear_l.rotation.z = -0.62
    ear_r.rotation.z = 0.62
    ear_l.position.y -= 0.08
    ear_r.position.y -= 0.08
    eye_l.scale.y *= 0.28
    eye_r.scale.y *= 0.28
    foot_l.scale *= Vector3(1.14, 0.74, 1.15)
    foot_r.scale *= Vector3(1.14, 0.74, 1.15)
    _add_sphere("BellyPatch", Vector3(0, 0.49, -0.39), Vector3(2.05, 2.22, 0.34), Color(0.86, 0.78, 0.58, 1.0))
    _add_sphere("LeafCap", Vector3(-0.10, 1.42, -0.02), Vector3(1.28, 0.44, 0.72), Color(0.26, 0.58, 0.22, 1.0))

func _build_raku(accent: Color) -> void:
    trick_tail.material_override = _material(Color(0.86, 0.38, 0.74, 1.0), false)
    body.scale *= Vector3(0.90, 1.03, 0.88)
    head.scale *= Vector3(0.96, 0.94, 0.94)
    head.rotation.z = -0.06
    ear_l.rotation.z -= 0.22
    ear_r.rotation.z += 0.05
    ear_l.scale *= Vector3(0.86, 1.22, 0.80)
    ear_r.scale *= Vector3(1.05, 0.92, 0.92)
    arm_l.scale *= Vector3(0.92, 1.10, 0.92)
    arm_r.scale *= Vector3(1.08, 0.94, 1.08)
    _add_cylinder("TrickTail2", Vector3(-0.28, 0.48, 0.29), Vector3(0.07, 0.54, 0.07), Vector3(1.10, 0.08, 0.46), accent.darkened(0.12))
    _add_box("FaceMaskL", Vector3(-0.19, 1.09, -0.43), Vector3(0.19, 0.075, 0.05), Vector3(0, 0, -0.28), accent.darkened(0.18))
    _add_box("FaceMaskR", Vector3(0.19, 1.05, -0.43), Vector3(0.16, 0.06, 0.05), Vector3(0, 0, 0.16), accent.darkened(0.18))
    _add_sphere("TrickCharm", Vector3(0.28, 0.74, -0.34), Vector3(0.68, 0.68, 0.34), accent.lightened(0.22), true)

func _add_face_finish(mimo_id: StringName, accent: Color) -> void:
    var mouth_y := 0.93 if mimo_id != &"moku" else 0.88
    _add_sphere("Mouth", Vector3(0, mouth_y, -0.445), Vector3(0.58, 0.19, 0.16), Color(0.16, 0.09, 0.08, 1.0))
    if mimo_id != &"goro":
        _add_sphere("CheekL", Vector3(-0.25, 0.98, -0.42), Vector3(0.46, 0.24, 0.15), accent.lightened(0.34), false)
        _add_sphere("CheekR", Vector3(0.25, 0.98, -0.42), Vector3(0.46, 0.24, 0.15), accent.lightened(0.34), false)

func _add_sphere(node_name: String, position_value: Vector3, scale_value: Vector3, color: Color, emissive: bool = false) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = node_name
    node.position = position_value
    node.scale = scale_value
    var mesh := SphereMesh.new()
    mesh.radius = 0.10
    mesh.height = 0.20
    mesh.radial_segments = 10
    mesh.rings = 5
    node.mesh = mesh
    node.material_override = _material(color, emissive)
    rig.add_child(node)
    return node

func _add_box(node_name: String, position_value: Vector3, size_value: Vector3, rotation_value: Vector3, color: Color) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = node_name
    node.position = position_value
    node.rotation = rotation_value
    var mesh := BoxMesh.new()
    mesh.size = size_value
    node.mesh = mesh
    node.material_override = _material(color, false)
    rig.add_child(node)
    return node

func _add_prism(node_name: String, position_value: Vector3, size_value: Vector3, rotation_value: Vector3, color: Color, emissive: bool) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = node_name
    node.position = position_value
    node.rotation = rotation_value
    var mesh := PrismMesh.new()
    mesh.size = size_value
    node.mesh = mesh
    node.material_override = _material(color, emissive)
    rig.add_child(node)
    return node

func _add_cylinder(node_name: String, position_value: Vector3, scale_value: Vector3, rotation_value: Vector3, color: Color) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = node_name
    node.position = position_value
    node.scale = scale_value
    node.rotation = rotation_value
    var mesh := CylinderMesh.new()
    mesh.top_radius = 0.05
    mesh.bottom_radius = 0.07
    mesh.height = 0.60
    mesh.radial_segments = 8
    node.mesh = mesh
    node.material_override = _material(color, false)
    rig.add_child(node)
    return node

func _material(color: Color, emissive: bool) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.74 if emissive else 0.88
    if emissive:
        material.emission_enabled = true
        material.emission = color * 0.72
        material.emission_energy_multiplier = 1.55
    return material