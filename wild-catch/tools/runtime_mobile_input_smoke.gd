extends Node

var _failures: Array[String] = []

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_run")

func _run() -> void:
    print("[MOBILE_INPUT] start")

    SettingsManager.reset_defaults()
    _check(absf(SettingsManager.camera_sensitivity - 0.65) < 0.01, "safe camera sensitivity default is 0.65")
    SettingsManager.set_camera_sensitivity(1.8)
    _check(absf(SettingsManager.camera_sensitivity - 1.20) < 0.01, "legacy/high sensitivity values clamp at 1.20")
    SettingsManager.reset_defaults()

    var stick := VirtualStick.new()
    stick.size = Vector2(180, 180)
    stick.position = Vector2(34, 506)
    add_child(stick)
    await get_tree().process_frame
    stick.call("_set_from_input_position", Vector2(124, 596), false)
    _check(stick.value.length() < 0.02, "absolute screen coordinate maps to joystick center")
    stick.call("_set_from_input_position", Vector2(124, 520), false)
    _check(stick.value.y < -0.45 and absf(stick.value.x) < 0.12, "absolute screen coordinate produces forward joystick input")
    stick.clear_input()
    _check(stick.value == Vector2.ZERO, "joystick release clears movement")
    stick.queue_free()

    var packed := load("res://scenes/stage1/stage1.tscn") as PackedScene
    _check(packed != null, "Stage 1 loads for mobile input smoke")
    if packed == null:
        _finish()
        return
    var stage := packed.instantiate()
    add_child(stage)
    await get_tree().process_frame
    await get_tree().physics_frame

    var player := get_tree().get_first_node_in_group("player") as PlayerController
    _check(player != null, "player resolves for mobile input smoke")
    if player == null:
        _finish()
        return

    var start := player.global_position
    player.set_touch_move_vector(Vector2(0.0, -1.0))
    for _i in range(12):
        await get_tree().physics_frame
    player.set_touch_move_vector(Vector2.ZERO)
    var horizontal_distance := Vector2(player.global_position.x - start.x, player.global_position.z - start.z).length()
    _check(horizontal_distance > 0.35, "touch joystick moves the player a meaningful distance")

    var pivot := player.get_node("CameraPivot") as Node3D
    var yaw_before := pivot.rotation.y
    player.add_camera_look_delta(Vector2(5000.0, 0.0))
    player.call("_apply_camera_look")
    var yaw_delta := absf(wrapf(pivot.rotation.y - yaw_before, -PI, PI))
    _check(yaw_delta > deg_to_rad(0.5), "large drag still rotates the camera")
    _check(yaw_delta <= deg_to_rad(7.1), "single-frame camera rotation is hard-capped against spin")

    var pitch_before := float(player.get("_pitch"))
    player.add_camera_look_delta(Vector2(0.0, 5000.0))
    player.call("_apply_camera_look")
    var pitch_after := float(player.get("_pitch"))
    _check(absf(pitch_after - pitch_before) <= deg_to_rad(5.6), "single-frame vertical look is hard-capped")
    _check(pitch_after >= deg_to_rad(-45.1) and pitch_after <= deg_to_rad(18.1), "camera pitch stays inside comfort limits")

    player.clear_transient_input_state()
    var touch_move: Vector2 = player.get("_touch_move")
    var look_delta: Vector2 = player.get("_look_delta")
    _check(touch_move.length() < 0.001, "transient clear removes touch movement")
    _check(look_delta.length() < 0.001, "transient clear removes camera delta")

    _finish()

func _check(condition: bool, label: String) -> void:
    if condition:
        print("[MOBILE_INPUT][PASS] ", label)
    else:
        _failures.append(label)
        push_error("[MOBILE_INPUT][FAIL] %s" % label)

func _finish() -> void:
    SettingsManager.reset_defaults()
    if _failures.is_empty():
        print("[MOBILE_INPUT] PASS")
        get_tree().quit(0)
    else:
        print("[MOBILE_INPUT] FAILURES: ", _failures.size())
        for failure in _failures:
            print("  - ", failure)
        get_tree().quit(1)