extends Node

const OUT_DIR := "res://build/screenshots"

@onready var scene_root: Node = $SceneRoot

func _ready() -> void:
    call_deferred("_run")

func _run() -> void:
    SaveManager.reset_all_progress()
    var absolute_dir := ProjectSettings.globalize_path(OUT_DIR)
    var err := DirAccess.make_dir_recursive_absolute(absolute_dir)
    if err != OK and err != ERR_ALREADY_EXISTS:
        push_error("[VISUAL_QA] cannot create screenshot directory: %s" % err)
        get_tree().quit(1)
        return

    print("[VISUAL_QA] capturing Japanese title")
    var title_scene := load("res://scenes/ui/title_screen.tscn") as PackedScene
    if title_scene == null:
        push_error("[VISUAL_QA] title scene failed to load")
        get_tree().quit(1)
        return
    scene_root.add_child(title_scene.instantiate())
    await _wait_frames(5)
    await _save_viewport("01_title.png")
    await _clear_scene_root()

    print("[VISUAL_QA] capturing Japanese Stage 1")
    var stage_scene := load("res://scenes/stage1/stage1.tscn") as PackedScene
    if stage_scene == null:
        push_error("[VISUAL_QA] Stage 1 failed to load")
        get_tree().quit(1)
        return
    var stage := stage_scene.instantiate()
    scene_root.add_child(stage)
    await _wait_frames(12)
    await _save_viewport("02_stage1_start.png")

    var players := get_tree().get_nodes_in_group("player")
    var mimos := get_tree().get_nodes_in_group("mimo")
    var scans := get_tree().get_nodes_in_group("echo_scan")
    var lures := get_tree().get_nodes_in_group("lure_pod")
    var pulses := get_tree().get_nodes_in_group("pulse_disc")
    var drones := get_tree().get_nodes_in_group("scout_drone")
    var switches := get_tree().get_nodes_in_group("pulse_target")
    var directors := get_tree().get_nodes_in_group("signature_action_director")
    var relics := get_tree().get_nodes_in_group("field_relic")
    var shrines := get_tree().get_nodes_in_group("secret_shrine")
    if players.is_empty() or mimos.is_empty() or scans.is_empty() or lures.is_empty() or pulses.is_empty() or drones.is_empty():
        push_error("[VISUAL_QA] gameplay/gadget nodes missing for staged captures")
        get_tree().quit(1)
        return

    var player := players[0] as Node3D
    var first := mimos[0] as MimoBase
    var second := mimos[1] as MimoBase
    var scan := scans[0] as EchoScan
    var lure := lures[0] as LurePod
    var pulse := pulses[0] as PulseDisc
    var drone := drones[0] as ScoutDrone
    var hud := stage.get_node_or_null("UI/MobileHUD") as MobileHUD

    first.global_position = player.global_position + Vector3(0.0, 0.0, -4.5)
    first.state = MimoBase.State.ROUTINE
    first.stamina = first.stamina_max * 0.62
    scan.request_scan()
    await _wait_frames(4)
    await _save_viewport("03_echo_scan.png")

    first.state = MimoBase.State.PANIC
    first.stamina = 0.0
    first.set_state(MimoBase.State.FATIGUED)
    await _wait_frames(4)
    await _save_viewport("04_capture_window.png")

    _clear_overlay(stage, true)
    _set_visual_context(stage, "ガジェット確認  •  誘導ポッド", "誘導フィールド  •  逃走ルートから引き離す")
    first.state = MimoBase.State.ROUTINE
    first.stamina = first.stamina_max
    second.state = MimoBase.State.ROUTINE
    second.global_position = player.global_position + Vector3(-2.0, 0.0, -5.0)
    lure.deploy(player)
    await _wait_frames(8)
    await _save_viewport("05_lure_pod.png")

    _clear_overlay(stage, true)
    _set_visual_context(stage, "ガジェット確認  •  パルスディスク", "パルス装置  •  追跡ショートカットを開く")
    var pulse_gate: PulseSwitch
    for target in switches:
        if target is PulseSwitch:
            pulse_gate = target as PulseSwitch
            break
    if pulse_gate != null:
        pulse_gate.global_position = player.global_position + Vector3(2.8, 0.0, -4.0)
        pulse.debug_fire_at(pulse_gate.global_position)
        await _wait_frames(12)
        await _save_viewport("06_pulse_gate.png")

    _clear_overlay(stage, false)
    _set_visual_context(stage, "ガジェット確認  •  偵察ドローン", "ドローン索敵  •  複数の逃走ルートを表示")
    drone.launch(player)
    await _wait_frames(8)
    await _save_viewport("07_scout_drone.png")

    if hud != null:
        SaveManager.record_capture(&"lumi")
        SaveManager.record_capture(&"goro")
        SaveManager.record_relic(&"sun_disc")
        SaveManager.record_relic(&"river_pearl")
        hud.toggle_field_log()
        await _wait_frames(4)
        await _save_viewport("08_field_log.png")
        hud.toggle_field_log()

    if not directors.is_empty() and mimos.size() >= 6:
        _clear_overlay(stage, true)
        _set_visual_context(stage, "ミモ固有技  •  ラク", "分身フェイント  •  ドローンで本物を見破る")
        var raku := mimos[5] as MimoBase
        raku.global_position = player.global_position + Vector3(0.0, 0.0, -5.0)
        (directors[0] as SignatureActionDirector).call("_trigger_signature", raku)
        await _wait_frames(5)
        await _save_viewport("09_signature_raku.png")

    # Reveal the new secret progression through the real relic flow.
    for node in relics:
        var relic := node as FieldRelic
        if relic != null and not GameState.found_relics.has(relic.relic_id):
            GameState.mark_relic_found(relic.relic_id)
    await _wait_frames(5)
    if not shrines.is_empty():
        _clear_overlay(stage, true)
        _set_visual_context(stage, "隠し遺跡シグナル", "遺物6/6で出現  •  パルスを当てて共鳴させる")
        var shrine := shrines[0] as SecretShrine
        shrine.global_position = player.global_position + Vector3(2.5, 0.0, -5.0)
        await _wait_frames(4)
        await _save_viewport("10_secret_shrine.png")
        pulse.debug_fire_at(shrine.global_position)
        await _wait_frames(6)

    # Force a full Japanese result screen after the secret progression shot.
    for node in mimos:
        var mimo := node as MimoBase
        if mimo != null and mimo.state != MimoBase.State.CAPTURED:
            mimo.capture()
    await _wait_frames(8)
    await _save_viewport("11_stage_clear_jp.png")

    print("[VISUAL_QA] PASS — 11 screenshots saved")
    get_tree().quit(0)

