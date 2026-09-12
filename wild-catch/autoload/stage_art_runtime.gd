extends Node

## Runtime art layer for Stage 1.
## Production priority: stage1_set.glb -> stage1_set.gltf -> preview scene.
## Until production art exists, a low-cost procedural polish layer improves
## density, palette and atmosphere without changing traversal/collision/gameplay.

const STAGE_NAME := "Stage1"
const FALLBACK_ROOT := "RuntimeEnvironmentPolish"
const PRODUCTION_ROOT := "ProductionEnvironmentArt"
const FILL_LIGHT_NAME := "RuntimeFillLight"

var _installed_scene_ids: Dictionary = {}
var _animated_canopies: Array[Node3D] = []
var _canopy_base_rotations: Dictionary = {}
var _water_mesh: MeshInstance3D
var _water_material: StandardMaterial3D
var _time := 0.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().node_added.connect(_on_node_added)
    if get_tree().current_scene != null:
        _try_install(get_tree().current_scene)

func _process(delta: float) -> void:
    _time += delta
    for canopy in _animated_canopies:
        if not is_instance_valid(canopy):
            continue
        var base := float(_canopy_base_rotations.get(canopy.get_instance_id(), 0.0))
        canopy.rotation.z = base + sin(_time * 0.72 + float(canopy.get_instance_id() % 13)) * 0.022
    if is_instance_valid(_water_mesh) and _water_material != null:
        var shimmer := 0.5 + sin(_time * 1.25) * 0.5
        _water_material.albedo_color = Color(0.035 + shimmer * 0.018, 0.30 + shimmer * 0.035, 0.51 + shimmer * 0.05, 0.82)
        _water_material.emission = Color(0.015, 0.10 + shimmer * 0.025, 0.16 + shimmer * 0.035, 1.0)

func _on_node_added(node: Node) -> void:
    if node is Node3D and node.name == STAGE_NAME:
        call_deferred("_try_install", node)

func _try_install(stage: Node) -> void:
    if not is_instance_valid(stage) or not (stage is Node3D):
        return
    var id := stage.get_instance_id()
    if _installed_scene_ids.has(id):
        return
    _installed_scene_ids[id] = true
    var stage3d := stage as Node3D
    var production := ProductionArtPaths.stage1_scene()
    if production != null:
        _install_production_environment(stage3d, production)
    else:
        _install_fallback_polish(stage3d)
    _apply_environment_direction(stage3d)
    _register_ambient_motion(stage3d)

func _install_production_environment(stage: Node3D, scene: PackedScene) -> void:
    var instance := scene.instantiate()
    if not (instance is Node3D):
        push_warning("Stage 1 production scene root must be Node3D")
        instance.queue_free()
        return
    var root := instance as Node3D
    root.name = PRODUCTION_ROOT
    stage.add_child(root)
    for path in ["Ground", "GroundDetail", "Landmarks", "Decor", "TraversalLayer"]:
        var placeholder := stage.get_node_or_null(path)
        if placeholder != null:
            _set_visuals_visible(placeholder, false)

func _install_fallback_polish(stage: Node3D) -> void:
    if stage.get_node_or_null(FALLBACK_ROOT) != null:
        return
    var root := Node3D.new()
    root.name = FALLBACK_ROOT
    stage.add_child(root)
    _add_grass(root)
    _add_shrubs(root)
    _add_pebbles(root)
    _add_flower_accents(root)
    _add_water_reeds(root)
    _add_ruin_accents(root)

func _apply_environment_direction(stage: Node3D) -> void:
    var world := stage.get_node_or_null("WorldEnvironment") as WorldEnvironment
    if world != null and world.environment != null:
        var env := world.environment.duplicate(true) as Environment
        env.background_mode = Environment.BG_COLOR
        env.background_color = Color(0.11, 0.47, 0.72, 1.0)
        env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
        env.ambient_light_color = Color(0.60, 0.70, 0.64, 1.0)
        env.ambient_light_energy = 0.86
        env.fog_enabled = true
        env.fog_light_color = Color(0.62, 0.78, 0.78, 1.0)
        env.fog_light_energy = 0.72
        env.fog_density = 0.006
        env.fog_height = -1.5
        env.fog_height_density = 0.055
        env.fog_sky_affect = 0.28
        env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
        env.adjustment_enabled = true
        env.adjustment_brightness = 1.03
        env.adjustment_contrast = 1.05
        env.adjustment_saturation = 1.08
        world.environment = env

    var sun := stage.get_node_or_null("DirectionalLight3D") as DirectionalLight3D
    if sun != null:
        sun.light_color = Color(1.0, 0.93, 0.78, 1.0)
        sun.light_energy = 1.48
        sun.shadow_enabled = true

    if stage.get_node_or_null(FILL_LIGHT_NAME) == null:
        var fill := DirectionalLight3D.new()
        fill.name = FILL_LIGHT_NAME
        fill.rotation_degrees = Vector3(-32.0, 145.0, 0.0)
        fill.light_color = Color(0.42, 0.68, 0.82, 1.0)
        fill.light_energy = 0.28
        fill.shadow_enabled = false
        stage.add_child(fill)

