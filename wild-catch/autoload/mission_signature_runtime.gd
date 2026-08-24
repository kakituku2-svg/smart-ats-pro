extends Node

signal signature_action(mimo_id: StringName, action_name: StringName)

const STAGE_IDS := ["Stage2", "Stage3"]
const COOLDOWNS := {
    &"aero": 3.6, &"kuru": 4.2, &"vivi": 4.8, &"toto": 4.0, &"nagi": 4.5,
    &"pico": 3.8, &"luna": 4.4, &"doro": 5.1, &"nix": 4.6, &"fufu": 4.0, &"zari": 3.9, &"ema": 5.4,
}

var _stage: Node3D
var _cooldowns: Dictionary = {}
var _active := false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().node_added.connect(_on_node_added)

func _process(delta: float) -> void:
    if not _active or not is_instance_valid(_stage):
        return
    for key in _cooldowns.keys():
        _cooldowns[key] = maxf(0.0, float(_cooldowns[key]) - delta)
    for node in get_tree().get_nodes_in_group("mimo"):
        var mimo := node as MimoBase
        if mimo == null or mimo.state != MimoBase.State.PANIC or not COOLDOWNS.has(mimo.mimo_id):
            continue
        if float(_cooldowns.get(mimo.mimo_id, 0.0)) > 0.0:
            continue
        _trigger(mimo)
        _cooldowns[mimo.mimo_id] = float(COOLDOWNS[mimo.mimo_id])

func _on_node_added(node: Node) -> void:
    if node is Node3D and String(node.name) in STAGE_IDS:
        call_deferred("_activate_for_stage", node)

func _activate_for_stage(stage: Node3D) -> void:
    if not is_instance_valid(stage):
        return
    _stage = stage
    _active = true
    _cooldowns.clear()
    for id in COOLDOWNS.keys():
        _cooldowns[id] = 1.4 + float(abs(hash(String(id))) % 10) * 0.08
    if not is_in_group("signature_action_director"):
        add_to_group("signature_action_director")
    stage.tree_exited.connect(_deactivate)
    call_deferred("_bind_mimo_visuals")

func _deactivate() -> void:
    _active = false
    _stage = null
    if is_in_group("signature_action_director"):
        remove_from_group("signature_action_director")

func _bind_mimo_visuals() -> void:
    await get_tree().process_frame
    for node in get_tree().get_nodes_in_group("mimo"):
        var mimo := node as MimoBase
        if mimo == null or not COOLDOWNS.has(mimo.mimo_id):
            continue
        var visual := mimo.get_node_or_null("Visual")
        if visual != null and visual.has_method("_on_signature_action"):
            var callable := Callable(visual, "_on_signature_action")
            if not signature_action.is_connected(callable):
                signature_action.connect(callable)

func _trigger(mimo: MimoBase) -> void:
    match mimo.mimo_id:
        &"aero": _wind_escape(mimo, &"spark_burst")
        &"kuru": _vortex_burst(mimo)
        &"vivi": _hide_and_recover(mimo)
        &"toto": _charge(mimo, 7.6, 1)
        &"nagi": _updraft_leap(mimo)
        &"pico": _flash_slow(mimo, 3.8, 0.70)
        &"luna": _blink_sideways(mimo)
        &"doro": _mud_splash(mimo)
        &"nix": _hide_and_dash(mimo)
        &"fufu": _echo_split(mimo)
        &"zari": _charge(mimo, 8.2, 1)
        &"ema": _calm_recover(mimo)

func _wind_escape(mimo: MimoBase, action_name: StringName) -> void:
    signature_action.emit(mimo.mimo_id, action_name)
    var player := _player()
    var away := Vector3.FORWARD
    if player != null:
        away = mimo.global_position - player.global_position
        away.y = 0.0
        if away.length_squared() > 0.01:
            away = away.normalized()
    var side := away.rotated(Vector3.UP, PI * 0.45)
    mimo.velocity.x = side.x * mimo.panic_speed * 1.45
    mimo.velocity.z = side.z * mimo.panic_speed * 1.45
    mimo.velocity.y = maxf(mimo.velocity.y, 4.2)
    _spawn_ring(mimo.global_position, Color(0.30, 0.88, 1.0, 0.58), 0.35, 2.2)