func _clear_overlay(stage: Node, hide_scan: bool) -> void:
    var hud := stage.get_node_or_null("UI/MobileHUD")
    if hud == null:
        return
    var capture_ready := hud.get_node_or_null("CaptureReadyLabel") as CanvasItem
    var toast := hud.get_node_or_null("ToastLabel") as CanvasItem
    var gadget_status := hud.get_node_or_null("GadgetStatusLabel") as CanvasItem
    var scan_panel := hud.get_node_or_null("ScanPanel") as CanvasItem
    if capture_ready != null:
        capture_ready.visible = false
    if toast != null:
        toast.visible = false
    if gadget_status != null:
        gadget_status.visible = false
    if hide_scan and scan_panel != null:
        scan_panel.visible = false

func _set_visual_context(stage: Node, objective_text: String, target_text: String) -> void:
    var hud := stage.get_node_or_null("UI/MobileHUD")
    if hud == null:
        return
    var objective := hud.get_node_or_null("TopBar/Margin/Rows/StatusRow/ObjectiveLabel") as Label
    var target := hud.get_node_or_null("TopBar/Margin/Rows/TargetLabel") as Label
    if objective != null:
        objective.text = objective_text
    if target != null:
        target.text = target_text

func _wait_frames(count: int) -> void:
    for _i in range(count):
        await get_tree().process_frame

func _save_viewport(file_name: String) -> void:
    await RenderingServer.frame_post_draw
    var image := get_viewport().get_texture().get_image()
    if image == null or image.is_empty():
        push_error("[VISUAL_QA] empty image: %s" % file_name)
        get_tree().quit(1)
        return
    var path := "%s/%s" % [OUT_DIR, file_name]
    var err := image.save_png(path)
    if err != OK:
        push_error("[VISUAL_QA] save failed %s: %s" % [file_name, err])
        get_tree().quit(1)
        return
    print("[VISUAL_QA] saved ", ProjectSettings.globalize_path(path))

func _clear_scene_root() -> void:
    for child in scene_root.get_children():
        child.queue_free()
    await get_tree().process_frame
    await get_tree().process_frame
