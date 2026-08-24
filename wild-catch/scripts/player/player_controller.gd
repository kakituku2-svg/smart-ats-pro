extends CharacterBody3D
class_name PlayerController

signal status_effect_changed(label: String)
signal health_changed(current: int, maximum: int)
signal knocked_out
signal checkpoint_changed(label: String, world_position: Vector3)

@export var move_speed := 6.2
@export var acceleration := 28.0
@export var air_control := 0.55
@export var jump_velocity := 7.4
@export var dash_speed := 13.5
@export var dash_duration := 0.20
@export var dash_cooldown := 0.45
@export var turn_speed := 12.0
@export var max_health := 3

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D

var health := 3
var _gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
var _air_jumps_left := 1
var _dash_time := 0.0
var _dash_cooldown_left := 0.0
var _touch_move := Vector2.ZERO
var _look_delta := Vector2.ZERO
var _look_sensitivity := 0.0018
var _look_event_limit := 34.0
var _look_frame_limit := 48.0
var _look_deadzone_pixels := 0.35
var _pitch := deg_to_rad(-10.0)
var _slow_multiplier := 1.0
var _slow_time := 0.0
var _stagger_time := 0.0
var _invulnerability_time := 0.0
var _camera_impulse := Vector2.ZERO
var _camera_base_position := Vector3.ZERO
var _capture_feedback_busy := false
var _spawn_position := Vector3.ZERO
var _checkpoint_label := "スタート地点"

func _ready() -> void:
    add_to_group("player")
    camera_pivot.rotation.x = _pitch
    _camera_base_position = camera.position
    _spawn_position = global_position
    health = max_health
    health_changed.emit(health, max_health)

func _physics_process(delta: float) -> void:
    _apply_camera_look()
    _update_status_effects(delta)
    _update_camera_feedback(delta)
    _dash_cooldown_left = maxf(0.0, _dash_cooldown_left - delta)
    _invulnerability_time = maxf(0.0, _invulnerability_time - delta)

    var keyboard := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var input_vec := _touch_move if _touch_move.length_squared() > 0.001 else keyboard
    if input_vec.length_squared() > 1.0:
        input_vec = input_vec.normalized()

    var cam_forward := -camera.global_transform.basis.z
    var cam_right := camera.global_transform.basis.x
    cam_forward.y = 0.0
    cam_right.y = 0.0
    cam_forward = cam_forward.normalized()
    cam_right = cam_right.normalized()
    var direction := cam_right * input_vec.x + cam_forward * -input_vec.y
    if direction.length_squared() > 1.0:
        direction = direction.normalized()

    if is_on_floor():
        _air_jumps_left = 1
    else:
        velocity.y -= _gravity * delta

    if Input.is_action_just_pressed("jump"):
        request_jump()
    if Input.is_action_just_pressed("dash"):
        request_dash()

    if _stagger_time > 0.0:
        direction = Vector3.ZERO

    var target_speed := dash_speed if _dash_time > 0.0 else move_speed
    target_speed *= _slow_multiplier
    _dash_time = maxf(0.0, _dash_time - delta)
    var accel := acceleration if is_on_floor() else acceleration * air_control
    velocity.x = move_toward(velocity.x, direction.x * target_speed, accel * delta)
    velocity.z = move_toward(velocity.z, direction.z * target_speed, accel * delta)

    if direction.length_squared() > 0.02:
        var target_yaw := atan2(-direction.x, -direction.z)
        rotation.y = lerp_angle(rotation.y, target_yaw, clampf(turn_speed * delta, 0.0, 1.0))

    move_and_slide()
    if global_position.y < -8.0:
        _knock_out()

func request_jump() -> void:
    if _stagger_time > 0.0:
        return
    if is_on_floor():
        velocity.y = jump_velocity
    elif _air_jumps_left > 0:
        velocity.y = jump_velocity
        _air_jumps_left -= 1

func request_dash() -> void:
    if _dash_cooldown_left > 0.0 or _stagger_time > 0.0:
        return
    _dash_time = dash_duration
    _dash_cooldown_left = dash_cooldown
    var forward := -global_transform.basis.z
    forward.y = 0.0
    if forward.length_squared() > 0.01:
        forward = forward.normalized()
        velocity.x = forward.x * dash_speed * _slow_multiplier
        velocity.z = forward.z * dash_speed * _slow_multiplier

func set_checkpoint(world_position: Vector3, label: String = "チェックポイント") -> void:
    _spawn_position = world_position
    _checkpoint_label = label
    checkpoint_changed.emit(_checkpoint_label, _spawn_position)

func get_checkpoint_position() -> Vector3:
    return _spawn_position

func get_checkpoint_label() -> String:
    return _checkpoint_label

func take_damage(amount: int = 1, push_direction: Vector3 = Vector3.ZERO) -> bool:
    if amount <= 0 or _invulnerability_time > 0.0:
        return false
    health = maxi(0, health - amount)
    _invulnerability_time = 1.0
    _dash_time = 0.0
    if push_direction.length_squared() > 0.01:
        var push := push_direction.normalized()
        velocity.x += push.x * 4.8
        velocity.z += push.z * 4.8
        velocity.y = maxf(velocity.y, 2.6)
    apply_stagger(0.22, 0.0)
    add_camera_impulse(Vector2(12.0, -7.0))
    health_changed.emit(health, max_health)
    if health <= 0:
        _knock_out()
    return true

