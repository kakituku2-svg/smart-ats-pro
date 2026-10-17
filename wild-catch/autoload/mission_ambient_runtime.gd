extends Node

var _time := 0.0
var _rotors: Array[Node3D] = []
var _glow_plants: Array[MeshInstance3D] = []
var _plant_base_scales: Dictionary = {}
var _ambient_nodes: Array[Node3D] = []
var _ambient_base_positions: Dictionary = {}
var _ambient_phases: Dictionary = {}

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().node_added.connect(_on_node_added)

func _process(delta: float) -> void:
    _time += delta
    for rotor in _rotors:
        if not is_instance_valid(rotor):
            continue
        rotor.rotation.z += delta * 2.2
    for plant in _glow_plants:
        if not is_instance_valid(plant):
            continue
        var id := plant.get_instance_id()
        var base: Vector3 = _plant_base_scales.get(id, plant.scale)
        var phase := float(id % 17) * 0.37
        var pulse := 0.94 + sin(_time * 1.65 + phase) * 0.08
        plant.scale = base * pulse
    for node in _ambient_nodes:
        if not is_instance_valid(node):
            continue
        var id := node.get_instance_id()
        var base: Vector3 = _ambient_base_positions.get(id, node.position)
        var phase := float(_ambient_phases.get(id, 0.0))
        if String(node.name).begins_with("GustRing"):
            node.position = base + Vector3(sin(_time * 0.8 + phase) * 0.35, sin(_time * 1.35 + phase) * 0.22, cos(_time * 0.7 + phase) * 0.28)
            node.rotation.y += delta * (0.32 + fmod(phase, 0.35))
            node.rotation.x = sin(_time * 0.48 + phase) * 0.18
        elif String(node.name).begins_with("GlowSpore"):
            node.position = base + Vector3(sin(_time * 0.62 + phase) * 0.28, sin(_time * 1.05 + phase) * 0.42, cos(_time * 0.55 + phase) * 0.24)
            var s := 0.82 + sin(_time * 1.85 + phase) * 0.16
            node.scale = Vector3.ONE * s

func _on_node_added(node: Node) -> void:
    if node is Node3D and String(node.name) in ["Stage2", "Stage3"]:
        call_deferred("_install", node)

func _install(stage: Node3D) -> void:
    await get_tree().process_frame
    await get_tree().process_frame
    if not is_instance_valid(stage):
        return
    if stage.get_node_or_null("MissionAmbientFX") != null:
        return
    var root := Node3D.new()
    root.name = "MissionAmbientFX"
    stage.add_child(root)
    if stage.name == "Stage2":
        _bind_stage2_rotors(stage)
        _build_gust_rings(root)
    elif stage.name == "Stage3":
        _bind_stage3_plants(stage)
        _build_glow_spores(root)

func _bind_stage2_rotors(stage: Node3D) -> void:
    for child in stage.get_children():
        if not (child is Node3D) or not String(child.name).begins_with("WindTurbine"):
            continue
        var mesh_children: Array[Node] = child.get_children()
        if mesh_children.size() < 6:
            continue
        for index in range(2, mesh_children.size()):
            var blade := mesh_children[index] as Node3D
            if blade != null:
                _rotors.append(blade)

func _bind_stage3_plants(stage: Node3D) -> void:
    for child in stage.get_children():
        var mesh_instance := child as MeshInstance3D
        if mesh_instance == null or not (mesh_instance.mesh is SphereMesh):
            continue
        if mesh_instance.scale.y < mesh_instance.scale.x * 1.35:
            continue
        var material := mesh_instance.material_override as StandardMaterial3D
        if material == null or not material.emission_enabled:
            continue
        _glow_plants.append(mesh_instance)
        _plant_base_scales[mesh_instance.get_instance_id()] = mesh_instance.scale

func _build_gust_rings(root: Node3D) -> void:
    var positions := [
        Vector3(-17, 2.0, 8), Vector3(-10, 3.1, -7), Vector3(-2, 1.8, -14),
        Vector3(7, 2.6, -5), Vector3(14, 3.4, -12), Vector3(18, 2.2, 7),
        Vector3(10, 1.5, 15), Vector3(-5, 2.8, 13), Vector3(-20, 3.5, -13),
    ]
    for i in range(positions.size()):
        var ring := MeshInstance3D.new()
        ring.name = "GustRing%02d" % i
        var mesh := TorusMesh.new()
        mesh.inner_radius = 0.72 + float(i % 3) * 0.12
        mesh.outer_radius = mesh.inner_radius + 0.045
        mesh.rings = 6
        mesh.ring_segments = 18
        ring.mesh = mesh
        ring.position = positions[i]
        ring.rotation_degrees = Vector3(80 + float(i % 2) * 20.0, float(i) * 31.0, 0)
        var color := Color(0.52, 0.90, 1.0, 0.28)
        ring.material_override = _transparent_emissive(color, 1.25)
        root.add_child(ring)
        _register_ambient(ring, positions[i], float(i) * 0.73)

func _build_glow_spores(root: Node3D) -> void:
    var colors := [
        Color(0.28, 1.0, 0.72, 0.72),
        Color(0.65, 0.38, 1.0, 0.72),
        Color(1.0, 0.34, 0.74, 0.70),
    ]
    for i in range(22):
        var spore := MeshInstance3D.new()
        spore.name = "GlowSpore%02d" % i
        var mesh := SphereMesh.new()
        mesh.radius = 0.055 + float(i % 4) * 0.012
        mesh.height = mesh.radius * 2.0
        mesh.radial_segments = 6
        mesh.rings = 3
        spore.mesh = mesh
        var x := -21.0 + float((i * 11) % 42)
        var z := -19.0 + float((i * 7) % 38)
        var y := 1.1 + float(i % 5) * 0.62
        var base := Vector3(x, y, z)
        spore.position = base
        spore.material_override = _transparent_emissive(colors[i % colors.size()], 1.75)
        root.add_child(spore)
        _register_ambient(spore, base, float(i) * 0.59)

func _register_ambient(node: Node3D, base: Vector3, phase: float) -> void:
    _ambient_nodes.append(node)
    _ambient_base_positions[node.get_instance_id()] = base
    _ambient_phases[node.get_instance_id()] = phase

func _transparent_emissive(color: Color, energy: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.emission_enabled = true
    material.emission = Color(color.r, color.g, color.b, 1.0)
    material.emission_energy_multiplier = energy
    material.no_depth_test = false
    return material
