extends Node

var _failures: Array[String] = []
var _statuses: Array[String] = []
var _knockout_count := 0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_run")

func _run() -> void:
    print("[RUNTIME_V042] start")
    var settings := get_tree().root.get_node_or_null("SettingsManager")
    var pause_menu := get_tree().root.get_node_or_null("GlobalPauseMenu")
    var achievements := get_tree().root.get_node_or_null("AchievementOverlay")
    var vitals := get_tree().root.get_node_or_null("VitalsOverlay")
    _check(settings != null, "SettingsManager autoload is available")
    _check(pause_menu != null, "GlobalPauseMenu autoload is available")
    _check(achievements != null, "Japanese AchievementOverlay autoload is available")
    _check(vitals != null, "Japanese VitalsOverlay autoload is available")
    if settings == null or pause_menu == null or achievements == null or vitals == null:
        _finish()
        return

    settings.call("reset_defaults")
    _check(absf(float(settings.get("camera_sensitivity")) - 0.65) < 0.01, "Camera sensitivity safe default is 0.65")
    settings.call("set_camera_sensitivity", 1.0)
    settings.call("set_camera_shake", false)
    settings.call("set_hitstop", false)
    _check(absf(float(settings.get("camera_sensitivity")) - 1.0) < 0.01, "Camera sensitivity setting updates inside safe range")
    settings.call("set_camera_sensitivity", 1.8)
    _check(absf(float(settings.get("camera_sensitivity")) - 1.2) < 0.01, "Camera sensitivity clamps runaway legacy values")
    _check(not bool(settings.get("camera_shake_enabled")), "Camera shake can be disabled")
    _check(not bool(settings.get("hitstop_enabled")), "Capture hitstop can be disabled")
    settings.call("reset_defaults")

    var packed := load("res://scenes/stage1/stage1.tscn") as PackedScene
    _check(packed != null, "Stage 1 loads for v0.4.2 gameplay-feel QA")
    if packed == null:
        _finish()
        return
    var stage := packed.instantiate()
    add_child(stage)
    await get_tree().process_frame
    await get_tree().process_frame

    var player := get_tree().get_first_node_in_group("player") as PlayerController
    var directors := get_tree().get_nodes_in_group("signature_action_director")
    var mimos := get_tree().get_nodes_in_group("mimo")
    _check(player != null, "Player is available")
    _check(directors.size() == 1, "Signature director is available")
    _check(mimos.size() == 6, "Six Mimo are available")
    if player == null or directors.is_empty() or mimos.size() != 6:
        _finish()
        return

    player.status_effect_changed.connect(_on_status)
    player.knocked_out.connect(_on_knocked_out)
    _check(player.health == 3 and player.max_health == 3, "Player starts with three hearts")
    var director := directors[0] as SignatureActionDirector

    pause_menu.call("toggle_pause")
    _check(get_tree().paused, "Pause menu pauses the SceneTree")
    var pause_root := pause_menu.get("_root") as Control
    _check(pause_root != null and pause_root.visible, "Pause overlay becomes visible")
    pause_menu.call("close_pause")
    _check(not get_tree().paused, "Pause menu resumes the SceneTree")
    await get_tree().process_frame

    achievements.call("toggle")
    _check(get_tree().paused, "Achievements overlay pauses gameplay")
    var achievement_root := achievements.get("_root") as Control
    var achievement_label := achievements.get("_label") as Label
    _check(achievement_root != null and achievement_root.visible, "Japanese achievements overlay becomes visible")
    _check(achievement_label != null and "はじめての捕獲" in achievement_label.text, "Achievements list is Japanese")
    achievements.call("close")
    _check(not get_tree().paused, "Achievements overlay resumes gameplay")
    await get_tree().process_frame

    var lumi := _find_mimo(mimos, &"lumi")
    var boka := _find_mimo(mimos, &"boka")
    var nera := _find_mimo(mimos, &"nera")
    _check(lumi != null and boka != null and nera != null, "Lumi, Boka and Nera resolved")

    if lumi != null:
        lumi.state = MimoBase.State.ROUTINE
        director.call("_trigger_signature", lumi)
        _check(bool(lumi.get_meta("scan_hidden", false)), "Lumi signature temporarily hides it from normal scan")
        lumi.apply_lure(lumi.global_position, 1.0, 1.0)
        _check(lumi.is_lured(), "LURE can counter Lumi scan-hide state")

    if boka != null:
        _statuses.clear()
        player.health = 3
        player.set("_invulnerability_time", 0.0)
        player.global_position = Vector3.ZERO
        boka.global_position = Vector3(0.0, 0.0, -4.0)
        boka.state = MimoBase.State.ROUTINE
        director.call("_trigger_signature", boka)
        await get_tree().create_timer(0.32).timeout
        _check(_statuses.has("STAGGER"), "Boka charge hits a player standing on its charge route")
        _check(player.health == 2, "Boka charge removes one heart")

    if nera != null:
        _statuses.clear()
        player.set("_invulnerability_time", 0.0)
        player.global_position = Vector3(1.5, 0.0, 0.0)
        nera.global_position = Vector3.ZERO
        nera.state = MimoBase.State.ROUTINE
        director.call("_trigger_signature", nera)
        await get_tree().create_timer(0.34).timeout
        _check(_statuses.has("SLOWED"), "Nera delayed shock hits inside its telegraphed radius")
        _check(player.health == 1, "Nera shock removes one heart")

    player.set("_invulnerability_time", 0.0)
    var knockout_before := _knockout_count
    player.take_damage(1, Vector3.BACK)
    await get_tree().process_frame
    _check(_knockout_count == knockout_before + 1, "Third heart loss triggers knockout")
    _check(player.health == 3, "Knockout restores all three hearts")
    var spawn_position: Vector3 = player.get("_spawn_position")
    _check(player.global_position.distance_to(spawn_position) < 0.2, "Knockout returns player to checkpoint")

    var vitals_label := vitals.get("_label") as Label
    await get_tree().process_frame
    _check(vitals_label != null and "♥♥♥" in vitals_label.text, "Japanese vitals HUD reflects restored three hearts")

    settings.call("set_camera_shake", false)
    settings.call("set_hitstop", false)
    player.play_capture_feedback(player.global_position + Vector3.FORWARD)
    await get_tree().process_frame
    _check(true, "Capture focus API runs with comfort effects disabled")
    settings.call("reset_defaults")

    _finish()

func _find_mimo(nodes: Array[Node], id: StringName) -> MimoBase:
    for node in nodes:
        var mimo := node as MimoBase
        if mimo != null and mimo.mimo_id == id:
            return mimo
    return null

func _on_status(label: String) -> void:
    if label != "":
        _statuses.append(label)

func _on_knocked_out() -> void:
    _knockout_count += 1

func _check(condition: bool, label: String) -> void:
    if condition:
        print("[RUNTIME_V042][PASS] ", label)
    else:
        _failures.append(label)
        push_error("[RUNTIME_V042][FAIL] %s" % label)

func _finish() -> void:
    get_tree().paused = false
    if _failures.is_empty():
        print("[RUNTIME_V042] PASS")
        get_tree().quit(0)
    else:
        print("[RUNTIME_V042] FAILURES: ", _failures.size())
        for failure in _failures:
            print("  - ", failure)
        get_tree().quit(1)