func _add_grass(root: Node3D) -> void:
    var mesh := CylinderMesh.new()
    mesh.top_radius = 0.015
    mesh.bottom_radius = 0.055
    mesh.height = 0.46
    mesh.radial_segments = 4
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.08, 0.38, 0.16, 1.0)
    material.roughness = 1.0
    mesh.material = material
    var rng := RandomNumberGenerator.new()
    rng.seed = 54127
    var transforms: Array[Transform3D] = []
    while transforms.size() < 170:
        var x := rng.randf_range(-27.0, 27.0)
        var z := rng.randf_range(-27.0, 27.0)
        if Vector2(x, z).length() < 6.5:
            continue
        if x > 5.0 and x < 22.0 and z > 11.0 and z < 21.0:
            continue
        var t := Transform3D.IDENTITY
        t.origin = Vector3(x, 0.48, z)
        var angle := rng.randf_range(0.0, TAU)
        var scale := Vector3(rng.randf_range(0.75, 1.25), rng.randf_range(0.7, 1.35), rng.randf_range(0.75, 1.25))
        t.basis = Basis(Vector3.UP, angle).scaled(scale)
        transforms.append(t)
    _make_multimesh(root, "GrassTufts", mesh, transforms)

func _add_shrubs(root: Node3D) -> void:
    var mesh := SphereMesh.new()
    mesh.radius = 0.52
    mesh.height = 1.04
    mesh.radial_segments = 8
    mesh.rings = 4
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.055, 0.28, 0.12, 1.0)
    material.roughness = 0.96
    mesh.material = material
    var positions := [
        Vector3(-22, 0.62, -5), Vector3(-24, 0.62, 8), Vector3(-15, 0.62, 15),
        Vector3(-20, 0.62, -20), Vector3(-11, 0.62, -22), Vector3(2, 0.62, -24),
        Vector3(18, 0.62, -23), Vector3(23, 0.62, -12), Vector3(24, 0.62, 1),
        Vector3(21, 0.62, 9), Vector3(3, 0.62, 23), Vector3(-7, 0.62, 24),
        Vector3(-14, 0.62, 5), Vector3(7, 0.62, -17), Vector3(16, 0.62, -5),
    ]
    var transforms: Array[Transform3D] = []
    for i in range(positions.size()):
        var t := Transform3D.IDENTITY
        t.origin = positions[i]
        var s := 0.65 + float((i * 37) % 55) / 100.0
        t.basis = Basis.IDENTITY.scaled(Vector3(s * 1.25, s, s * 1.15))
        transforms.append(t)
    _make_multimesh(root, "ShrubClusters", mesh, transforms)

func _add_pebbles(root: Node3D) -> void:
    var mesh := BoxMesh.new()
    mesh.size = Vector3(0.55, 0.25, 0.42)
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.27, 0.31, 0.29, 1.0)
    material.roughness = 0.98
    mesh.material = material
    var rng := RandomNumberGenerator.new()
    rng.seed = 9137
    var transforms: Array[Transform3D] = []
    for i in range(48):
        var t := Transform3D.IDENTITY
        t.origin = Vector3(rng.randf_range(-25.0, 25.0), 0.43, rng.randf_range(-25.0, 25.0))
        t.basis = Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(Vector3(rng.randf_range(0.55, 1.35), rng.randf_range(0.6, 1.15), rng.randf_range(0.55, 1.35)))
        transforms.append(t)
    _make_multimesh(root, "RuinPebbles", mesh, transforms)

