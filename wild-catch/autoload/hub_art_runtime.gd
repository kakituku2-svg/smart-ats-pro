extends Node

var _time := 0.0
var _holograms: Array[Node3D] = []
var _hologram_bases: Dictionary = {}

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().node_added.connect(_on_node_added)

func _process(delta: float) -> void:
    _time += delta
    for node in _holograms:
        if not is_instance_valid(node):
            continue
        var id := node.get_instance_id()
        var base: Vector3 = _hologram_bases.get(id, node.position)
        var phase := float(id % 19) * 0.22
        node.position = base + Vector3(0, sin(_time * 1.8 + phase) * 0.035, 0)
        node.rotation.y += delta * 0.25

func _on_node_added(node: Node) -> void:
    if node is Node3D and node.name == "FieldBase":
        call_deferred("_install", node)

func _install(hub: Node3D) -> void:
    await get_tree().process_frame
    if not is_instance_valid(hub) or hub.get_node_or_null("HubArtPolish") != null:
        return
    var root := Node3D.new()
    root.name = "HubArtPolish"
    hub.add_child(root)
    _build_archive_wall(root)
    _build_mission_holograms(root)
    _build_service_consoles(root)
    _build_transfer_outer_ring(root)

func _build_archive_wall(root: Node3D) -> void:
    var archive := Node3D.new()
    archive.name = "CaptureArchive"
    archive.position = Vector3(-7.8, 0.0, -3.0)
    root.add_child(archive)

    var header := Label3D.new()
    header.text = "CAPTURE ARCHIVE  %02d / %02d" % [SaveManager.get_unique_capture_count(), SaveManager.get_bestiary_total()]
    header.font_size = 48
    header.outline_size = 8
    header.modulate = Color(0.62, 1.0, 0.88, 1.0)
    header.position = Vector3(0, 3.85, 0)
    header.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    archive.add_child(header)

    var ids := SaveManager.MIMO_IDS
    for i in range(ids.size()):
        var row := i / 6
        var col := i % 6
        var x := float(col) * 0.92
        var y := 2.75 - float(row) * 1.18
        var pod := Node3D.new()
        pod.name = "ArchivePod_%s" % String(ids[i])
        pod.position = Vector3(x, y, 0)
        archive.add_child(pod)

        var frame := MeshInstance3D.new()
        var frame_mesh := CylinderMesh.new()
        frame_mesh.top_radius = 0.30
        frame_mesh.bottom_radius = 0.34
        frame_mesh.height = 0.86
        frame_mesh.radial_segments = 10
        frame.mesh = frame_mesh
        frame.material_override = _mat(Color(0.07, 0.14, 0.17, 1.0), false, 0.80)
        pod.add_child(frame)

        var captured := SaveManager.has_captured(StringName(ids[i]))
        var color := _stage_color_for_index(i)
        var core := MeshInstance3D.new()
        core.name = "CapturedCore" if captured else "UnknownCore"
        var core_mesh := SphereMesh.new()
        core_mesh.radius = 0.16
        core_mesh.height = 0.32
        core_mesh.radial_segments = 8
        core_mesh.rings = 4
        core.mesh = core_mesh
        core.position = Vector3(0, 0.02, -0.31)
        core.material_override = _mat(color if captured else Color(0.12, 0.16, 0.18, 1.0), captured, 0.34)
        pod.add_child(core)

        var label := Label3D.new()
        label.text = JapaneseText.mimo_name(ids[i], "？？") if captured else "--"
        label.font_size = 26
        label.outline_size = 5
        label.modulate = color.lightened(0.18) if captured else Color(0.42, 0.48, 0.50, 1.0)
        label.position = Vector3(0, -0.54, -0.03)
        label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
        pod.add_child(label)

