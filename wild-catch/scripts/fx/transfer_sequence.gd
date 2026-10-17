extends Node3D
class_name TransferSequence

signal arrival_finished
signal departure_finished

var _active := false

func play_arrival(player: PlayerController) -> void:
    if _active or player == null:
        return
    _active = true
    global_position = player.global_position
    player.clear_transient_input_state()
    player.set_physics_process(false)
    player.visible = false
    var beam := _make_beam(Color(0.22, 0.92, 1.0, 0.22))
    beam.scale = Vector3(0.22, 1.0, 0.22)
    var rings := _make_rings(Color(0.30, 1.0, 0.86, 1.0))
    var tween := create_tween().set_parallel(true)
    tween.tween_property(beam, "scale", Vector3(1.0, 1.0, 1.0), 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    for i in range(rings.size()):
        var ring := rings[i] as Node3D
        ring.position.y = 4.8 + float(i) * 0.9
        tween.tween_property(ring, "position:y", 0.28 + float(i) * 0.34, 0.62 + float(i) * 0.07).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
    await get_tree().create_timer(0.48).timeout
    player.visible = true
    await get_tree().create_timer(0.42).timeout
    var fade := create_tween()
    fade.tween_property(beam, "modulate:a", 0.0, 0.24)
    await fade.finished
    player.set_physics_process(true)
    player.clear_transient_input_state()
    arrival_finished.emit()
    queue_free()

func play_departure(player: PlayerController, on_complete: Callable = Callable()) -> void:
    if _active or player == null:
        return
    _active = true
    global_position = player.global_position
    player.clear_transient_input_state()
    player.set_physics_process(false)
    var beam := _make_beam(Color(0.34, 1.0, 0.72, 0.16))
    beam.scale = Vector3(0.18, 1.0, 0.18)
    var rings := _make_rings(Color(0.50, 1.0, 0.72, 1.0))
    for i in range(rings.size()):
        var ring := rings[i] as Node3D
        ring.position.y = 0.24 + float(i) * 0.34
    var tween := create_tween().set_parallel(true)
    tween.tween_property(beam, "scale", Vector3(1.15, 1.0, 1.15), 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    for i in range(rings.size()):
        var ring := rings[i] as Node3D
        tween.tween_property(ring, "position:y", 5.2 + float(i) * 0.8, 0.72 + float(i) * 0.06).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
    await get_tree().create_timer(0.46).timeout
    player.visible = false
    await get_tree().create_timer(0.52).timeout
    departure_finished.emit()
    if on_complete.is_valid():
        on_complete.call()
    queue_free()

func _make_beam(color: Color) -> MeshInstance3D:
    var beam := MeshInstance3D.new()
    beam.name = "TransferBeam"
    var mesh := CylinderMesh.new()
    mesh.top_radius = 1.3
    mesh.bottom_radius = 1.3
    mesh.height = 9.0
    mesh.radial_segments = 24
    beam.mesh = mesh
    beam.position.y = 4.2
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.emission_enabled = true
    material.emission = Color(color.r, color.g, color.b, 1.0)
    material.emission_energy_multiplier = 1.8
    beam.material_override = material
    add_child(beam)
    return beam

func _make_rings(color: Color) -> Array[Node3D]:
    var output: Array[Node3D] = []
    for i in range(5):
        var ring := MeshInstance3D.new()
        ring.name = "TransferRing%d" % i
        var torus := TorusMesh.new()
        torus.inner_radius = 0.74 + float(i) * 0.05
        torus.outer_radius = 0.82 + float(i) * 0.05
        torus.rings = 10
        torus.ring_segments = 24
        ring.mesh = torus
        ring.rotation_degrees = Vector3(90, float(i) * 18.0, 0)
        var material := StandardMaterial3D.new()
        material.albedo_color = color
        material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        material.emission_enabled = true
        material.emission = color
        material.emission_energy_multiplier = 2.1
        ring.material_override = material
        add_child(ring)
        output.append(ring)
    return output