func _add_flower_accents(root: Node3D) -> void:
    var palettes := [
        ["SunFlowers", Color(1.0, 0.72, 0.20, 1.0), 1171],
        ["CoralFlowers", Color(1.0, 0.34, 0.36, 1.0), 1172],
        ["SkyFlowers", Color(0.32, 0.72, 1.0, 1.0), 1173],
    ]
    for entry in palettes:
        var mesh := SphereMesh.new()
        mesh.radius = 0.075
        mesh.height = 0.15
        mesh.radial_segments = 6
        mesh.rings = 3
        var material := StandardMaterial3D.new()
        material.albedo_color = entry[1] as Color
        material.emission_enabled = true
        material.emission = (entry[1] as Color) * 0.18
        material.roughness = 0.84
        mesh.material = material
        var rng := RandomNumberGenerator.new()
        rng.seed = int(entry[2])
        var transforms: Array[Transform3D] = []
        for i in range(18):
            var t := Transform3D.IDENTITY
            t.origin = Vector3(rng.randf_range(-23.0, 23.0), 0.70, rng.randf_range(-23.0, 23.0))
            t.basis = Basis.IDENTITY.scaled(Vector3.ONE * rng.randf_range(0.75, 1.25))
            transforms.append(t)
        _make_multimesh(root, String(entry[0]), mesh, transforms)

func _add_water_reeds(root: Node3D) -> void:
    var mesh := CylinderMesh.new()
    mesh.top_radius = 0.025
    mesh.bottom_radius = 0.045
    mesh.height = 0.95
    mesh.radial_segments = 5
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.18, 0.44, 0.20, 1.0)
    material.roughness = 1.0
    mesh.material = material
    var transforms: Array[Transform3D] = []
    for i in range(28):
        var side := -1.0 if i % 2 == 0 else 1.0
        var x := 7.3 + float(i % 14) * 0.72
        var z := 15.0 + side * (1.65 + float((i * 7) % 4) * 0.15)
        var t := Transform3D.IDENTITY
        t.origin = Vector3(x, 0.78, z)
        t.basis = Basis(Vector3.UP, float(i) * 0.47).scaled(Vector3(0.8, 0.8 + float(i % 5) * 0.08, 0.8))
        transforms.append(t)
    _make_multimesh(root, "WaterReeds", mesh, transforms)

func _add_ruin_accents(root: Node3D) -> void:
    var mesh := BoxMesh.new()
    mesh.size = Vector3(0.55, 1.65, 0.55)
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.34, 0.40, 0.37, 1.0)
    material.roughness = 0.98
    mesh.material = material
    var positions := [
        Vector3(-15.0, 1.08, -4.8), Vector3(-3.5, 1.08, -4.5),
        Vector3(5.0, 1.08, -16.5), Vector3(18.5, 1.08, -8.5),
        Vector3(-19.5, 1.08, -18.5), Vector3(20.0, 1.08, 18.0),
    ]
    var transforms: Array[Transform3D] = []
    for i in range(positions.size()):
        var t := Transform3D.IDENTITY
        t.origin = positions[i]
        t.basis = Basis(Vector3.UP, float(i) * 0.71).scaled(Vector3(0.75 + float(i % 2) * 0.18, 0.75 + float(i % 3) * 0.12, 0.75))
        transforms.append(t)
    _make_multimesh(root, "RuinColumns", mesh, transforms)

func _make_multimesh(root: Node3D, node_name: String, mesh: Mesh, transforms: Array[Transform3D]) -> void:
    var multimesh := MultiMesh.new()
    multimesh.transform_format = MultiMesh.TRANSFORM_3D
    multimesh.mesh = mesh
    multimesh.instance_count = transforms.size()
    for i in range(transforms.size()):
        multimesh.set_instance_transform(i, transforms[i])
    var instance := MultiMeshInstance3D.new()
    instance.name = node_name
    instance.multimesh = multimesh
    root.add_child(instance)

func _register_ambient_motion(stage: Node3D) -> void:
    var decor := stage.get_node_or_null("Decor")
    if decor != null:
        for tree in decor.get_children():
            var canopy := tree.get_node_or_null("Canopy") as Node3D
            if canopy != null:
                _animated_canopies.append(canopy)
                _canopy_base_rotations[canopy.get_instance_id()] = canopy.rotation.z
    _water_mesh = stage.get_node_or_null("Landmarks/Waterway") as MeshInstance3D
    if _water_mesh != null and _water_mesh.material_override is StandardMaterial3D:
        _water_material = (_water_mesh.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
        _water_material.emission_enabled = true
        _water_mesh.material_override = _water_material

func _set_visuals_visible(root: Node, value: bool) -> void:
    if root is VisualInstance3D:
        (root as VisualInstance3D).visible = value
    for child in root.get_children():
        _set_visuals_visible(child, value)
