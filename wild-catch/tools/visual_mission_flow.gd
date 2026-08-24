extends Node

const OUT_DIR := "res://build/screenshots"

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_run")

func _run() -> void:
    var absolute_dir := ProjectSettings.globalize_path(OUT_DIR)
    var err := DirAccess.make_dir_recursive_absolute(absolute_dir)
    if err != OK and err != ERR_ALREADY_EXISTS:
        push_error("[VISUAL_MISSION] cannot create screenshot directory")
        get_tree().quit(1)
        return

    var hub_pack := load("res://scenes/hub/hub.tscn") as PackedScene
    var hub := hub_pack.instantiate()
    add_child(hub)
    await _wait_frames(12)
    await _save_viewport("27_field_base_hub.png")
    hub.queue_free()
    await _wait_frames(4)

    MissionRouter.select_mission(&"stage1")
    var loading_pack := load("res://scenes/ui/mission_loading.tscn") as PackedScene
    var loading := loading_pack.instantiate()
    add_child(loading)
    await _wait_frames(8)
    await _save_viewport("28_mission_briefing.png")
    loading.queue_free()
    AudioManager.stop_music()
    await _wait_frames(4)

    var stage2_pack := load("res://scenes/stage2/stage2.tscn") as PackedScene
    var stage2 := stage2_pack.instantiate()
    add_child(stage2)
    await _wait_frames(14)
    await _save_viewport("29_stage2_skywind.png")

    var stage2_player := _find_under(stage2, "player") as PlayerController
    var stage2_hazards := _group_under(stage2, "mission_hazard")
    if stage2_player != null and not stage2_hazards.is_empty():
        var updraft := stage2_hazards[0] as MissionHazardZone
        stage2_player.global_position = updraft.global_position + Vector3(0.4, 0.3, 1.4)
        await _wait_frames(6)
        await _save_viewport("32_stage2_updraft.png")
    stage2.queue_free()
    await _wait_frames(5)

    var stage3_pack := load("res://scenes/stage3/stage3.tscn") as PackedScene
    var stage3 := stage3_pack.instantiate()
    add_child(stage3)
    await _wait_frames(14)
    await _save_viewport("30_stage3_neon_swamp.png")

    var player := _find_under(stage3, "player") as PlayerController
    var enemies := _group_under(stage3, "interference_enemy")
    if player != null and not enemies.is_empty():
        var enemy := enemies[0] as InterferenceEnemy
        enemy.global_position = player.global_position + Vector3(0.8, 0.0, -2.8)
        await _wait_frames(5)
        await _save_viewport("31_interference_encounter.png")

    var stage3_hazards := _group_under(stage3, "mission_hazard")
    if player != null and not stage3_hazards.is_empty():
        var mud := stage3_hazards[0] as MissionHazardZone
        player.global_position = mud.global_position + Vector3(0.3, 0.3, 1.2)
        await _wait_frames(6)
        await _save_viewport("33_stage3_glow_mud.png")

    print("[VISUAL_MISSION] PASS — hub/briefing/stage2/stage3/hazards/interference screenshots saved")
    get_tree().quit(0)

func _find_under(root: Node, group_name: StringName) -> Node:
    for node in get_tree().get_nodes_in_group(group_name):
        if root == node or root.is_ancestor_of(node):
            return node
    return null

func _group_under(root: Node, group_name: StringName) -> Array[Node]:
    var result: Array[Node] = []
    for node in get_tree().get_nodes_in_group(group_name):
        if root == node or root.is_ancestor_of(node):
            result.append(node)
    return result

func _wait_frames(count: int) -> void:
    for _i in range(count):
        await get_tree().process_frame

func _save_viewport(file_name: String) -> void:
    await RenderingServer.frame_post_draw
    var image := get_viewport().get_texture().get_image()
    if image == null or image.is_empty():
        push_error("[VISUAL_MISSION] empty image: %s" % file_name)
        get_tree().quit(1)
        return
    var path := "%s/%s" % [OUT_DIR, file_name]
    var save_err := image.save_png(path)
    if save_err != OK:
        push_error("[VISUAL_MISSION] save failed: %s" % file_name)
        get_tree().quit(1)
        return
    print("[VISUAL_MISSION] saved ", ProjectSettings.globalize_path(path))
