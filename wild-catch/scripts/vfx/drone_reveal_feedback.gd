extends Node3D
class_name DroneRevealFeedback

var _markers: Array[Node3D] = []

func reveal(payloads: Array, duration: float = 3.6) -> void:
    _clear_markers()
    for payload_value in payloads:
        var payload := payload_value as Dictionary
        if not payload.has("world_position"):
            continue
        var marker := _build_marker()
        add_child(marker)
        marker.global_position = payload["world_position"] as Vector3 + Vector3.UP * 2.15
        _markers.append(marker)
        _animate_marker(marker, duration)

func _build_marker() -> Node3D:
    var root := Node3D.new()
    root.name = "DroneTargetMarker"

    var ring := MeshInstance3D.new()
    ring.name = "Ring"
    var torus := TorusMesh.new()
    torus.inner_radius = 0.42
    torus.outer_radius = 0.50
    torus.rings = 20
    torus.ring_segments = 8
    ring.mesh = torus
    ring.rotation_degrees.x = 90.0
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.26, 0.94, 1.0, 0.86)
    mat.emission_enabled = true
    mat.emission = Color(0.10, 0.78, 1.0, 1.0)
    mat.emission_energy_multiplier = 2.7
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    ring.material_override = mat
    root.add_child(ring)

    var pointer := MeshInstance3D.new()
    pointer.name = "Pointer"
    var cone := CylinderMesh.new()
    cone.top_radius = 0.0
    cone.bottom_radius = 0.18
    cone.height = 0.38
    cone.radial_segments = 8
    pointer.mesh = cone
    pointer.position.y = 0.68
    pointer.rotation_degrees.z = 180.0
    pointer.material_override = mat
    root.add_child(pointer)
    return root

func _animate_marker(marker: Node3D, duration: float) -> void:
    marker.scale = Vector3.ONE * 0.72
    var tween := create_tween()
    tween.set_loops(int(maxf(1.0, duration / 0.48)))
    tween.tween_property(marker, "scale", Vector3.ONE * 1.08, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    tween.tween_property(marker, "scale", Vector3.ONE * 0.82, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
    get_tree().create_timer(duration).timeout.connect(func() -> void:
        if is_instance_valid(marker):
            marker.queue_free()
        _markers.erase(marker)
    )

func _clear_markers() -> void:
    for marker in _markers:
        if is_instance_valid(marker):
            marker.queue_free()
    _markers.clear()