func _build_mission_holograms(root: Node3D) -> void:
    var positions := [Vector3(5.6, 1.05, -6.4), Vector3(7.2, 1.05, -3.5), Vector3(6.1, 1.05, -0.4)]
    for i in range(3):
        var stage_id := StringName("stage%d" % (i + 1))
        var mission := MissionRouter.get_mission(stage_id)
        var pedestal := Node3D.new()
        pedestal.name = "MissionHolo_%s" % String(stage_id)
        pedestal.position = positions[i]
        root.add_child(pedestal)

        var base := MeshInstance3D.new()
        var base_mesh := CylinderMesh.new()
        base_mesh.top_radius = 0.64
        base_mesh.bottom_radius = 0.78
        base_mesh.height = 0.52
        base_mesh.radial_segments = 12
        base.mesh = base_mesh
        base.material_override = _mat(Color(0.06, 0.16, 0.20, 1.0), false, 0.72)
        pedestal.add_child(base)

        var holo := MeshInstance3D.new()
        holo.name = "Hologram"
        var holo_mesh := SphereMesh.new()
        holo_mesh.radius = 0.46
        holo_mesh.height = 0.92
        holo_mesh.radial_segments = 10
        holo_mesh.rings = 5
        holo.mesh = holo_mesh
        holo.position = Vector3(0, 0.88, 0)
        var accent := mission.get("accent", Color.WHITE) as Color
        var unlocked := MissionRouter.is_unlocked(stage_id)
        holo.material_override = _transparent_mat(accent if unlocked else Color(0.22, 0.26, 0.28, 0.38), unlocked)
        pedestal.add_child(holo)
        _holograms.append(holo)
        _hologram_bases[holo.get_instance_id()] = holo.position

        var ring := MeshInstance3D.new()
        var ring_mesh := TorusMesh.new()
        ring_mesh.inner_radius = 0.52
        ring_mesh.outer_radius = 0.58
        ring_mesh.rings = 7
        ring_mesh.ring_segments = 18
        ring.mesh = ring_mesh
        ring.position = Vector3(0, 0.62, 0)
        ring.rotation_degrees.x = 90.0
        ring.material_override = _transparent_mat(accent, unlocked)
        pedestal.add_child(ring)

        var label := Label3D.new()
        label.text = String(mission.get("name", stage_id)) if unlocked else "LOCKED"
        label.font_size = 28
        label.outline_size = 6
        label.modulate = accent.lightened(0.12) if unlocked else Color(0.48, 0.50, 0.52, 1.0)
        label.position = Vector3(0, 1.62, 0)
        label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
        pedestal.add_child(label)

func _build_service_consoles(root: Node3D) -> void:
    var console_positions := [Vector3(-5.5, 0.65, 5.7), Vector3(-2.7, 0.65, 7.1), Vector3(2.6, 0.65, 7.1), Vector3(5.5, 0.65, 5.7)]
    for i in range(console_positions.size()):
        var console := MeshInstance3D.new()
        console.name = "ServiceConsole%02d" % i
        var mesh := BoxMesh.new()
        mesh.size = Vector3(1.55, 1.25, 0.72)
        console.mesh = mesh
        console.position = console_positions[i]
        console.rotation.y = atan2(-console.position.x, -console.position.z)
        console.material_override = _mat(Color(0.055, 0.12, 0.15, 1.0), false, 0.68)
        root.add_child(console)

        var screen := MeshInstance3D.new()
        var screen_mesh := BoxMesh.new()
        screen_mesh.size = Vector3(1.18, 0.56, 0.045)
        screen.mesh = screen_mesh
        screen.position = Vector3(0, 0.22, -0.385)
        screen.material_override = _mat([Color(0.28, 0.90, 1.0, 1.0), Color(0.45, 1.0, 0.62, 1.0), Color(1.0, 0.72, 0.25, 1.0), Color(0.72, 0.46, 1.0, 1.0)][i], true, 0.22)
        console.add_child(screen)

func _build_transfer_outer_ring(root: Node3D) -> void:
    var outer := Node3D.new()
    outer.name = "TransferMachinery"
    outer.position = Vector3(0, 0.0, -4.2)
    root.add_child(outer)
    for i in range(10):
        var angle := TAU * float(i) / 10.0
        var module := MeshInstance3D.new()
        module.name = "TransferModule%02d" % i
        var mesh := BoxMesh.new()
        mesh.size = Vector3(0.56, 0.88, 0.74)
        module.mesh = mesh
        module.position = Vector3(sin(angle) * 3.25, 0.42, cos(angle) * 3.25)
        module.rotation.y = angle
        module.material_override = _mat(Color(0.07, 0.18, 0.21, 1.0), false, 0.70)
        outer.add_child(module)
        var lamp := MeshInstance3D.new()
        var lamp_mesh := SphereMesh.new()
        lamp_mesh.radius = 0.075
        lamp_mesh.height = 0.15
        lamp_mesh.radial_segments = 6
        lamp_mesh.rings = 3
        lamp.mesh = lamp_mesh
        lamp.position = Vector3(0, 0.18, -0.39)
        lamp.material_override = _mat(Color(0.26, 0.94, 1.0, 1.0), true, 0.20)
        module.add_child(lamp)

func _stage_color_for_index(index: int) -> Color:
    if index < 6:
        return Color(0.36, 1.0, 0.68, 1.0)
    if index < 11:
        return Color(0.38, 0.80, 1.0, 1.0)
    return Color(0.78, 0.44, 1.0, 1.0)

func _mat(color: Color, emissive: bool, roughness: float) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = roughness
    if emissive:
        mat.emission_enabled = true
        mat.emission = color
        mat.emission_energy_multiplier = 1.75
    return mat

func _transparent_mat(color: Color, emissive: bool) -> StandardMaterial3D:
    var mat := _mat(color, emissive, 0.28)
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.albedo_color.a = 0.42 if emissive else 0.22
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    return mat
