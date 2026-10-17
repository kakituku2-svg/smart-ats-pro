extends CharacterBody3D
class_name MimoBase

enum State { ROUTINE, ALERT, PANIC, FATIGUED, RECOVER, CAPTURED }

signal state_changed(mimo: MimoBase, state: State)
signal captured(mimo: MimoBase)

@export var mimo_id: StringName = &"mimo"
@export var display_name := "Mimo"
@export var personality := "curious"
@export var area_name := "Unknown Area"
@export var capture_hint := "Chase it until it tires, then use HEX NET."
@export var accent_color := Color(1.0, 0.45, 0.35, 1.0)
@export var behavior_profile: StringName = &"runner"
@export var move_speed := 2.2
@export var panic_speed := 6.0
@export var detection_distance := 8.0
@export var stamina_max := 100.0
@export var home_radius := 5.0
@export var panic_stamina_drain := 24.0
@export var recover_rate := 18.0
@export var trick_bias := 0.0

@onready var visual: Node3D = $Visual
@onready var body_mesh: MeshInstance3D = $Visual/Body
@onready var halo_mesh: MeshInstance3D = $Visual/Halo
@onready var orb_mesh: MeshInstance3D = $Visual/Orb
@onready var collision: CollisionShape3D = $CollisionShape3D

var state: State = State.ROUTINE
var stamina := 100.0
var _home := Vector3.ZERO
var _wander_target := Vector3.ZERO
var _wander_timer := 0.0
var _alert_timer := 0.0
var _recover_timer := 0.0
var _player: Node3D
var _phase := 0.0
var _orb_material: StandardMaterial3D
var _special_timer := 0.0
var _burst_timer := 0.0
var _escape_flip := 1.0
var _lure_position := Vector3.ZERO
var _lure_time := 0.0
var _stun_time := 0.0
var _route_anchor: Node3D
var _route_refresh := 0.0

func _ready() -> void:
    add_to_group("mimo")
    _home = global_position
    stamina = stamina_max
    _player = get_tree().get_first_node_in_group("player") as Node3D
    _phase = float(abs(hash(String(mimo_id))) % 628) / 100.0
    if behavior_profile == &"runner":
        behavior_profile = _default_behavior_profile()
    _special_timer = 1.0 + randf() * 1.6
    _escape_flip = -1.0 if (abs(hash(String(mimo_id))) % 2) == 0 else 1.0
    _pick_wander_target()
    _apply_accent_material()

func _physics_process(delta: float) -> void:
    if state == State.CAPTURED:
        return
    if not is_instance_valid(_player):
        _player = get_tree().get_first_node_in_group("player") as Node3D
        if not is_instance_valid(_player):
            return

    _lure_time = maxf(0.0, _lure_time - delta)
    _stun_time = maxf(0.0, _stun_time - delta)
    _route_refresh = maxf(0.0, _route_refresh - delta)
    var to_player := _player.global_position - global_position
    var player_distance := to_player.length()

    if _stun_time > 0.0:
        _stunned_tick(delta)
    elif _lure_time > 0.0 and state in [State.ROUTINE, State.ALERT, State.RECOVER]:
        _lure_tick(delta, player_distance)
    else:
        match state:
            State.ROUTINE:
                _routine_tick(delta, player_distance)
            State.ALERT:
                _alert_tick(delta, player_distance)
            State.PANIC:
                _panic_tick(delta, to_player, player_distance)
            State.FATIGUED:
                _fatigued_tick(delta, player_distance)
            State.RECOVER:
                _recover_tick(delta, player_distance)

    if not is_on_floor():
        velocity.y -= float(ProjectSettings.get_setting("physics/3d/default_gravity")) * delta
    move_and_slide()
    _face_velocity(delta)
    _update_visual_feedback(delta)

