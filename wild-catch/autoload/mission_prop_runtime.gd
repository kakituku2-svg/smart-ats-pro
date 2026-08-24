extends Node

var _time := 0.0
var _flags: Array[MeshInstance3D] = []
var _flag_base_rotations: Dictionary = {}
var _warning_lights: Array[MeshInstance3D] = []

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().node_added.connect(_on_node_added)

func _process(delta: float) -> void:
    _time += delta
    for flag in _flags:
        if not is_instance_valid(flag):
            continue
        var id := flag.get_instance_id()
        var base: Vector3 = _flag_base_rotations.get(id, flag.rotation)
        flag.rotation = base + Vector3(0.0, sin(_time * 2.1 + float(id % 13)) * 0.12, sin(_time * 3.0 + float(id % 7)) * 0.08)
    for light_mesh in _warning_lights:
        if not is_instance_valid(light_mesh):
            continue
        var mat := light_mesh.material_override as StandardMaterial3D
        if mat == null:
            continue
        mat.emission_energy_multiplier = 1.3 + (sin(_time * 4.0 + float(light_mesh.get_instance_id() % 11)) * 0.5 + 0.5) * 1.6

func _on_node_added(node: Node) -> void:
    if node is Node3D and String(node.name) in ["Stage2", "Stage3"]:
        call_deferred("_install", node)

func _install(stage: Node3D) -> void:
    await get_tree().process_frame
    if not is_instance_valid(stage) or stage.get_node_or_null("MissionProps") != null:
        return
    var root := Node3D.new()
    root.name = "MissionProps"
    stage.add_child(root)
    if stage.name == "Stage2":
        _build_stage2_props(root)
    elif stage.name == "Stage3":
        _build_stage3_props(root)

func _build_stage2_props(root: Node3D) -> void:
    var post_color := Color(0.22, 0.23, 0.24, 1.0)
    var teal := Color(0.22, 0.82, 0.95, 1.0)
    var orange := Color(1.0, 0.58, 0.16, 1.0)
    var stations := [
        Vector3(-17, 0.2, -7), Vector3(-10, 0.2, 10), Vector3(-1, 0.2, -15),
        Vector3(8, 0.2, 2), Vector3(15, 0.2, -13), Vector3(18, 0.2, 10),
    ]
    for i in range(stations.size()):
        var p: Vector3 = stations[i]
        _add_cylinder(root, "MooringPost%02d" % i, p + Vector3(0, 1.25, 0), 0.11, 2.5, post_color)
        var arm := _add_box(root, "WindVaneArm%02d" % i, p + Vector3(0.42, 2.22, 0), Vector3(0.84, 0.06, 0.06), post_color)
        arm.rotation_degrees.z = -8.0 if i % 2 == 0 else 8.0
        var flag := _add_box(root, "WindFlag%02d" % i, p + Vector3(0.82, 2.17, 0), Vector3(0.72, 0.34, 0.035), teal if i % 2 == 0 else orange, true)
        flag.rotation_degrees.y = float(i) * 27.0
        _flags.append(flag)
        _flag_base_rotations[flag.get_instance_id()] = flag.rotation
    var crates := [Vector3(-6, 0.35, 7), Vector3(-4.9, 0.35, 7.3), Vector3(11, 0.35, 5), Vector3(12, 0.35, 5.6)]
    for i in range(crates.size()):
        _add_box(root, "WindCrate%02d" % i, crates[i], Vector3(0.9, 0.7, 0.9), Color(0.32, 0.24, 0.13, 1.0))
    for i in range(4):
        var x := -7.5 + float(i) * 5.0
        _add_box(root, "BridgeRailL%02d" % i, Vector3(x, 1.72, -11.0), Vector3(4.2, 0.08, 0.08), Color(0.19, 0.16, 0.12, 1.0))
        _add_box(root, "BridgeRailR%02d" % i, Vector3(x, 1.72, -9.0), Vector3(4.2, 0.08, 0.08), Color(0.19, 0.16, 0.12, 1.0))

