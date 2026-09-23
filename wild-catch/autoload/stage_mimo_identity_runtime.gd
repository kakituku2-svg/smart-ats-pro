extends Node

const STAGE2_IDS := [&"aero", &"kuru", &"vivi", &"toto", &"nagi"]
const STAGE3_IDS := [&"pico", &"luna", &"doro", &"nix", &"fufu", &"zari", &"ema"]

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
    if node is MimoBase:
        var mimo := node as MimoBase
        if mimo.mimo_id in STAGE2_IDS or mimo.mimo_id in STAGE3_IDS:
            call_deferred("_decorate", mimo)

func _decorate(mimo: MimoBase) -> void:
    await get_tree().process_frame
    if not is_instance_valid(mimo):
        return
    var id := mimo.mimo_id
    var final_glb := ProductionArtPaths.mimo_scene_path(id)
    var final_gltf := final_glb.trim_suffix(".glb") + ".gltf"
    if ResourceLoader.exists(final_glb) or ResourceLoader.exists(final_gltf):
        return
    var visual := mimo.get_node_or_null("Visual") as MimoVisualController
    if visual == null:
        return
    var art_root := visual.get_production_root()
    if art_root == null:
        art_root = visual
    if art_root.get_node_or_null("StageIdentityLayer") != null:
        return
    var layer := Node3D.new()
    layer.name = "StageIdentityLayer"
    art_root.add_child(layer)
    _apply_body_shape(art_root, id)
    match id:
        &"aero": _build_aero(layer, mimo.accent_color)
        &"kuru": _build_kuru(layer, mimo.accent_color)
        &"vivi": _build_vivi(layer, mimo.accent_color)
        &"toto": _build_toto(layer, mimo.accent_color)
        &"nagi": _build_nagi(layer, mimo.accent_color)
        &"pico": _build_pico(layer, mimo.accent_color)
        &"luna": _build_luna(layer, mimo.accent_color)
        &"doro": _build_doro(layer, mimo.accent_color)
        &"nix": _build_nix(layer, mimo.accent_color)
        &"fufu": _build_fufu(layer, mimo.accent_color)
        &"zari": _build_zari(layer, mimo.accent_color)
        &"ema": _build_ema(layer, mimo.accent_color)

func _apply_body_shape(root: Node3D, id: StringName) -> void:
    match id:
        &"aero": root.scale *= Vector3(0.88, 1.08, 0.86)
        &"kuru": root.scale *= Vector3(0.96, 0.95, 1.02)
        &"vivi": root.scale *= Vector3(0.84, 0.92, 0.82)
        &"toto": root.scale *= Vector3(1.12, 1.05, 1.06)
        &"nagi": root.scale *= Vector3(0.90, 1.14, 0.88)
        &"pico": root.scale *= Vector3(0.88, 1.00, 0.84)
        &"luna": root.scale *= Vector3(0.92, 1.08, 0.88)
        &"doro": root.scale *= Vector3(1.20, 0.82, 1.18)
        &"nix": root.scale *= Vector3(0.88, 1.12, 0.86)
        &"fufu": root.scale *= Vector3(0.94, 1.00, 0.90)
        &"zari": root.scale *= Vector3(1.14, 0.96, 1.10)
        &"ema": root.scale *= Vector3(0.90, 1.10, 0.90)

func _build_aero(layer: Node3D, color: Color) -> void:
    _prism(layer, "WingL", Vector3(-0.45, 0.86, 0.12), Vector3(0.20, 0.52, 0.42), Vector3(0, 0, -0.70), color.lightened(0.18), true)
    _prism(layer, "WingR", Vector3(0.45, 0.86, 0.12), Vector3(0.20, 0.52, 0.42), Vector3(0, 0, 0.70), color.lightened(0.18), true)
    _cone(layer, "WindCrest", Vector3(0, 1.62, 0.02), Vector3(0.18, 0.42, 0.18), Vector3.ZERO, Color(0.84, 0.96, 1.0, 1.0))

func _build_kuru(layer: Node3D, color: Color) -> void:
    _torus(layer, "SpiralHalo", Vector3(0, 1.58, 0), Vector3(0.78, 0.78, 0.78), Vector3(PI / 2.0, 0.35, 0), color, true)
    _cylinder(layer, "CurlTail", Vector3(0.34, 0.44, 0.32), Vector3(0.08, 0.55, 0.08), Vector3(1.10, 0.1, -0.52), color.darkened(0.12))
    _sphere(layer, "ForeheadDot", Vector3(0, 1.23, -0.43), Vector3(0.55, 0.55, 0.25), color.lightened(0.25), true)