func _routine_tick(delta: float, player_distance: float) -> void:
    stamina = minf(stamina_max, stamina + recover_rate * 0.5 * delta)
    if player_distance <= detection_distance:
        _alert_timer = 0.35
        set_state(State.ALERT)
        return
    _wander_timer -= delta
    if _wander_timer <= 0.0 or global_position.distance_to(_wander_target) < 0.8:
        _pick_wander_target()
    var desired := _flat_direction_to(_wander_target) * move_speed
    velocity.x = move_toward(velocity.x, desired.x, 8.0 * delta)
    velocity.z = move_toward(velocity.z, desired.z, 8.0 * delta)

func _lure_tick(delta: float, player_distance: float) -> void:
    if player_distance <= detection_distance * 0.62:
        _lure_time = 0.0
        _alert_timer = 0.22
        set_state(State.ALERT)
        return
    var to_lure := _lure_position - global_position
    to_lure.y = 0.0
    var distance := to_lure.length()
    if distance <= 0.75:
        velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)
        stamina = minf(stamina_max, stamina + recover_rate * 0.18 * delta)
        return
    var direction := to_lure.normalized()
    var attraction_speed := move_speed * (1.25 if behavior_profile in [&"sleepy", &"timid"] else 1.0)
    velocity.x = move_toward(velocity.x, direction.x * attraction_speed, 10.0 * delta)
    velocity.z = move_toward(velocity.z, direction.z * attraction_speed, 10.0 * delta)

func _stunned_tick(delta: float) -> void:
    velocity.x = move_toward(velocity.x, 0.0, 24.0 * delta)
    velocity.z = move_toward(velocity.z, 0.0, 24.0 * delta)

func _alert_tick(delta: float, player_distance: float) -> void:
    velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
    velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)
    _alert_timer -= delta
    if player_distance > detection_distance * 1.35:
        set_state(State.ROUTINE)
    elif _alert_timer <= 0.0:
        set_state(State.PANIC)

func _panic_tick(delta: float, to_player: Vector3, player_distance: float) -> void:
    stamina = maxf(0.0, stamina - panic_stamina_drain * delta)
    _special_timer = maxf(0.0, _special_timer - delta)
    _burst_timer = maxf(0.0, _burst_timer - delta)
    if stamina <= 0.0:
        _recover_timer = 2.7
        set_state(State.FATIGUED)
        return

    var away := -to_player
    away.y = 0.0
    if away.length_squared() < 0.01:
        away = Vector3.FORWARD
    away = away.normalized()
    var perpendicular := Vector3(-away.z, 0.0, away.x)
    var side := perpendicular * sin(Time.get_ticks_msec() * 0.0025 + _phase) * (0.35 + trick_bias)
    var desired_dir := (away + side).normalized()
    var home_pull := _flat_direction_to(_home) * clampf(global_position.distance_to(_home) / maxf(home_radius, 0.1), 0.0, 1.0)
    desired_dir = (desired_dir + home_pull * 0.45).normalized()
    desired_dir = _profile_escape_direction(desired_dir, away, perpendicular, player_distance)
    var route_dir := _escape_route_direction()
    if route_dir != Vector3.ZERO:
        var route_weight := 0.48 if behavior_profile in [&"sentinel", &"trickster", &"timid"] else 0.34
        desired_dir = (desired_dir + route_dir * route_weight).normalized()
    var speed_scale := _profile_speed_scale(player_distance)
    velocity.x = desired_dir.x * panic_speed * speed_scale
    velocity.z = desired_dir.z * panic_speed * speed_scale

    if player_distance > detection_distance * 2.2 and stamina > stamina_max * 0.35:
        set_state(State.RECOVER)

func _escape_route_direction() -> Vector3:
    if _route_refresh <= 0.0 or not is_instance_valid(_route_anchor) or global_position.distance_to(_route_anchor.global_position) < 1.2:
        _route_refresh = 0.75 + randf() * 0.55
        _route_anchor = _choose_escape_anchor()
    if not is_instance_valid(_route_anchor):
        return Vector3.ZERO
    return _flat_direction_to(_route_anchor.global_position)

