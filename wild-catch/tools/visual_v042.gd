extends Node

const OUT_DIR := "res://build/screenshots"

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_run")

func _run() -> void:
    var absolute_dir := ProjectSettings.globalize_path(OUT_DIR)
    var err := DirAccess.make_dir_recursive_absolute(absolute_dir)
    if err != OK and err != ERR_ALREADY_EXISTS:
        push_error("[VISUAL_V042] cannot create screenshot directory")
        get_tree().quit(1)
        return

    var packed := load("res://scenes/stage1/stage1.tscn") as PackedScene
    if packed == null:
        push_error("[VISUAL_V042] Stage 1 failed to load")
        get_tree().quit(1)
        return
    var stage := packed.instantiate()
    add_child(stage)
    await _wait_frames(10)

    var pause_menu := get_tree().root.get_node_or_null("GlobalPauseMenu")
    if pause_menu == null:
        push_error("[VISUAL_V042] GlobalPauseMenu missing")
        get_tree().quit(1)
        return
    pause_menu.call("toggle_pause")
    await _wait_frames(3)
    await _save_viewport("12_pause_settings.png")
    pause_menu.call("close_pause")
    await _wait_frames(3)

    var players := get_tree().get_nodes_in_group("player")
    var mimos := get_tree().get_nodes_in_group("mimo")
    var feedbacks := get_tree().get_nodes_in_group("capture_feedback")
    if players.is_empty() or mimos.is_empty() or feedbacks.is_empty():
        push_error("[VISUAL_V042] gameplay nodes missing")
        get_tree().quit(1)
        return
    var player := players[0] as PlayerController
    var mimo := mimos[0] as MimoBase
    var feedback := feedbacks[0] as CaptureFeedback
    mimo.global_position = player.global_position + Vector3(0.0, 0.0, -2.2)
    SettingsManager.set_hitstop(false)
    feedback.play_capture(mimo.global_position, mimo.accent_color)
    await _wait_frames(2)
    await _save_viewport("13_capture_feedback.png")
    SettingsManager.reset_defaults()

    SaveManager.record_capture(&"lumi")
    SaveManager.record_relic(&"sun_disc")
    var achievement_overlay := get_tree().root.get_node_or_null("AchievementOverlay")
    if achievement_overlay == null:
        push_error("[VISUAL_V042] AchievementOverlay missing")
        get_tree().quit(1)
        return
    achievement_overlay.call("toggle")
    await _wait_frames(3)
    await _save_viewport("14_achievements.png")
    achievement_overlay.call("close")
    await _wait_frames(2)

    player.health = player.max_health
    player.set("_invulnerability_time", 0.0)
    player.take_damage(1, Vector3.RIGHT)
    player.set("_invulnerability_time", 0.0)
    player.take_damage(1, Vector3.LEFT)
    await _wait_frames(3)
    await _save_viewport("15_vitals.png")

    print("[VISUAL_V042] PASS — pause/settings, capture feedback, achievements and vitals saved")
    get_tree().quit(0)

func _wait_frames(count: int) -> void:
    for _i in range(count):
        await get_tree().process_frame

func _save_viewport(file_name: String) -> void:
    await RenderingServer.frame_post_draw
    var image := get_viewport().get_texture().get_image()
    if image == null or image.is_empty():
        push_error("[VISUAL_V042] empty image: %s" % file_name)
        get_tree().quit(1)
        return
    var path := "%s/%s" % [OUT_DIR, file_name]
    var save_err := image.save_png(path)
    if save_err != OK:
        push_error("[VISUAL_V042] save failed: %s" % file_name)
        get_tree().quit(1)
        return
    print("[VISUAL_V042] saved ", ProjectSettings.globalize_path(path))