func _vortex_burst(mimo: MimoBase) -> void:
    signature_action.emit(mimo.mimo_id, &"decoy_split")
    _spawn_ring(mimo.global_position, Color(1.0, 0.72, 0.24, 0.62), 0.28, 3.0)
    var player := _player()
    if player == null:
        return
    var delta := player.global_position - mimo.global_position
    delta.y = 0.0
    if delta.length() <= 4.2 and delta.length_squared() > 0.01:
        var push := delta.normalized()
        player.velocity.x += push.x * 5.2
        player.velocity.z += push.z * 5.2

func _hide_and_recover(mimo: MimoBase) -> void:
    signature_action.emit(mimo.mimo_id, &"grass_hide")
    mimo.set_meta("scan_hidden", true)
    mimo.stamina = minf(mimo.stamina_max, mimo.stamina + 14.0)
    var visual := mimo.get_node_or_null("Visual") as Node3D
    if visual != null:
        var tween := create_tween()
        tween.tween_property(visual, "scale", Vector3(0.68, 0.44, 0.68), 0.14)
        tween.tween_interval(0.55)
        tween.tween_property(visual, "scale", Vector3.ONE, 0.18)
    _restore_scan(mimo, 0.86)

func _charge(mimo: MimoBase, distance: float, damage: int) -> void:
    signature_action.emit(mimo.mimo_id, &"counter_charge")
    var player := _player()
    if player == null:
        return
    var direction := player.global_position - mimo.global_position
    direction.y = 0.0
    if direction.length_squared() <= 0.01:
        return
    direction = direction.normalized()
    mimo.velocity.x = direction.x * mimo.panic_speed * 1.85
    mimo.velocity.z = direction.z * mimo.panic_speed * 1.85
    var start := mimo.global_position
    var finish := start + direction * distance
    _spawn_lane(start, finish, mimo.accent_color)
    _resolve_charge(player, start, finish, damage)

func _resolve_charge(player: PlayerController, start: Vector3, finish: Vector3, damage: int) -> void:
    await get_tree().create_timer(0.24).timeout
    if player != null and _distance_point_to_segment_xz(player.global_position, start, finish) <= 1.45:
        player.take_damage(damage, finish - start)

func _updraft_leap(mimo: MimoBase) -> void:
    signature_action.emit(mimo.mimo_id, &"spark_burst")
    mimo.velocity.y = maxf(mimo.velocity.y, 6.8)
    mimo.stamina = minf(mimo.stamina_max, mimo.stamina + 7.0)
    _spawn_ring(mimo.global_position, Color(0.66, 0.52, 1.0, 0.62), 0.30, 2.5)

func _flash_slow(mimo: MimoBase, radius: float, slow_value: float) -> void:
    signature_action.emit(mimo.mimo_id, &"spark_burst")
    _spawn_ring(mimo.global_position, mimo.accent_color, 0.26, radius * 0.72)
    var player := _player()
    if player != null and player.global_position.distance_to(mimo.global_position) <= radius:
        player.apply_slow(slow_value, 0.95)

func _blink_sideways(mimo: MimoBase) -> void:
    signature_action.emit(mimo.mimo_id, &"decoy_split")
    var before := mimo.global_position
    var player := _player()
    var direction := Vector3.RIGHT
    if player != null:
        var away := mimo.global_position - player.global_position
        away.y = 0.0
        if away.length_squared() > 0.01:
            direction = away.normalized().rotated(Vector3.UP, PI * 0.5)
    var sign_value := -1.0 if (abs(hash(String(mimo.mimo_id))) + Time.get_ticks_msec()) % 2 == 0 else 1.0
    mimo.global_position += direction * sign_value * 4.2
    _spawn_ring(before, Color(0.64, 0.42, 1.0, 0.66), 0.24, 1.8)
    _spawn_ring(mimo.global_position, Color(0.64, 0.42, 1.0, 0.66), 0.24, 1.8)

func _mud_splash(mimo: MimoBase) -> void:
    signature_action.emit(mimo.mimo_id, &"sleep_cloud")
    _spawn_ring(mimo.global_position, Color(0.42, 0.82, 0.34, 0.56), 0.32, 3.2)
    var player := _player()
    if player != null and player.global_position.distance_to(mimo.global_position) <= 4.0:
        player.apply_slow(0.52, 1.6)

func _hide_and_dash(mimo: MimoBase) -> void:
    signature_action.emit(mimo.mimo_id, &"grass_hide")
    mimo.set_meta("scan_hidden", true)
    var player := _player()
    if player != null:
        var away := mimo.global_position - player.global_position
        away.y = 0.0
        if away.length_squared() > 0.01:
            away = away.normalized()
            mimo.velocity.x = away.x * mimo.panic_speed * 1.55
            mimo.velocity.z = away.z * mimo.panic_speed * 1.55
    _restore_scan(mimo, 0.74)

