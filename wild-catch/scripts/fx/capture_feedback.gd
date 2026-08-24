extends Node3D
class_name CaptureFeedback

func _ready() -> void:
    add_to_group("capture_feedback")

func play_capture(world_position: Vector3, accent: Color) -> void:
    var player := get_tree().get_first_node_in_group("player") as PlayerController
    if player != null:
        player.play_capture_feedback(world_position)

    var root := Node3D.new()
    root.global_position = world_position + Vector3.UP * 0.95
    add_child(root)

    for i in range(4):
        var ring := MeshInstance3D.new()
        var mesh := TorusMesh.new()
        mesh.inner_radius = 0.48 + float(i) * 0.10
        mesh.outer_radius = 0.56 + float(i) * 0.10
        mesh.rings = 28
        mesh.ring_segments = 10
        ring.mesh = mesh
        ring.rotation_degrees = Vector3(90.0, float(i) * 32.0, float(i % 2) * 18.0)
        ring.scale = Vector3.ONE * 0.20
        var mat := StandardMaterial3D.new()
        mat.albedo_color = accent.lightened(0.30)
        mat.emission_enabled = true
        mat.emission = accent.lightened(0.22)
        mat.emission_energy_multiplier = 3.6
        mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        ring.material_override = mat
        root.add_child(ring)
        var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
        tween.tween_interval(float(i) * 0.035)
        tween.tween_property(ring, "scale", Vector3.ONE * (1.75 + float(i) * 0.34), 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        tween.parallel().tween_property(ring, "rotation:y", ring.rotation.y + TAU * 0.75, 0.26)
        tween.tween_property(ring, "scale", Vector3.ONE * 0.08, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

    for i in range(8):
        var spark := MeshInstance3D.new()
        var spark_mesh := SphereMesh.new()
        spark_mesh.radius = 0.07
        spark_mesh.height = 0.14
        spark_mesh.radial_segments = 6
        spark_mesh.rings = 3
        spark.mesh = spark_mesh
        var spark_mat := StandardMaterial3D.new()
        spark_mat.albedo_color = accent.lightened(0.38)
        spark_mat.emission_enabled = true
        spark_mat.emission = accent
        spark_mat.emission_energy_multiplier = 4.0
        spark.material_override = spark_mat
        root.add_child(spark)
        var angle := TAU * float(i) / 8.0
        var destination := Vector3(cos(angle), 0.25 + float(i % 3) * 0.18, sin(angle)) * 1.8
        var spark_tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
        spark_tween.tween_property(spark, "position", destination, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        spark_tween.parallel().tween_property(spark, "scale", Vector3.ZERO, 0.24)

    var flash := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.34
    sphere.height = 0.68
    flash.mesh = sphere
    flash.scale = Vector3.ONE * 0.18
    var flash_mat := StandardMaterial3D.new()
    flash_mat.albedo_color = Color(0.84, 0.98, 1.0, 1.0)
    flash_mat.emission_enabled = true
    flash_mat.emission = Color(0.35, 0.92, 1.0, 1.0)
    flash_mat.emission_energy_multiplier = 5.2
    flash.material_override = flash_mat
    root.add_child(flash)
    var flash_tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    flash_tween.tween_property(flash, "scale", Vector3.ONE * 1.75, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    flash_tween.tween_property(flash, "scale", Vector3.ZERO, 0.26)
    flash_tween.tween_callback(root.queue_free)

func play_pulse_hit(world_position: Vector3) -> void:
    var ring := MeshInstance3D.new()
    ring.global_position = world_position + Vector3.UP * 0.45
    var mesh := TorusMesh.new()
    mesh.inner_radius = 0.38
    mesh.outer_radius = 0.45
    mesh.rings = 20
    mesh.ring_segments = 8
    ring.mesh = mesh
    ring.rotation_degrees.x = 90.0
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.20, 0.76, 1.0, 1.0)
    mat.emission_enabled = true
    mat.emission = Color(0.08, 0.62, 1.0, 1.0)
    mat.emission_energy_multiplier = 3.0
    ring.material_override = mat
    add_child(ring)
    var tween := create_tween()
    tween.tween_property(ring, "scale", Vector3.ONE * 2.2, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.tween_property(ring, "scale", Vector3.ZERO, 0.14)
    tween.tween_callback(ring.queue_free)
