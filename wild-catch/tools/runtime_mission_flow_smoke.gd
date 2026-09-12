extends Node

var _failures: Array[String] = []

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_run")

func _run() -> void:
    print("[MISSION_FLOW] start")
    _check(get_tree().root.get_node_or_null("MissionRouter") != null, "MissionRouter autoload exists")
    _check(get_tree().root.get_node_or_null("MissionStageFlowRuntime") != null, "Mission stage flow runtime exists")
    _check(get_tree().root.get_node_or_null("InterferenceRuntime") != null, "Interference runtime exists")
    _check(get_tree().root.get_node_or_null("StageMimoIdentityRuntime") != null, "Stage Mimo identity runtime exists")
    _check(get_tree().root.get_node_or_null("MissionHazardRuntime") != null, "Mission hazard runtime exists")
    _check(get_tree().root.get_node_or_null("MissionPropRuntime") != null, "Mission prop density runtime exists")
    _check(get_tree().root.get_node_or_null("MissionSignatureRuntime") != null, "Stage 2/3 signature runtime exists")
    _check(get_tree().root.get_node_or_null("HubControlsRuntime") != null, "Field Base mobile controls runtime exists")
    _check(get_tree().root.get_node_or_null("HubStatsRuntime") != null, "Field Base stats runtime exists")
    _check(MissionRouter.get_mission_ids().size() == 3, "Three mission definitions are registered")
    _check(SaveManager.get_bestiary_total() == 18, "Persistent bestiary supports eighteen capture targets")

    var hub_packed := load("res://scenes/hub/hub.tscn") as PackedScene
    _check(hub_packed != null, "Field Base hub scene loads")
    if hub_packed != null:
        var hub := hub_packed.instantiate()
        add_child(hub)
        await _wait_frames(4)
        _check(hub.get_node_or_null("TransferGate") != null, "Field Base creates transfer gate")
        _check(hub.get_node_or_null("HubUI") != null, "Field Base creates mission terminal UI")
        _check(hub.get_node_or_null("HubControls") != null, "Field Base installs Android movement/camera controls")
        var hub_ui := hub.get_node_or_null("HubUI")
        _check(hub_ui != null and hub_ui.get_node_or_null("FieldRecordPanel") != null, "Field Base installs persistent field-record terminal")
        hub.queue_free()
        await _wait_frames(3)

    await _test_stage("res://scenes/stage2/stage2.tscn", &"stage2", 5, 3, &"aero", MissionHazardZone.Kind.UPDRAFT)
    await _test_stage("res://scenes/stage3/stage3.tscn", &"stage3", 7, 4, &"pico", MissionHazardZone.Kind.GLOW_MUD)
    _finish()

func _test_stage(path: String, stage_id: StringName, expected_mimo: int, expected_enemies: int, identity_id: StringName, expected_hazard_kind: int) -> void:
    var packed := load(path) as PackedScene
    _check(packed != null, "%s scene loads" % String(stage_id))
    if packed == null:
        return
    var stage := packed.instantiate()
    add_child(stage)
    await _wait_frames(4)
    await get_tree().physics_frame

    var mimos := _nodes_under_group(stage, "mimo")
    var enemies := _nodes_under_group(stage, "interference_enemy")
    var hazards := _nodes_under_group(stage, "mission_hazard")
    _check(mimos.size() == expected_mimo, "%s has %d capture targets" % [String(stage_id), expected_mimo])
    _check(enemies.size() == expected_enemies, "%s has %d non-capturable interference enemies" % [String(stage_id), expected_enemies])
    _check(hazards.size() == 3, "%s installs three stage-specific hazard zones" % String(stage_id))
    _check(stage.get_node_or_null("MissionProps") != null, "%s installs stage-specific prop density layer" % String(stage_id))
    var checkpoint_root := stage.get_node_or_null("RuntimeCheckpoints")
    _check(checkpoint_root != null and checkpoint_root.get_child_count() == 3, "%s installs three mission checkpoints" % String(stage_id))
    _check(GameState.current_stage_id == stage_id, "%s resets GameState to its own mission id" % String(stage_id))
    _check(GameState.stage_target_total == expected_mimo, "%s mission target total is correct" % String(stage_id))

    var identity_found := false
    for node in mimos:
        var mimo := node as MimoBase
        if mimo != null and mimo.mimo_id == identity_id:
            var visual := mimo.get_node_or_null("Visual") as MimoVisualController
            if visual != null:
                var art_root := visual.get_production_root()
                if art_root == null:
                    art_root = visual
                identity_found = art_root.get_node_or_null("StageIdentityLayer") != null
            break
    _check(identity_found, "%s receives its individual preview CG identity layer" % String(identity_id))

    var player := _find_under_group(stage, "player") as PlayerController
    _check(player != null, "%s player resolves for hazard regression" % String(stage_id))
    if player != null and not hazards.is_empty():
        var hazard := hazards[0] as MissionHazardZone
        _check(hazard != null and hazard.kind == expected_hazard_kind, "%s hazard type matches mission theme" % String(stage_id))
        if hazard != null:
            player.global_position = hazard.global_position + Vector3(0.2, 0.0, 0.2)
            if expected_hazard_kind == MissionHazardZone.Kind.UPDRAFT:
                player.velocity.y = 0.0
                hazard.call("_process", 0.10)
                _check(player.velocity.y >= 5.5, "Stage 2 updraft physically lifts Ren")
            else:
                hazard.call("_process", 0.10)
                var slow_value := float(player.get("_slow_multiplier"))
                _check(slow_value <= 0.57, "Stage 3 glow mud applies meaningful movement slow")

    if not enemies.is_empty():
        var enemy := enemies[0] as InterferenceEnemy
        _check(enemy != null and not enemy.is_in_group("mimo"), "Interference enemy stays outside capture-target group")
        if enemy != null:
            var defeats_before := SaveManager.get_interference_defeats(stage_id)
            for _i in range(enemy.max_health):
                enemy.trigger_pulse(enemy.global_position)
            _check(enemy.health == 0, "Interference enemy can be defeated with pulse hits")
            _check(SaveManager.get_interference_defeats(stage_id) == defeats_before + 1, "Interference defeat persists to field record")

    stage.queue_free()
    await _wait_frames(3)

func _find_under_group(root: Node, group_name: StringName) -> Node:
    for node in get_tree().get_nodes_in_group(group_name):
        if root == node or root.is_ancestor_of(node):
            return node
    return null

func _nodes_under_group(root: Node, group_name: StringName) -> Array[Node]:
    var result: Array[Node] = []
    for node in get_tree().get_nodes_in_group(group_name):
        if root == node or root.is_ancestor_of(node):
            result.append(node)
    return result

func _wait_frames(count: int) -> void:
    for _i in range(count):
        await get_tree().process_frame

func _check(condition: bool, label: String) -> void:
    if condition:
        print("[MISSION_FLOW][PASS] ", label)
    else:
        _failures.append(label)
        push_error("[MISSION_FLOW][FAIL] %s" % label)

func _finish() -> void:
    AudioManager.stop_music()
    if _failures.is_empty():
        print("[MISSION_FLOW] PASS")
        get_tree().quit(0)
    else:
        print("[MISSION_FLOW] FAILURES: ", _failures.size())
        for failure in _failures:
            print("  - ", failure)
        get_tree().quit(1)
