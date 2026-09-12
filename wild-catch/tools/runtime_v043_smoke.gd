extends Node

var _failures: Array[String] = []

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_run")

func _run() -> void:
    print("[RUNTIME_V043] start")
    var art_runtime := get_tree().root.get_node_or_null("StageArtRuntime")
    _check(art_runtime != null, "StageArtRuntime autoload is available")
    _check(get_tree().root.get_node_or_null("CheckpointRuntime") != null, "CheckpointRuntime autoload is available")

    var packed := load("res://scenes/stage1/stage1.tscn") as PackedScene
    _check(packed != null, "Stage 1 loads for v0.4.3 art bridge QA")
    if packed == null:
        _finish()
        return

    var stage := packed.instantiate()
    add_child(stage)
    await get_tree().process_frame
    await get_tree().process_frame
    await get_tree().process_frame

    var resolved_stage_art := ProductionArtPaths.stage1_scene()
    var fallback := stage.get_node_or_null("RuntimeEnvironmentPolish")
    var production_environment := stage.get_node_or_null("ProductionEnvironmentArt")
    if resolved_stage_art != null:
        _check(production_environment != null, "Stage 1 production art is auto-installed when a GLB/glTF/preview scene is present")
        _check(fallback == null, "Fallback environment is not installed when Stage 1 production art exists")
    else:
        _check(fallback != null, "Stage 1 fallback art density layer is installed when production art is absent")
        if fallback != null:
            _check(fallback.get_node_or_null("GrassTufts") is MultiMeshInstance3D, "Grass MultiMesh is installed")
            _check(fallback.get_node_or_null("ShrubClusters") is MultiMeshInstance3D, "Shrub MultiMesh is installed")
            _check(fallback.get_node_or_null("RuinPebbles") is MultiMeshInstance3D, "Ruin pebble MultiMesh is installed")
            _check(fallback.get_node_or_null("SunFlowers") is MultiMeshInstance3D, "Flower accent MultiMesh is installed")
            _check(fallback.get_node_or_null("WaterReeds") is MultiMeshInstance3D, "Water reed MultiMesh is installed")
            _check(fallback.get_node_or_null("RuinColumns") is MultiMeshInstance3D, "Ruin accent MultiMesh is installed")
    _check(stage.get_node_or_null("RuntimeFillLight") is DirectionalLight3D, "Runtime fill light is installed")
    var world := stage.get_node_or_null("WorldEnvironment") as WorldEnvironment
    _check(world != null and world.environment != null, "Stage 1 WorldEnvironment remains available")
    if world != null and world.environment != null:
        _check(world.environment.fog_enabled, "Stage 1 atmospheric fog is enabled")
        _check(world.environment.adjustment_enabled, "Stage 1 color adjustment is enabled")

    var player := get_tree().get_first_node_in_group("player") as PlayerController
    _check(player != null, "Player exists for production-art bridge QA")
    if player == null:
        _finish()
        return
    var player_visual := player.get_node_or_null("Visual") as PlayerVisualController
    _check(player_visual != null, "Ren PlayerVisualController is attached")
    if player_visual != null:
        var resolved_ren := ProductionArtPaths.ren_scene()
        if resolved_ren != null:
            _check(player_visual.has_production_art(), "Ren resolved art is auto-installed when GLB/glTF/preview scene is present")
            _check_animation_contract(player_visual.get("_animation_player") as AnimationPlayer, [&"Idle", &"Run", &"Jump"], "Ren")
        else:
            _check(not player_visual.has_production_art(), "Ren safely falls back when production art is absent")

    var checkpoints := get_tree().get_nodes_in_group("field_checkpoint")
    _check(checkpoints.size() == 3, "Stage 1 installs exactly three field checkpoints")
    if not checkpoints.is_empty():
        var checkpoint := checkpoints[0] as FieldCheckpoint
        player.global_position = checkpoint.global_position
        await get_tree().process_frame
        await get_tree().process_frame
        _check(checkpoint.is_activated(), "Entering a field checkpoint activates it")
        _check(player.get_checkpoint_label() == checkpoint.checkpoint_label, "Activated checkpoint updates player checkpoint label")
        var expected_respawn := checkpoint.global_position + Vector3.UP * 0.35
        _check(player.get_checkpoint_position().distance_to(expected_respawn) < 0.05, "Activated checkpoint updates respawn position")
        player.health = 1
        player.set("_invulnerability_time", 0.0)
        player.global_position += Vector3(4.0, 0.0, 4.0)
        player.take_damage(1)
        await get_tree().process_frame
        _check(player.health == player.max_health, "Knockout at a checkpoint restores all hearts")
        _check(player.global_position.distance_to(expected_respawn) < 0.10, "Knockout returns player to the latest checkpoint")

    var mimos := get_tree().get_nodes_in_group("mimo")
    _check(mimos.size() == 6, "Six Mimo exist for visual bridge QA")
    for node in mimos:
        var mimo := node as MimoBase
        if mimo == null:
            continue
        var visual := mimo.get_node_or_null("Visual") as MimoVisualController
        _check(visual != null, "%s has MimoVisualController" % String(mimo.mimo_id))
        if visual == null:
            continue
        var resolved_mimo := ProductionArtPaths.mimo_scene(mimo.mimo_id)
        if resolved_mimo != null:
            _check(visual.has_production_art(), "%s resolved art is auto-installed" % String(mimo.mimo_id))
            _check_animation_contract(visual.get("_animation_player") as AnimationPlayer, [&"Idle", &"Run", &"Tired", &"Capture"], String(mimo.mimo_id))
        else:
            _check(not visual.has_production_art(), "%s safely falls back without production art" % String(mimo.mimo_id))

    var director := get_tree().get_first_node_in_group("signature_action_director") as SignatureActionDirector
    _check(director != null, "SignatureActionDirector exists for character-action bridge QA")
    if director != null:
        for node in mimos:
            var candidate := node as MimoBase
            if candidate != null and candidate.mimo_id == &"goro":
                director.call("_trigger_signature", candidate)
                await get_tree().process_frame
                var visual := candidate.get_node_or_null("Visual") as MimoVisualController
                _check(visual != null and String(visual.get("_action_semantic")) == "throw_rock", "Goro stone throw drives throw_rock character semantic")
                break

    var net := get_tree().get_first_node_in_group("hex_net") as HexNet
    var scan := get_tree().get_first_node_in_group("echo_scan") as EchoScan
    _check(net != null and scan != null, "NET and SCAN exist for Ren action-animation bridge QA")
    if player_visual != null and net != null:
        net.request_swing()
        await get_tree().process_frame
        _check(String(player_visual.get("_action_semantic")) == "net_1", "HEX NET swing drives Ren net_1 action semantic")
    if player_visual != null and scan != null:
        scan.request_scan()
        await get_tree().process_frame
        _check(String(player_visual.get("_action_semantic")) == "scan", "ECHO SCAN drives Ren scan action semantic")
        var scan_feedback := get_tree().current_scene.find_child("EchoScanFeedback", true, false) if get_tree().current_scene != null else null
        _check(scan_feedback is ScanFeedback, "ECHO SCAN creates world-space scan feedback")
        if scan_feedback != null:
            _check(scan_feedback.get_node_or_null("ScanWave") is MeshInstance3D, "ECHO SCAN feedback creates expanding scan wave")
            _check(scan_feedback.get_node_or_null("TargetBeacon") is Node3D, "ECHO SCAN feedback creates target beacon when a Mimo is found")

    _check(ProductionArtPaths.REN_GLB.ends_with("art/characters/ren/ren.glb"), "Ren GLB production path is canonical")
    _check(ProductionArtPaths.REN_GLTF.ends_with("art/characters/ren/ren.gltf"), "Ren glTF fallback path is canonical")
    _check(ProductionArtPaths.mimo_scene_path(&"lumi").ends_with("art/mimo/lumi/lumi.glb"), "Mimo primary production art path is canonical")
    _check(ProductionArtPaths.STAGE1_GLB.ends_with("art/environment/stage1/stage1_set.glb"), "Stage 1 GLB production art path is canonical")
    _check(ProductionArtPaths.STAGE1_GLTF.ends_with("art/environment/stage1/stage1_set.gltf"), "Stage 1 glTF fallback path is canonical")

    _finish()

func _check_animation_contract(animation_player: AnimationPlayer, required: Array[StringName], label: String) -> void:
    _check(animation_player != null, "%s production art exposes AnimationPlayer" % label)
    if animation_player == null:
        return
    for animation_name in required:
        _check(animation_player.has_animation(animation_name), "%s production art contains %s animation" % [label, String(animation_name)])

func _check(condition: bool, label: String) -> void:
    if condition:
        print("[RUNTIME_V043][PASS] ", label)
    else:
        _failures.append(label)
        push_error("[RUNTIME_V043][FAIL] %s" % label)

func _finish() -> void:
    get_tree().paused = false
    if _failures.is_empty():
        print("[RUNTIME_V043] PASS")
        get_tree().quit(0)
    else:
        print("[RUNTIME_V043] FAILURES: ", _failures.size())
        for failure in _failures:
            print("  - ", failure)
        get_tree().quit(1)