func _choose_escape_anchor() -> Node3D:
    if not is_instance_valid(_player):
        return null
    var best: Node3D
    var best_score := -INF
    for node in get_tree().get_nodes_in_group("mimo_escape_anchor"):
        var anchor := node as Node3D
        if anchor == null:
            continue
        if StringName(anchor.get_meta("target_mimo", &"")) != mimo_id:
            continue
        var player_distance := anchor.global_position.distance_to(_player.global_position)
        var self_distance := anchor.global_position.distance_to(global_position)
        var score := player_distance - self_distance * 0.38 + randf() * 0.45
        if score > best_score:
            best_score = score
            best = anchor
    return best

func _profile_escape_direction(base_dir: Vector3, away: Vector3, perpendicular: Vector3, player_distance: float) -> Vector3:
    var t := Time.get_ticks_msec() * 0.001 + _phase
    match behavior_profile:
        &"timid":
            return (base_dir + away * 0.35 + _flat_direction_to(_home) * 0.35).normalized()
        &"zigzag":
            return (away + perpendicular * sin(t * 7.5) * 0.92).normalized()
        &"challenger":
            if player_distance < 4.4:
                var side_sign := 1.0 if sin(t * 5.0) >= 0.0 else -1.0
                return (away * 0.38 + perpendicular * side_sign * 1.18).normalized()
        &"sentinel":
            if _special_timer <= 0.0:
                _special_timer = 2.8
                _burst_timer = 0.52
                _escape_flip *= -1.0
            if _burst_timer > 0.0:
                return (away + perpendicular * _escape_flip * 0.72).normalized()
        &"sleepy":
            return (base_dir + away * 0.20).normalized()
        &"trickster":
            if _special_timer <= 0.0:
                _special_timer = 1.65
                _burst_timer = 0.38
                _escape_flip *= -1.0
            if _burst_timer > 0.0:
                return (away * 0.22 + perpendicular * _escape_flip * 1.30).normalized()
            return (base_dir + perpendicular * sin(t * 10.5) * 0.48).normalized()
    return base_dir

func _profile_speed_scale(player_distance: float) -> float:
    match behavior_profile:
        &"timid":
            return 1.06
        &"zigzag":
            return 0.98
        &"challenger":
            return 1.12 if player_distance < 4.4 else 1.0
        &"sentinel":
            return 1.34 if _burst_timer > 0.0 else 1.0
        &"sleepy":
            return 0.72 + get_pressure() * 0.28
        &"trickster":
            return 1.24 if _burst_timer > 0.0 else 1.02
    return 1.0

func _default_behavior_profile() -> StringName:
    match mimo_id:
        &"lumi":
            return &"timid"
        &"goro":
            return &"zigzag"
        &"boka":
            return &"challenger"
        &"nera":
            return &"sentinel"
        &"moku":
            return &"sleepy"
        &"raku":
            return &"trickster"
    return &"runner"

func _fatigued_tick(delta: float, player_distance: float) -> void:
    velocity.x = move_toward(velocity.x, 0.0, 14.0 * delta)
    velocity.z = move_toward(velocity.z, 0.0, 14.0 * delta)
    _recover_timer -= delta
    if player_distance > 4.5 and _recover_timer <= 0.0:
        set_state(State.RECOVER)

func _recover_tick(delta: float, player_distance: float) -> void:
    stamina = minf(stamina_max, stamina + recover_rate * delta)
    velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta)
    velocity.z = move_toward(velocity.z, 0.0, 8.0 * delta)
    if player_distance <= detection_distance * 0.75 and stamina > stamina_max * 0.25:
        set_state(State.PANIC)
    elif stamina >= stamina_max * 0.70:
        set_state(State.ROUTINE)

