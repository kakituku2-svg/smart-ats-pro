extends Node
class_name SignatureActionDirector

signal signature_action(mimo_id: StringName, action_name: StringName)

var _cooldowns: Dictionary = {}
var _decoys: Array[Node3D] = []

func _ready() -> void:
    add_to_group("signature_action_director")
    for id in [&"lumi", &"goro", &"boka", &"nera", &"moku", &"raku"]:
        _cooldowns[id] = 1.2

func _process(delta: float) -> void:
    for key in _cooldowns.keys():
        _cooldowns[key] = maxf(0.0, float(_cooldowns[key]) - delta)
    for node in get_tree().get_nodes_in_group("mimo"):
        var mimo := node as MimoBase
        if mimo == null or mimo.state != MimoBase.State.PANIC:
            continue
        if float(_cooldowns.get(mimo.mimo_id, 0.0)) > 0.0:
            continue
        _trigger_signature(mimo)

func _trigger_signature(mimo: MimoBase) -> void:
    match mimo.mimo_id:
        &"lumi":
            _lumi_hide(mimo)
            _cooldowns[mimo.mimo_id] = 4.8
        &"goro":
            _goro_throw(mimo)
            _cooldowns[mimo.mimo_id] = 3.4
        &"boka":
            _boka_charge(mimo)
            _cooldowns[mimo.mimo_id] = 4.0
        &"nera":
            _nera_shock(mimo)
            _cooldowns[mimo.mimo_id] = 4.5
        &"moku":
            _moku_drowse(mimo)
            _cooldowns[mimo.mimo_id] = 5.6
        &"raku":
            _raku_decoys(mimo)
            _cooldowns[mimo.mimo_id] = 4.2

func _lumi_hide(mimo: MimoBase) -> void:
    signature_action.emit(mimo.mimo_id, &"grass_hide")
    mimo.stamina = minf(mimo.stamina_max, mimo.stamina + 12.0)
    mimo.set_meta("scan_hidden", true)
    var visual := mimo.get_node_or_null("Visual") as Node3D
    if visual != null:
        var tween := create_tween()
        tween.tween_property(visual, "scale", Vector3(0.55, 0.35, 0.55), 0.16)
        tween.tween_interval(0.65)
        tween.tween_property(visual, "scale", Vector3.ONE, 0.20).set_trans(Tween.TRANS_BACK)
    _restore_lumi_scan(mimo)

func _restore_lumi_scan(mimo: MimoBase) -> void:
    await get_tree().create_timer(0.95).timeout
    if is_instance_valid(mimo):
        mimo.set_meta("scan_hidden", false)

func _goro_throw(mimo: MimoBase) -> void:
    signature_action.emit(mimo.mimo_id, &"stone_throw")
    var player := get_tree().get_first_node_in_group("player") as PlayerController
    if player == null:
        return
    var rock := MeshInstance3D.new()
    rock.name = "GoroStone"
    var mesh := SphereMesh.new()
    mesh.radius = 0.28
    mesh.height = 0.56
    mesh.radial_segments = 8
    mesh.rings = 4
    rock.mesh = mesh
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.24, 0.21, 0.18, 1.0)
    mat.roughness = 1.0
    rock.material_override = mat
    get_tree().current_scene.add_child(rock)
    var start := mimo.global_position + Vector3.UP * 1.0
    var end := player.global_position + Vector3.UP * 0.7
    var mid := (start + end) * 0.5 + Vector3.UP * 2.2
    rock.global_position = start
    var tween := create_tween()
    tween.tween_method(func(t: float) -> void:
        if not is_instance_valid(rock):
            return
        var a := start.lerp(mid, t)
        var b := mid.lerp(end, t)
        rock.global_position = a.lerp(b, t)
    , 0.0, 1.0, 0.55)
    tween.tween_callback(func() -> void:
        if is_instance_valid(player) and player.global_position.distance_to(end) < 2.2:
            player.take_damage(1, player.global_position - start)
        if is_instance_valid(rock):
            rock.queue_free()
    )

func _boka_charge(mimo: MimoBase) -> void:
    signature_action.emit(mimo.mimo_id, &"counter_charge")
    var player := get_tree().get_first_node_in_group("player") as PlayerController
    if player == null:
        return
    var dir := player.global_position - mimo.global_position
    dir.y = 0.0
    if dir.length_squared() <= 0.01:
        return
    dir = dir.normalized()
    var start := mimo.global_position
    var charge_end := start + dir * 7.2
    mimo.velocity.x = dir.x * mimo.panic_speed * 1.8
    mimo.velocity.z = dir.z * mimo.panic_speed * 1.8
    _spawn_charge_telegraph(start, charge_end)
    _resolve_boka_charge(player, start, charge_end)

func _resolve_boka_charge(player: PlayerController, start: Vector3, charge_end: Vector3) -> void:
    await get_tree().create_timer(0.24).timeout
    if not is_instance_valid(player):
        return
    if _distance_point_to_segment_xz(player.global_position, start, charge_end) <= 1.55:
        player.take_damage(1, charge_end - start)