func _echo_split(mimo: MimoBase) -> void:
    signature_action.emit(mimo.mimo_id, &"decoy_split")
    for side in [-1.0, 1.0]:
        var echo := MeshInstance3D.new()
        echo.name = "FufuEcho"
        var mesh := SphereMesh.new()
        mesh.radius = 0.48
        mesh.height = 0.96
        mesh.radial_segments = 8
        mesh.rings = 4
        echo.mesh = mesh
        echo.global_position = mimo.global_position + Vector3(side * 2.0, 0.45, 0.0)
        var mat := StandardMaterial3D.new()
        mat.albedo_color = Color(mimo.accent_color.r, mimo.accent_color.g, mimo.accent_color.b, 0.42)
        mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        mat.emission_enabled = true
        mat.emission = mimo.accent_color
        mat.emission_energy_multiplier = 1.4
        echo.material_override = mat
        _stage.add_child(echo)
        var tween := create_tween()
        tween.tween_property(echo, "scale", Vector3.ONE * 1.22, 0.35)
        tween.tween_interval(0.65)
        tween.tween_property(echo, "scale", Vector3.ZERO, 0.18)
        tween.tween_callback(echo.queue_free)

func _calm_recover(mimo: MimoBase) -> void:
    signature_action.emit(mimo.mimo_id, &"sleep_cloud")
    mimo.stamina = minf(mimo.stamina_max, mimo.stamina + 18.0)
    mimo.velocity.x *= 0.45
    mimo.velocity.z *= 0.45
    _spawn_ring(mimo.global_position, Color(1.0, 0.86, 0.34, 0.52), 0.24, 2.0)

func _restore_scan(mimo: MimoBase, delay: float) -> void:
    await get_tree().create_timer(delay).timeout
    if is_instance_valid(mimo):
        mimo.set_meta("scan_hidden", false)

func _player() -> PlayerController:
    return get_tree().get_first_node_in_group("player") as PlayerController

func _spawn_ring(origin: Vector3, color: Color, start_scale: float, end_scale: float) -> void:
    if not is_instance_valid(_stage):
        return
    var ring := MeshInstance3D.new()
    ring.name = "MissionSignatureRing"
    var mesh := TorusMesh.new()
    mesh.inner_radius = 0.82
    mesh.outer_radius = 0.96
    mesh.rings = 18
    mesh.ring_segments = 7
    ring.mesh = mesh
    ring.global_position = origin + Vector3.UP * 0.16
    ring.rotation_degrees.x = 90.0
    ring.scale = Vector3.ONE * start_scale
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.emission_enabled = true
    mat.emission = Color(color.r, color.g, color.b, 1.0)
    mat.emission_energy_multiplier = 1.8
    ring.material_override = mat
    ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    _stage.add_child(ring)
    var tween := create_tween()
    tween.tween_property(ring, "scale", Vector3.ONE * end_scale, 0.38)
    tween.tween_interval(0.08)
    tween.tween_callback(ring.queue_free)

func _spawn_lane(start: Vector3, finish: Vector3, color: Color) -> void:
    if not is_instance_valid(_stage):
        return
    var lane := MeshInstance3D.new()
    lane.name = "ChargeLane"
    var mesh := BoxMesh.new()
    var length := start.distance_to(finish)
    mesh.size = Vector3(0.20, 0.035, length)
    lane.mesh = mesh
    lane.global_position = (start + finish) * 0.5 + Vector3.UP * 0.06
    lane.look_at(finish, Vector3.UP)
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(color.r, color.g, color.b, 0.46)
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.emission_enabled = true
    mat.emission = color
    mat.emission_energy_multiplier = 1.5
    lane.material_override = mat
    lane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    _stage.add_child(lane)
    var tween := create_tween()
    tween.tween_interval(0.42)
    tween.tween_callback(lane.queue_free)

func _distance_point_to_segment_xz(point: Vector3, a: Vector3, b: Vector3) -> float:
    var p := Vector2(point.x, point.z)
    var av := Vector2(a.x, a.z)
    var bv := Vector2(b.x, b.z)
    var ab := bv - av
    if ab.length_squared() <= 0.0001:
        return p.distance_to(av)
    var t := clampf((p - av).dot(ab) / ab.length_squared(), 0.0, 1.0)
    return p.distance_to(av + ab * t)
