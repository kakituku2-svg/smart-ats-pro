extends Node3D
class_name ScanFeedback

const LIFE_SECONDS := 1.35

var _target: Node3D

func play(player_node: Node3D, target_node: Node3D = null) -> void:
    _target = target_node
    if is_instance_valid(player_node):
        global_position = player_node.global_position + Vector3.UP * 0.08
    _build_scan_wave()
    if is_instance_valid(_target):
        _build_target_beacon(_target.global_position + Vector3.UP * 1.55)
    var timer := get_tree().create_timer(LIFE_SECONDS)
    timer.timeout.connect(queue_free)

func _build_scan_wave() -> void:
    var ring := MeshInstance3D.new()
    ring.name = "ScanWave"
    var mesh := TorusMesh.new()
    mesh.inner_radius = 0.88
    mesh.outer_radius = 1.0
    mesh.rings = 8
    mesh.ring_segments = 40
    ring.mesh = mesh
    ring.rotation_degrees.x = 90.0
    ring.scale = Vector3.ONE * 0.18
    ring.material_override = _glow_material(Color(0.10, 0.92, 0.88, 0.82), 2.0)
    add_child(ring)

    var inner := MeshInstance3D.new()
    inner.name = "ScanWaveInner"
    var inner_mesh := TorusMesh.new()
    inner_mesh.inner_radius = 0.42
    inner_mesh.outer_radius = 0.48
    inner_mesh.rings = 8
    inner_mesh.ring_segments = 32
    inner.mesh = inner_mesh
    inner.rotation_degrees.x = 90.0
    inner.scale = Vector3.ONE * 0.14
    inner.material_override = _glow_material(Color(0.35, 1.0, 0.76, 0.72), 1.5)
    add_child(inner)

    var tween := create_tween().set_parallel(true)
    tween.tween_property(ring, "scale", Vector3.ONE * 8.5, 0.90).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.tween_property(inner, "scale", Vector3.ONE * 6.8, 0.72).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.tween_property(ring, "position:y", 0.20, 0.90)
    tween.tween_property(inner, "position:y", 0.12, 0.72)

func _build_target_beacon(world_position: Vector3) -> void:
    var beacon := Node3D.new()
    beacon.name = "TargetBeacon"
    add_child(beacon)
    beacon.global_position = world_position

    for i in range(3):
        var ring := MeshInstance3D.new()
        ring.name = "BeaconRing%d" % (i + 1)
        var mesh := TorusMesh.new()
        mesh.inner_radius = 0.33 + float(i) * 0.07
        mesh.outer_radius = 0.39 + float(i) * 0.07
        mesh.rings = 8
        mesh.ring_segments = 28
        ring.mesh = mesh
        ring.position.y = float(i) * 0.23
        ring.rotation_degrees.x = 90.0
        ring.material_override = _glow_material(Color(0.16, 0.85, 1.0, 0.90), 2.4)
        beacon.add_child(ring)
        var pulse := create_tween().set_loops(3)
        pulse.tween_property(ring, "scale", Vector3.ONE * 1.22, 0.17).set_trans(Tween.TRANS_SINE)
        pulse.tween_property(ring, "scale", Vector3.ONE * 0.92, 0.17).set_trans(Tween.TRANS_SINE)

    var stem := MeshInstance3D.new()
    stem.name = "BeaconStem"
    var stem_mesh := CylinderMesh.new()
    stem_mesh.top_radius = 0.018
    stem_mesh.bottom_radius = 0.035
    stem_mesh.height = 1.15
    stem_mesh.radial_segments = 6
    stem.mesh = stem_mesh
    stem.position.y = -0.46
    stem.material_override = _glow_material(Color(0.12, 0.78, 1.0, 0.55), 1.6)
    beacon.add_child(stem)

    var label := Label3D.new()
    label.name = "TargetLabel"
    label.text = "TARGET"
    label.position = Vector3(0, 0.72, 0)
    label.font_size = 28
    label.outline_size = 8
    label.modulate = Color(0.72, 0.97, 1.0, 1.0)
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    beacon.add_child(label)

    var beacon_tween := create_tween()
    beacon.scale = Vector3.ONE * 0.72
    beacon_tween.tween_property(beacon, "scale", Vector3.ONE * 1.08, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    beacon_tween.tween_property(beacon, "scale", Vector3.ONE, 0.12)

func _glow_material(color: Color, energy: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.albedo_color = color
    material.emission_enabled = true
    material.emission = Color(color.r, color.g, color.b, 1.0)
    material.emission_energy_multiplier = energy
    material.no_depth_test = false
    return material