func _build_stage3_props(root: Node3D) -> void:
    var metal := Color(0.12, 0.17, 0.20, 1.0)
    var cyan := Color(0.24, 1.0, 0.78, 1.0)
    var violet := Color(0.70, 0.38, 1.0, 1.0)
    var pink := Color(1.0, 0.32, 0.72, 1.0)
    var tanks := [Vector3(-11, 0, -13), Vector3(-7, 0, -13), Vector3(11, 0, -5), Vector3(15, 0, -5)]
    for i in range(tanks.size()):
        var p: Vector3 = tanks[i]
        _add_cylinder(root, "ResearchTank%02d" % i, p + Vector3(0, 1.5, 0), 0.72, 3.0, metal)
        _add_cylinder(root, "ResearchTankCore%02d" % i, p + Vector3(0, 1.5, -0.01), 0.54, 2.42, [cyan, violet, pink][i % 3], true)
        _add_ring(root, "TankRingA%02d" % i, p + Vector3(0, 0.72, 0), 0.76, metal)
        _add_ring(root, "TankRingB%02d" % i, p + Vector3(0, 2.28, 0), 0.76, metal)
    var pipe_positions := [
        [Vector3(-15, 1.1, -4), Vector3(3.2, 0.11, 0.11)],
        [Vector3(-12, 1.6, 6), Vector3(6.0, 0.12, 0.12)],
        [Vector3(10, 1.1, 1), Vector3(4.8, 0.10, 0.10)],
        [Vector3(13, 1.7, 9), Vector3(5.6, 0.10, 0.10)],
    ]
    for i in range(pipe_positions.size()):
        var entry: Array = pipe_positions[i]
        _add_box(root, "LabPipe%02d" % i, entry[0] as Vector3, entry[1] as Vector3, metal.lightened(0.05))
    var terminal_positions := [Vector3(-4, 0.55, -7), Vector3(5, 0.55, -8), Vector3(-17, 0.55, 5), Vector3(16, 0.55, 9)]
    for i in range(terminal_positions.size()):
        var p: Vector3 = terminal_positions[i]
        _add_box(root, "FieldTerminal%02d" % i, p, Vector3(0.72, 1.10, 0.48), metal)
        var screen := _add_box(root, "FieldTerminalScreen%02d" % i, p + Vector3(0, 0.15, -0.255), Vector3(0.48, 0.38, 0.025), cyan if i % 2 == 0 else violet, true)
        screen.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    for i in range(7):
        var angle := TAU * float(i) / 7.0
        var p := Vector3(sin(angle) * 18.0, 0.95, cos(angle) * 18.0)
        _add_cylinder(root, "WarningPost%02d" % i, p, 0.06, 1.8, metal)
        var lamp := _add_sphere(root, "WarningLight%02d" % i, p + Vector3(0, 1.02, 0), 0.15, pink if i % 2 == 0 else cyan, true)
        lamp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        _warning_lights.append(lamp)

func _add_box(parent: Node3D, node_name: String, position_value: Vector3, size_value: Vector3, color: Color, emissive: bool = false) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = node_name
    node.position = position_value
    var mesh := BoxMesh.new()
    mesh.size = size_value
    node.mesh = mesh
    node.material_override = _material(color, emissive)
    parent.add_child(node)
    return node

func _add_cylinder(parent: Node3D, node_name: String, position_value: Vector3, radius: float, height: float, color: Color, emissive: bool = false) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = node_name
    node.position = position_value
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius * 1.04
    mesh.height = height
    mesh.radial_segments = 12
    node.mesh = mesh
    node.material_override = _material(color, emissive)
    parent.add_child(node)
    return node

func _add_ring(parent: Node3D, node_name: String, position_value: Vector3, radius: float, color: Color) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = node_name
    node.position = position_value
    var mesh := TorusMesh.new()
    mesh.inner_radius = radius
    mesh.outer_radius = radius + 0.08
    mesh.rings = 16
    mesh.ring_segments = 8
    node.mesh = mesh
    node.material_override = _material(color, false)
    parent.add_child(node)
    return node

func _add_sphere(parent: Node3D, node_name: String, position_value: Vector3, radius: float, color: Color, emissive: bool) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = node_name
    node.position = position_value
    var mesh := SphereMesh.new()
    mesh.radius = radius
    mesh.height = radius * 2.0
    mesh.radial_segments = 10
    mesh.rings = 5
    node.mesh = mesh
    node.material_override = _material(color, emissive)
    parent.add_child(node)
    return node

func _material(color: Color, emissive: bool) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.90 if not emissive else 0.48
    if emissive:
        mat.emission_enabled = true
        mat.emission = color
        mat.emission_energy_multiplier = 1.8
    return mat