func _knock_out() -> void:
    knocked_out.emit()
    velocity = Vector3.ZERO
    global_position = _spawn_position
    health = max_health
    _invulnerability_time = 2.0
    _slow_multiplier = 1.0
    _slow_time = 0.0
    _stagger_time = 0.0
    clear_transient_input_state()
    health_changed.emit(health, max_health)

func apply_slow(multiplier: float, duration: float) -> void:
    _slow_multiplier = minf(_slow_multiplier, clampf(multiplier, 0.25, 1.0))
    _slow_time = maxf(_slow_time, duration)
    status_effect_changed.emit("SLOWED")

func apply_stagger(duration: float, push_strength: float = 0.0) -> void:
    _stagger_time = maxf(_stagger_time, duration)
    _dash_time = 0.0
    if push_strength > 0.0:
        var backward := global_transform.basis.z
        backward.y = 0.0
        if backward.length_squared() > 0.01:
            backward = backward.normalized()
            velocity.x += backward.x * push_strength
            velocity.z += backward.z * push_strength
    status_effect_changed.emit("STAGGER")

func add_camera_impulse(pixels: Vector2) -> void:
    if not SettingsManager.camera_shake_enabled:
        return
    _camera_impulse += pixels

func play_capture_feedback(_target_position: Vector3) -> void:
    if _capture_feedback_busy:
        return
    _capture_feedback_busy = true
    if SettingsManager.camera_shake_enabled:
        add_camera_impulse(Vector2(18.0, -10.0))
    var base_fov := camera.fov
    var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    tween.tween_property(camera, "fov", maxf(48.0, base_fov - 10.0), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.tween_interval(0.10)
    tween.tween_property(camera, "fov", base_fov, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
    tween.tween_callback(func() -> void: _capture_feedback_busy = false)
    if SettingsManager.hitstop_enabled:
        _run_capture_hitstop()

func _run_capture_hitstop() -> void:
    var previous_scale := Engine.time_scale
    Engine.time_scale = 0.16
    await get_tree().create_timer(0.055, true, false, true).timeout
    Engine.time_scale = previous_scale

func set_touch_move_vector(value: Vector2) -> void:
    _touch_move = value.limit_length(1.0)

func add_camera_look_delta(delta_pixels: Vector2) -> void:
    var normalized_delta := _normalize_mobile_look_delta(delta_pixels)
    if normalized_delta.length() <= _look_deadzone_pixels:
        return
    var limited := normalized_delta.limit_length(_look_event_limit)
    _look_delta = (_look_delta + limited).limit_length(_look_frame_limit)

func clear_camera_look_input() -> void:
    _look_delta = Vector2.ZERO

func _normalize_mobile_look_delta(delta_pixels: Vector2) -> Vector2:
    if not OS.has_feature("mobile") and not OS.has_feature("android"):
        return delta_pixels
    var viewport_size := get_viewport().get_visible_rect().size
    var window_size_i := DisplayServer.window_get_size()
    var window_size := Vector2(float(window_size_i.x), float(window_size_i.y))
    if viewport_size.x <= 1.0 or viewport_size.y <= 1.0 or window_size.x <= 1.0 or window_size.y <= 1.0:
        return delta_pixels
    var scale_x := viewport_size.x / window_size.x
    var scale_y := viewport_size.y / window_size.y
    var input_scale := clampf(minf(scale_x, scale_y), 0.35, 1.0)
    return delta_pixels * input_scale

func _apply_camera_look() -> void:
    if _look_delta.length() <= _look_deadzone_pixels:
        _look_delta = Vector2.ZERO
        return
    var sensitivity := _look_sensitivity * SettingsManager.camera_sensitivity
    var yaw_step := clampf(_look_delta.x * sensitivity, deg_to_rad(-7.0), deg_to_rad(7.0))
    var pitch_step := clampf(_look_delta.y * sensitivity, deg_to_rad(-5.5), deg_to_rad(5.5))
    camera_pivot.rotation.y = wrapf(camera_pivot.rotation.y - yaw_step, -PI, PI)
    _pitch = clampf(_pitch - pitch_step, deg_to_rad(-45.0), deg_to_rad(18.0))
    camera_pivot.rotation.x = _pitch
    _look_delta = Vector2.ZERO

func _update_status_effects(delta: float) -> void:
    if _slow_time > 0.0:
        _slow_time = maxf(0.0, _slow_time - delta)
        if _slow_time <= 0.0:
            _slow_multiplier = 1.0
            status_effect_changed.emit("")
    if _stagger_time > 0.0:
        _stagger_time = maxf(0.0, _stagger_time - delta)
        if _stagger_time <= 0.0 and _slow_time <= 0.0:
            status_effect_changed.emit("")

func _update_camera_feedback(delta: float) -> void:
    if not SettingsManager.camera_shake_enabled:
        _camera_impulse = Vector2.ZERO
        camera.position = camera.position.lerp(_camera_base_position, clampf(delta * 14.0, 0.0, 1.0))
        return
    if _camera_impulse.length_squared() > 0.01:
        var shake := Vector3(_camera_impulse.x, _camera_impulse.y, 0.0) * 0.006
        camera.position = _camera_base_position + shake
        _camera_impulse = _camera_impulse.lerp(Vector2.ZERO, clampf(delta * 14.0, 0.0, 1.0))
    else:
        camera.position = camera.position.lerp(_camera_base_position, clampf(delta * 14.0, 0.0, 1.0))

func clear_transient_input_state() -> void:
    _dash_time = 0.0
    _touch_move = Vector2.ZERO
    _look_delta = Vector2.ZERO
    _stagger_time = 0.0

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
        clear_transient_input_state()