func set_state(next_state: State) -> void:
    if state == State.CAPTURED or state == next_state:
        return
    state = next_state
    if state == State.PANIC and _special_timer <= 0.0:
        _special_timer = 0.6 + randf() * 0.8
    if state != State.PANIC:
        _route_anchor = null
    state_changed.emit(self, state)

func apply_lure(target_position: Vector3, duration: float) -> bool:
    if state in [State.CAPTURED, State.FATIGUED]:
        return false
    if state == State.PANIC and get_pressure() < 0.45:
        return false
    _lure_position = target_position
    _lure_time = maxf(_lure_time, duration)
    if state == State.PANIC:
        set_state(State.RECOVER)
    return true

func apply_pulse(_origin: Vector3, damage: float, stun_seconds: float) -> bool:
    if state == State.CAPTURED:
        return false
    _lure_time = 0.0
    stamina = maxf(0.0, stamina - maxf(damage, 0.0))
    _stun_time = maxf(_stun_time, stun_seconds)
    if stamina <= 0.0:
        _recover_timer = 2.7
        set_state(State.FATIGUED)
    elif state != State.FATIGUED:
        _alert_timer = maxf(_alert_timer, stun_seconds * 0.6)
        set_state(State.ALERT)
    return true

func is_lured() -> bool:
    return _lure_time > 0.0

func is_stunned() -> bool:
    return _stun_time > 0.0

func attempt_capture(net_step: int, hunter: Node3D) -> bool:
    if state == State.CAPTURED or not is_instance_valid(hunter):
        return false
    var distance := global_position.distance_to(hunter.global_position)
    var guaranteed := state == State.FATIGUED or (_stun_time > 0.0 and distance <= 2.3) or distance <= 1.35 or (net_step == 3 and distance <= 2.05)
    if guaranteed:
        capture()
        return true
    stamina = maxf(0.0, stamina - (24.0 if net_step == 3 else 14.0))
    set_state(State.PANIC)
    if stamina <= 0.0:
        _recover_timer = 2.7
        set_state(State.FATIGUED)
    return false

func capture() -> void:
    if state == State.CAPTURED:
        return
    state = State.CAPTURED
    velocity = Vector3.ZERO
    _lure_time = 0.0
    _stun_time = 0.0
    _route_anchor = null
    collision.set_deferred("disabled", true)
    GameState.mark_captured(mimo_id)
    captured.emit(self)
    var tween := create_tween()
    tween.tween_property(visual, "scale", Vector3.ONE * 1.25, 0.10)
    tween.tween_property(visual, "scale", Vector3.ZERO, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
    tween.tween_callback(func() -> void: visible = false)

func is_capture_ready() -> bool:
    return state == State.FATIGUED

func get_pressure() -> float:
    return clampf(1.0 - stamina / maxf(stamina_max, 1.0), 0.0, 1.0)

func get_capture_status() -> String:
    if state == State.FATIGUED:
        return "READY — HEX NET NOW"
    if _stun_time > 0.0:
        return "STUNNED — CLOSE IN"
    if _lure_time > 0.0:
        return "LURED — SET UP AN AMBUSH"
    var stamina_ratio := stamina / maxf(stamina_max, 1.0)
    if state == State.PANIC and stamina_ratio <= 0.35:
        return "NEARLY TIRED"
    if state == State.PANIC:
        return "CHASE"
    if state == State.ALERT:
        return "SPOTTED YOU"
    if state == State.RECOVER:
        return "RECOVERING"
    return "TRACK"

func get_route_hint() -> String:
    if is_instance_valid(_route_anchor):
        return String(_route_anchor.get_meta("anchor_kind", "dynamic"))
    return "dynamic"

func get_scan_payload(observer_position: Vector3) -> Dictionary:
    var delta := global_position - observer_position
    var direction_label := _direction_label(delta)
    return {
        "id": String(mimo_id),
        "name": display_name,
        "distance": delta.length(),
        "direction": direction_label,
        "area": area_name,
        "personality": personality,
        "behavior": String(behavior_profile),
        "route": get_route_hint(),
        "state": State.keys()[state],
        "stamina": stamina / maxf(stamina_max, 1.0),
        "pressure": get_pressure(),
        "capture_ready": is_capture_ready(),
        "capture_status": get_capture_status(),
        "lured": is_lured(),
        "stunned": is_stunned(),
        "hint": capture_hint,
    }

func _pick_wander_target() -> void:
    _wander_timer = 1.5 + randf() * 2.4
    var angle := randf() * TAU
    var radius := randf_range(home_radius * 0.25, home_radius)
    _wander_target = _home + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)