func _build_vivi(layer: Node3D, color: Color) -> void:
    _sphere(layer, "LeafCape", Vector3(0, 0.67, 0.30), Vector3(2.1, 0.42, 1.45), Color(0.20, 0.58, 0.30, 1.0))
    _prism(layer, "LeafEarL", Vector3(-0.28, 1.35, 0.02), Vector3(0.18, 0.36, 0.24), Vector3(0, 0, -0.55), color, false)
    _prism(layer, "LeafEarR", Vector3(0.28, 1.35, 0.02), Vector3(0.18, 0.36, 0.24), Vector3(0, 0, 0.55), color, false)

func _build_toto(layer: Node3D, color: Color) -> void:
    _sphere(layer, "PunchL", Vector3(-0.47, 0.48, -0.08), Vector3(1.6, 1.25, 1.45), color.darkened(0.12))
    _sphere(layer, "PunchR", Vector3(0.47, 0.48, -0.08), Vector3(1.6, 1.25, 1.45), color.darkened(0.12))
    _cone(layer, "CenterHorn", Vector3(0, 1.48, -0.08), Vector3(0.18, 0.48, 0.18), Vector3(0.18, 0, 0), Color(1.0, 0.88, 0.46, 1.0))

func _build_nagi(layer: Node3D, color: Color) -> void:
    _prism(layer, "FeatherL", Vector3(-0.22, 1.55, 0.10), Vector3(0.13, 0.52, 0.20), Vector3(0, 0, -0.32), color.lightened(0.18), true)
    _prism(layer, "FeatherR", Vector3(0.22, 1.55, 0.10), Vector3(0.13, 0.52, 0.20), Vector3(0, 0, 0.32), color.lightened(0.18), true)
    _torus(layer, "SkyRing", Vector3(0, 1.82, 0), Vector3(0.64, 0.64, 0.64), Vector3(PI / 2.0, 0, 0), Color(0.72, 0.92, 1.0, 1.0), true)

func _build_pico(layer: Node3D, color: Color) -> void:
    for side in [-1.0, 1.0]:
        _cylinder(layer, "Antenna%s" % side, Vector3(side * 0.18, 1.52, 0), Vector3(0.04, 0.42, 0.04), Vector3(0, 0, side * -0.22), color.darkened(0.12))
        _sphere(layer, "Bulb%s" % side, Vector3(side * 0.25, 1.78, 0), Vector3(0.65, 0.65, 0.65), color.lightened(0.28), true)

func _build_luna(layer: Node3D, color: Color) -> void:
    _torus(layer, "MoonArc", Vector3(0.05, 1.48, -0.02), Vector3(0.82, 0.82, 0.82), Vector3(PI / 2.0, 0.25, 0.25), color.lightened(0.22), true)
    _prism(layer, "NightEarL", Vector3(-0.31, 1.36, 0.05), Vector3(0.16, 0.44, 0.22), Vector3(0, 0, -0.48), Color(0.16, 0.14, 0.34, 1.0), false)
    _prism(layer, "NightEarR", Vector3(0.31, 1.36, 0.05), Vector3(0.16, 0.44, 0.22), Vector3(0, 0, 0.48), Color(0.16, 0.14, 0.34, 1.0), false)

func _build_doro(layer: Node3D, color: Color) -> void:
    _sphere(layer, "MudShell", Vector3(0, 0.60, 0.24), Vector3(3.0, 1.55, 2.3), Color(0.23, 0.20, 0.14, 1.0))
    _sphere(layer, "MossPatch", Vector3(0, 0.96, 0.14), Vector3(2.2, 0.42, 1.7), color.darkened(0.18))
    _sphere(layer, "MudNose", Vector3(0, 1.00, -0.45), Vector3(0.9, 0.55, 0.42), Color(0.36, 0.26, 0.16, 1.0))

func _build_nix(layer: Node3D, color: Color) -> void:
    _box(layer, "FaceVisor", Vector3(0, 1.08, -0.44), Vector3(0.46, 0.12, 0.055), Vector3.ZERO, Color(0.10, 0.16, 0.24, 1.0), true)
    _prism(layer, "LongEarL", Vector3(-0.30, 1.48, 0.02), Vector3(0.14, 0.52, 0.19), Vector3(0, 0, -0.38), color, true)
    _prism(layer, "LongEarR", Vector3(0.30, 1.48, 0.02), Vector3(0.14, 0.52, 0.19), Vector3(0, 0, 0.38), color, true)

