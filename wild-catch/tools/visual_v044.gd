extends Node

const OUT_DIR := "res://build/screenshots"

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_run")

func _run() -> void:
    var absolute_dir := ProjectSettings.globalize_path(OUT_DIR)
    var err := DirAccess.make_dir_recursive_absolute(absolute_dir)
    if err != OK and err != ERR_ALREADY_EXISTS:
        push_error("[VISUAL_V044] cannot create screenshot directory")
        get_tree().quit(1)
        return

    var title_pack := load("res://scenes/ui/title_screen.tscn") as PackedScene
    if title_pack == null:
        push_error("[VISUAL_V044] title scene failed to load")
        get_tree().quit(1)
        return
    var title := title_pack.instantiate()
    add_child(title)
    await _wait_frames(8)
    await _save_viewport("21_title_ui.png")
    title.queue_free()
    await _wait_frames(3)

    var stage_pack := load("res://scenes/stage1/stage1.tscn") as PackedScene
    if stage_pack == null:
        push_error("[VISUAL_V044] Stage 1 failed to load")
        get_tree().quit(1)
        return
    var stage := stage_pack.instantiate()
    add_child(stage)
    await _wait_frames(10)
    await _save_viewport("22_gameplay_ui.png")

    var player := get_tree().get_first_node_in_group("player") as PlayerController
    var drone := get_tree().get_first_node_in_group("scout_drone") as ScoutDrone
    var mimos := get_tree().get_nodes_in_group("mimo")
    if player == null or drone == null or mimos.is_empty():
        push_error("[VISUAL_V044] gameplay nodes missing")
        get_tree().quit(1)
        return
    var mimo := mimos[0] as MimoBase
    mimo.global_position = player.global_position + Vector3(2.3, 0.0, -3.2)
    drone.launch(player)
    await _wait_frames(5)
    await _save_viewport("23_drone_world_markers.png")

    var pause_menu := get_tree().root.get_node_or_null("GlobalPauseMenu")
    if pause_menu == null:
        push_error("[VISUAL_V044] pause menu missing")
        get_tree().quit(1)
        return
    pause_menu.call("toggle_pause")
    await _wait_frames(3)
    await _save_viewport("24_pause_ui_polished.png")
    pause_menu.call("close_pause")
    await _wait_frames(2)

    var achievement_overlay := get_tree().root.get_node_or_null("AchievementOverlay")
    if achievement_overlay == null:
        push_error("[VISUAL_V044] AchievementOverlay missing")
        get_tree().quit(1)
        return
    achievement_overlay.call("toggle")
    await _wait_frames(3)
    await _save_viewport("25_achievements_ui_polished.png")
    achievement_overlay.call("close")
    await _wait_frames(2)

    var hud := stage.get_node_or_null("UI/MobileHUD") as MobileHUD
    if hud == null:
        push_error("[VISUAL_V044] MobileHUD missing")
        get_tree().quit(1)
        return
    hud.toggle_field_log()
    await _wait_frames(3)
    await _save_viewport("26_field_log_ui_polished.png")
    hud.toggle_field_log()

    print("[VISUAL_V044] PASS — product UI screenshots saved")
    get_tree().quit(0)

func _wait_frames(count: int) -> void:
    for _i in range(count):
        await get_tree().process_frame

func _save_viewport(file_name: String) -> void:
    await RenderingServer.frame_post_draw
    var image := get_viewport().get_texture().get_image()
    if image == null or image.is_empty():
        push_error("[VISUAL_V044] empty image: %s" % file_name)
        get_tree().quit(1)
        return
    var path := "%s/%s" % [OUT_DIR, file_name]
    var save_err := image.save_png(path)
    if save_err != OK:
        push_error("[VISUAL_V044] save failed: %s" % file_name)
        get_tree().quit(1)
        return
    print("[VISUAL_V044] saved ", ProjectSettings.globalize_path(path))