func _flat_direction_to(target: Vector3) -> Vector3:
    var delta := target - global_position
    delta.y = 0.0
    return delta.normalized() if delta.length_squared() > 0.001 else Vector3.ZERO

func _face_velocity(delta: float) -> void:
    var planar := Vector3(velocity.x, 0.0, velocity.z)
    if planar.length_squared() <= 0.05:
        return
    var target_yaw := atan2(-planar.x, -planar.z)
    rotation.y = lerp_angle(rotation.y, target_yaw, clampf(7.0 * delta, 0.0, 1.0))

func _apply_accent_material() -> void:
    var material := StandardMaterial3D.new()
    material.albedo_color = accent_color.darkened(0.35)
    material.roughness = 0.85
    body_mesh.material_override = material
    _orb_material = StandardMaterial3D.new()
    _orb_material.albedo_color = accent_color
    _orb_material.emission_enabled = true
    _orb_material.emission = accent_color
    _orb_material.emission_energy_multiplier = 1.5
    orb_mesh.material_override = _orb_material

func _update_visual_feedback(delta: float) -> void:
    if not is_instance_valid(visual) or not is_instance_valid(halo_mesh) or _orb_material == null:
        return
    var now := Time.get_ticks_msec() * 0.001 + _phase
    var pulse_amp := 0.025
    var pulse_speed := 2.5
    var state_color := accent_color
    var scale_base := 1.0
    if _stun_time > 0.0:
        state_color = Color(0.20, 0.78, 1.0, 1.0)
        pulse_amp = 0.09
        pulse_speed = 13.0
    elif _lure_time > 0.0:
        state_color = Color(0.58, 1.0, 0.38, 1.0)
        pulse_amp = 0.06
        pulse_speed = 4.8
    else:
        match state:
            State.ALERT:
                state_color = Color(1.0, 0.72, 0.16, 1.0)
                pulse_amp = 0.055
                pulse_speed = 6.0
            State.PANIC:
                state_color = Color(1.0, 0.16, 0.12, 1.0)
                pulse_amp = 0.075
                pulse_speed = 8.5
            State.FATIGUED:
                state_color = Color(0.25, 1.0, 0.46, 1.0)
                pulse_amp = 0.11
                pulse_speed = 5.0
                scale_base = 0.90
            State.RECOVER:
                state_color = Color(0.25, 0.72, 1.0, 1.0)
                pulse_amp = 0.04
                pulse_speed = 3.5
    var pulse := scale_base * (1.0 + sin(now * pulse_speed) * pulse_amp)
    visual.scale = visual.scale.lerp(Vector3.ONE * pulse, clampf(delta * 8.0, 0.0, 1.0))
    halo_mesh.rotation.y += delta * (2.6 if state == State.PANIC else 1.25)
    _orb_material.albedo_color = state_color
    _orb_material.emission = state_color
    _orb_material.emission_energy_multiplier = 3.0 if state == State.FATIGUED else (2.4 if _stun_time > 0.0 else 1.7)

func _direction_label(delta: Vector3) -> String:
    if absf(delta.x) > absf(delta.z):
        return "E" if delta.x > 0.0 else "W"
    return "S" if delta.z > 0.0 else "N"