func _build_fufu(layer: Node3D, color: Color) -> void:
    _cylinder(layer, "TwinTailL", Vector3(-0.28, 0.48, 0.32), Vector3(0.07, 0.58, 0.07), Vector3(1.08, 0.1, 0.50), color.darkened(0.12))
    _cylinder(layer, "TwinTailR", Vector3(0.28, 0.48, 0.32), Vector3(0.07, 0.58, 0.07), Vector3(1.08, -0.1, -0.50), color.darkened(0.12))
    _box(layer, "TrickMask", Vector3(0, 1.08, -0.44), Vector3(0.52, 0.11, 0.05), Vector3(0, 0, -0.08), color.darkened(0.25), false)

func _build_zari(layer: Node3D, color: Color) -> void:
    _sphere(layer, "ClawL", Vector3(-0.50, 0.46, -0.10), Vector3(1.8, 1.18, 1.55), color.darkened(0.20))
    _sphere(layer, "ClawR", Vector3(0.50, 0.46, -0.10), Vector3(1.8, 1.18, 1.55), color.darkened(0.20))
    for side in [-1.0, 1.0]:
        _cone(layer, "Spine%s" % side, Vector3(side * 0.23, 1.42, 0.16), Vector3(0.15, 0.44, 0.15), Vector3(-0.35, 0, side * 0.18), Color(0.88, 0.72, 0.36, 1.0))

func _build_ema(layer: Node3D, color: Color) -> void:
    for i in range(5):
        var angle := TAU * float(i) / 5.0
        _prism(layer, "Petal%d" % i, Vector3(sin(angle) * 0.22, 1.58, cos(angle) * 0.12), Vector3(0.15, 0.38, 0.18), Vector3(0, angle, angle * 0.25), color.lightened(0.16), true)
    _cylinder(layer, "LongTail", Vector3(0.28, 0.45, 0.34), Vector3(0.055, 0.72, 0.055), Vector3(1.18, 0.0, -0.36), color.darkened(0.18))

func _sphere(parent: Node3D, name_value: String, pos: Vector3, scale_value: Vector3, color: Color, emissive: bool = false) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = name_value
    node.position = pos
    node.scale = scale_value
    var mesh := SphereMesh.new()
    mesh.radius = 0.10
    mesh.height = 0.20
    mesh.radial_segments = 8
    mesh.rings = 4
    node.mesh = mesh
    node.material_override = _mat(color, emissive)
    parent.add_child(node)
    return node

func _box(parent: Node3D, name_value: String, pos: Vector3, size_value: Vector3, rot: Vector3, color: Color, emissive: bool = false) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = name_value
    node.position = pos
    node.rotation = rot
    var mesh := BoxMesh.new()
    mesh.size = size_value
    node.mesh = mesh
    node.material_override = _mat(color, emissive)
    parent.add_child(node)
    return node

func _prism(parent: Node3D, name_value: String, pos: Vector3, size_value: Vector3, rot: Vector3, color: Color, emissive: bool) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = name_value
    node.position = pos
    node.rotation = rot
    var mesh := PrismMesh.new()
    mesh.size = size_value
    node.mesh = mesh
    node.material_override = _mat(color, emissive)
    parent.add_child(node)
    return node

func _cylinder(parent: Node3D, name_value: String, pos: Vector3, scale_value: Vector3, rot: Vector3, color: Color) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = name_value
    node.position = pos
    node.scale = scale_value
    node.rotation = rot
    var mesh := CylinderMesh.new()
    mesh.top_radius = 0.05
    mesh.bottom_radius = 0.07
    mesh.height = 0.60
    mesh.radial_segments = 7
    node.mesh = mesh
    node.material_override = _mat(color, false)
    parent.add_child(node)
    return node

func _cone(parent: Node3D, name_value: String, pos: Vector3, scale_value: Vector3, rot: Vector3, color: Color) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = name_value
    node.position = pos
    node.scale = scale_value
    node.rotation = rot
    var mesh := CylinderMesh.new()
    mesh.top_radius = 0.0
    mesh.bottom_radius = 0.12
    mesh.height = 0.60
    mesh.radial_segments = 7
    node.mesh = mesh
    node.material_override = _mat(color, false)
    parent.add_child(node)
    return node

func _torus(parent: Node3D, name_value: String, pos: Vector3, scale_value: Vector3, rot: Vector3, color: Color, emissive: bool) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = name_value
    node.position = pos
    node.scale = scale_value
    node.rotation = rot
    var mesh := TorusMesh.new()
    mesh.inner_radius = 0.22
    mesh.outer_radius = 0.28
    mesh.rings = 8
    mesh.ring_segments = 16
    node.mesh = mesh
    node.material_override = _mat(color, emissive)
    parent.add_child(node)
    return node

func _mat(color: Color, emissive: bool) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.78 if emissive else 0.90
    if emissive:
        mat.emission_enabled = true
        mat.emission = color
        mat.emission_energy_multiplier = 1.65
    return mat