func _spawn_charge_telegraph(start: Vector3, charge_end: Vector3) -> void:
    var trail := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    var length := start.distance_to(charge_end)
    mesh.size = Vector3(0.22, 0.04, length)
    trail.mesh = mesh
    trail.global_position = (start + charge_end) * 0.5 + Vector3.UP * 0.08
    trail.look_at(charge_end, Vector3.UP)
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(1.0, 0.34, 0.20, 0.55)
    mat.emission_enabled = true
    mat.emission = Color(1.0, 0.18, 0.08, 1.0)
    mat.emission_energy_multiplier = 2.0
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    trail.material_override = mat
    get_tree().current_scene.add_child(trail)
    var tween := create_tween()
    tween.tween_property(trail, "modulate:a", 0.0, 0.42)
    tween.tween_callback(trail.queue_free)

func _nera_shock(mimo: MimoBase) -> void:
    signature_action.emit(mimo.mimo_id, &"spark_burst")
    var origin := mimo.global_position
    _spawn_ring(origin, Color(0.35, 0.75, 1.0, 0.9), 0.25, 4.5)
    _resolve_nera_shock(origin)

func _resolve_nera_shock(origin: Vector3) -> void:
    await get_tree().create_timer(0.24).timeout
    var player := get_tree().get_first_node_in_group("player") as PlayerController
    if player != null and player.global_position.distance_to(origin) <= 5.2:
        player.take_damage(1, player.global_position - origin)
        player.apply_slow(0.48, 1.8)

func _moku_drowse(mimo: MimoBase) -> void:
    signature_action.emit(mimo.mimo_id, &"sleep_cloud")
    var origin := mimo.global_position
    _spawn_ring(origin, Color(0.62, 0.48, 0.94, 0.72), 0.30, 3.7)
    mimo.stamina = maxf(0.0, mimo.stamina - 8.0)
    _run_moku_cloud(origin)

func _run_moku_cloud(origin: Vector3) -> void:
    var elapsed := 0.0
    while elapsed < 1.8:
        await get_tree().create_timer(0.20).timeout
        elapsed += 0.20
        var player := get_tree().get_first_node_in_group("player") as PlayerController
        if player != null and player.global_position.distance_to(origin) <= 4.2:
            player.apply_slow(0.62, 0.45)

func _raku_decoys(mimo: MimoBase) -> void:
    signature_action.emit(mimo.mimo_id, &"decoy_split")
    for old in _decoys:
        if is_instance_valid(old):
            old.queue_free()
    _decoys.clear()
    for side in [-1.0, 1.0]:
        var decoy := Node3D.new()
        decoy.name = "RakuDecoy"
        decoy.add_to_group("raku_decoy")
        get_tree().current_scene.add_child(decoy)
        decoy.global_position = mimo.global_position + Vector3(side * 2.4, 0.2, -1.0)
        var body := MeshInstance3D.new()
        var mesh := SphereMesh.new()
        mesh.radius = 0.62
        mesh.height = 1.24
        mesh.radial_segments = 10
        mesh.rings = 5
        body.mesh = mesh
        var mat := StandardMaterial3D.new()
        mat.albedo_color = Color(0.95, 0.34, 0.74, 0.58)
        mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        mat.emission_enabled = true
        mat.emission = Color(0.95, 0.22, 0.70, 1.0)
        mat.emission_energy_multiplier = 1.6
        body.material_override = mat
        decoy.add_child(body)
        _decoys.append(decoy)
        var tween := create_tween()
        tween.tween_property(decoy, "position:y", 0.65, 0.22)
        tween.tween_interval(1.1)
        tween.tween_property(decoy, "scale", Vector3.ZERO, 0.20)
        tween.tween_callback(func() -> void:
            if is_instance_valid(decoy):
                decoy.queue_free()
        )

func _spawn_ring(origin: Vector3, color: Color, start_radius: float, end_radius: float) -> void:
    var ring := MeshInstance3D.new()
    var torus := TorusMesh.new()
    torus.inner_radius = 0.82
    torus.outer_radius = 1.0
    torus.rings = 24
    torus.ring_segments = 8
    ring.mesh = torus
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.emission_enabled = true
    mat.emission = color
    mat.emission_energy_multiplier = 2.2
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    ring.material_override = mat
    get_tree().current_scene.add_child(ring)
    ring.global_position = origin + Vector3.UP * 0.18
    ring.rotation_degrees.x = 90.0
    ring.scale = Vector3.ONE * start_radius
    var tween := create_tween()
    tween.tween_property(ring, "scale", Vector3.ONE * end_radius, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.38)
    tween.tween_callback(func() -> void:
        if is_instance_valid(ring):
            ring.queue_free()
    )

func _distance_point_to_segment_xz(point: Vector3, a: Vector3, b: Vector3) -> float:
    var p := Vector2(point.x, point.z)
    var av := Vector2(a.x, a.z)
    var bv := Vector2(b.x, b.z)
    var ab := bv - av
    if ab.length_squared() <= 0.0001:
        return p.distance_to(av)
    var t := clampf((p - av).dot(ab) / ab.length_squared(), 0.0, 1.0)
    return p.distance_to(av + ab * t)
