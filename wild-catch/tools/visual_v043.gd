extends Node

const OUT_DIR := "res://build/screenshots"

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_run")

func _run() -> void:
    var absolute_dir := ProjectSettings.globalize_path(OUT_DIR)
    var err := DirAccess.make_dir_recursive_absolute(absolute_dir)
    if err != OK and err != ERR_ALREADY_EXISTS:
        push_error("[VISUAL_V043] cannot create screenshot directory")
        get_tree().quit(1)
        return

    var packed := load("res://scenes/stage1/stage1.tscn") as PackedScene
    if packed == null:
        push_error("[VISUAL_V043] Stage 1 failed to load")
        get_tree().quit(1)
        return
    var stage := packed.instantiate()
    add_child(stage)
    await _wait_frames(12)

    var fallback := stage.get_node_or_null("RuntimeEnvironmentPolish")
    if fallback == null:
        push_error("[VISUAL_V043] RuntimeEnvironmentPolish missing")
        get_tree().quit(1)
        return
    await _save_viewport("16_art_density.png")

    var player := get_tree().get_first_node_in_group("player") as PlayerController
    var net := get_tree().get_first_node_in_group("hex_net") as HexNet
    var scan := get_tree().get_first_node_in_group("echo_scan") as EchoScan
    if player == null or net == null or scan == null:
        push_error("[VISUAL_V043] gameplay nodes missing")
        get_tree().quit(1)
        return

    net.request_swing()
    await _wait_frames(2)
    await _save_viewport("17_ren_net_pose.png")

    scan.request_scan()
    await _wait_frames(2)
    await _save_viewport("18_ren_scan_pose.png")

    print("[VISUAL_V043] PASS — art density and Ren action poses saved")
    get_tree().quit(0)

func _wait_frames(count: int) -> void:
    for _i in range(count):
        await get_tree().process_frame

func _save_viewport(file_name: String) -> void:
    await RenderingServer.frame_post_draw
    var image := get_viewport().get_texture().get_image()
    if image == null or image.is_empty():
        push_error("[VISUAL_V043] empty image: %s" % file_name)
        get_tree().quit(1)
        return
    var path := "%s/%s" % [OUT_DIR, file_name]
    var save_err := image.save_png(path)
    if save_err != OK:
        push_error("[VISUAL_V043] save failed: %s" % file_name)
        get_tree().quit(1)
        return
    print("[VISUAL_V043] saved ", ProjectSettings.globalize_path(path))
