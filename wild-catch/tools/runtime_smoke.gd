extends Node

var _failures: Array[String] = []
var _stage_clear_count := 0
var _scan_payload: Dictionary = {}
var _signature_actions: Dictionary = {}
var _audio_events: Dictionary = {}

func _ready() -> void:
    call_deferred("_run")

func _run() -> void:
    print("[RUNTIME_QA] WILD CATCH smoke test start")

    var save_manager := get_tree().root.get_node_or_null("SaveManager")
    var audio_manager := get_tree().root.get_node_or_null("AudioManager")
    _check(save_manager != null, "SaveManager autoload is available")
    _check(audio_manager != null, "AudioManager autoload is available")
    if save_manager != null:
        save_manager.call("reset_all_progress")
    if audio_manager != null:
        audio_manager.event_played.connect(_on_audio_event)

    var title_packed := load("res://scenes/ui/title_screen.tscn") as PackedScene
    _check(title_packed != null, "Title screen PackedScene loads")
    var packed := load("res://scenes/stage1/stage1.tscn") as PackedScene
    _check(packed != null, "Stage 1 PackedScene loads")
    if packed == null:
        _finish()
        return

    var stage := packed.instantiate()
    add_child(stage)
    await get_tree().process_frame
    await get_tree().process_frame

    var game_state := get_tree().root.get_node_or_null("GameState")
    _check(game_state != null, "GameState autoload is available")
    if game_state == null:
        _finish()
        return
    game_state.stage_cleared.connect(_on_stage_cleared)

    var players := get_tree().get_nodes_in_group("player")
    var mimos := get_tree().get_nodes_in_group("mimo")
    var scans := get_tree().get_nodes_in_group("echo_scan")
    var nets := get_tree().get_nodes_in_group("hex_net")
    var lures := get_tree().get_nodes_in_group("lure_pod")
    var pulses := get_tree().get_nodes_in_group("pulse_disc")
    var drones := get_tree().get_nodes_in_group("scout_drone")
    var pulse_targets := get_tree().get_nodes_in_group("pulse_target")
    var escape_anchors := get_tree().get_nodes_in_group("mimo_escape_anchor")
    var relics := get_tree().get_nodes_in_group("field_relic")
    var directors := get_tree().get_nodes_in_group("signature_action_director")

    _check(players.size() == 1, "Exactly one player is registered")
    _check(mimos.size() == 6, "Exactly six Stage 1 Mimo are registered")
    _check(scans.size() == 1, "Exactly one ECHO SCAN is registered")
    _check(nets.size() == 1, "Exactly one HEX NET is registered")
    _check(lures.size() == 1, "Exactly one LURE POD is registered")
    _check(pulses.size() == 1, "Exactly one PULSE DISC is registered")
    _check(drones.size() == 1, "Exactly one SCOUT DRONE is registered")
    _check(pulse_targets.size() >= 1, "Stage 1 has a pulse-reactive route gimmick")
    _check(escape_anchors.size() == 18, "Stage 1 exposes exactly 18 Mimo escape anchors")
    _check(relics.size() == 6, "Stage 1 exposes exactly six persistent field relics")
    _check(directors.size() == 1, "Exactly one signature-action director is registered")

    if players.is_empty() or mimos.size() != 6 or scans.is_empty() or lures.is_empty() or pulses.is_empty() or drones.is_empty():
        _finish()
        return

    var player := players[0] as PlayerController
    var scan := scans[0] as EchoScan
    var lure := lures[0] as LurePod
    var pulse := pulses[0] as PulseDisc
    var drone := drones[0] as ScoutDrone
    var director := directors[0] as SignatureActionDirector if not directors.is_empty() else null

    var expected_profiles := {
        &"lumi": &"timid", &"goro": &"zigzag", &"boka": &"challenger",
        &"nera": &"sentinel", &"moku": &"sleepy", &"raku": &"trickster",
    }
    var ids: Dictionary = {}
    var profiles: Dictionary = {}
    for node in mimos:
        var mimo := node as MimoBase
        _check(mimo != null, "Mimo node casts to MimoBase")
        if mimo != null:
            ids[mimo.mimo_id] = true
            profiles[mimo.behavior_profile] = true
            _check(mimo.behavior_profile == expected_profiles.get(mimo.mimo_id, &"runner"), "%s has expected behavior profile" % mimo.display_name)
    _check(ids.size() == 6, "All six Mimo IDs are unique")
    _check(profiles.size() == 6, "All six Stage 1 Mimo use distinct escape profiles")

    var anchor_counts: Dictionary = {}
    for node in escape_anchors:
        var anchor := node as Node3D
        if anchor == null:
            continue
        var target_id := StringName(anchor.get_meta("target_mimo", &""))
        anchor_counts[target_id] = int(anchor_counts.get(target_id, 0)) + 1
    for mimo_id in expected_profiles.keys():
        _check(int(anchor_counts.get(mimo_id, 0)) == 3, "%s has exactly three terrain escape anchors" % String(mimo_id).capitalize())

    _check(lure.get_profile_effectiveness(&"sleepy") > lure.get_profile_effectiveness(&"trickster"), "LURE POD is meaningfully stronger against sleepy than trickster profile")
    _check(lure.get_profile_effectiveness(&"timid") > 1.0, "LURE POD has explicit advantage against timid profile")
    _check(pulse.get_profile_effectiveness(&"zigzag") > pulse.get_profile_effectiveness(&"sleepy"), "PULSE DISC is meaningfully stronger against zigzag than sleepy profile")
    _check(pulse.get_profile_effectiveness(&"sentinel") > 1.0, "PULSE DISC has explicit advantage against sentinel profile")

    var lure_target := mimos[1] as MimoBase
    lure_target.state = MimoBase.State.ROUTINE
    lure_target.global_position = player.global_position + Vector3(0.0, 0.0, -5.0)
    var lure_count := lure.deploy(player)
    _check(lure_count >= 1, "LURE POD can influence a nearby uncaptured Mimo")
    _check(lure_target.is_lured(), "Mimo exposes active lure response")

    var pulse_target := mimos[2] as MimoBase
    pulse_target.state = MimoBase.State.ROUTINE
    pulse_target.global_position = player.global_position + Vector3(0.0, 0.0, -6.0)
    var stamina_before := pulse_target.stamina
    var pulse_count := pulse.debug_fire_at(pulse_target.global_position)
    _check(pulse_count >= 1, "PULSE DISC can hit a nearby Mimo")
    _check(pulse_target.is_stunned(), "PULSE DISC applies a temporary stun")
    _check(pulse_target.stamina < stamina_before, "PULSE DISC reduces target stamina")

    var revealed := drone.launch(player)
    _check(revealed >= 1, "SCOUT DRONE reveals uncaptured Mimo routes")
    _check(not drone.is_cartographer_upgraded(), "SCOUT DRONE starts unupgraded before relic completion")

    if not pulse_targets.is_empty():
        var switch := pulse_targets[0]
        var opened_now := bool(switch.call("trigger_pulse", (switch as Node3D).global_position))
        _check(opened_now, "PULSE DISC route switch can be activated")
        _check(bool(switch.get("is_open")), "Pulse-reactive ruins gate reports open state")

    if director != null:
        director.signature_action.connect(_on_signature_action)
        for node in mimos:
            director.call("_trigger_signature", node as MimoBase)
        await get_tree().process_frame
        _check(_signature_actions.size() == 6, "All six Mimo signature actions can be triggered")
        for action_name in [&"grass_hide", &"stone_throw", &"counter_charge", &"spark_burst", &"sleep_cloud", &"decoy_split"]:
            _check(_signature_actions.has(action_name), "Signature action registered: %s" % String(action_name))

    player.apply_slow(0.55, 0.15)
    player.apply_stagger(0.08, 1.0)
    player.add_camera_impulse(Vector2(4.0, -3.0))
    _check(true, "Player reaction API accepts slow, stagger and camera feedback")

    for node in relics:
        var relic := node as FieldRelic
        if relic != null:
            relic.collect()
    await get_tree().process_frame
    await get_tree().process_frame
    _check(game_state.get_relic_count() == 6, "Collecting all field relics produces 6/6 relic progress")
    if save_manager != null:
        _check(int(save_manager.call("get_relic_count")) == 6, "All six relics persist through SaveManager")
        _check(bool(save_manager.call("has_unlock", &"ruins_cartographer")), "Six relics unlock RUINS CARTOGRAPHER permanently")

    var upgraded_drone := ScoutDrone.new()
    upgraded_drone.name = "CartographerDroneQA"
    stage.add_child(upgraded_drone)
    await get_tree().process_frame
    _check(upgraded_drone.is_cartographer_upgraded(), "Fresh SCOUT DRONE applies persistent Cartographer upgrade")
    _check(upgraded_drone.scan_radius >= 44.0, "Cartographer upgrade increases drone scan radius")
    _check(upgraded_drone.max_reveals >= 4, "Cartographer upgrade increases simultaneous route reveals")
    _check(upgraded_drone.cooldown_seconds <= 6.8, "Cartographer upgrade reduces drone cooldown")
    upgraded_drone.queue_free()

    var hud := stage.get_node_or_null("UI/MobileHUD") as MobileHUD
    _check(hud != null, "Mobile HUD is available")
    if hud != null:
        _check(hud.get_node_or_null("FieldLogButton") != null, "FIELD LOG button is built at runtime")
        _check(hud.get_node_or_null("FieldLogPanel") != null, "FIELD LOG panel is built at runtime")

    var first := mimos[0] as MimoBase
    first.global_position = player.global_position + Vector3(0.0, 0.0, -1.0)
    first.state = MimoBase.State.FATIGUED
    var ready_payload := first.get_scan_payload(player.global_position)
    _check(bool(ready_payload.get("capture_ready", false)), "Fatigued Mimo reports capture-ready through SCAN payload")
    _check(String(ready_payload.get("capture_status", "")).contains("READY"), "Capture-ready payload exposes a readable READY status")
    _check(ready_payload.has("route"), "SCAN payload exposes terrain route hint")
    var captured_now := first.attempt_capture(3, player)
    await get_tree().process_frame
    _check(captured_now, "Fatigued nearby Mimo can be captured with HEX NET step 3 rules")
    _check(game_state.get_capture_count() == 1, "First capture increments progress to 1")
    if save_manager != null:
        _check(bool(save_manager.call("has_captured", first.mimo_id)), "Captured Mimo persists in bestiary SaveManager data")

    first.capture()
    await get_tree().process_frame
    _check(game_state.get_capture_count() == 1, "Repeated capture does not double-count")

    scan.scan_result.connect(_on_scan_result, CONNECT_ONE_SHOT)
    scan.request_scan()
    await get_tree().process_frame
    _check(not _scan_payload.is_empty(), "ECHO SCAN returns an uncaptured target")
    if not _scan_payload.is_empty():
        _check(StringName(_scan_payload.get("id", "")) != first.mimo_id, "ECHO SCAN excludes captured Mimo")

    var traversal := stage.get_node_or_null("TraversalLayer")
    _check(traversal != null, "Stage 1 builds runtime traversal layer")
    if traversal != null:
        _check(traversal.get_child_count() >= 10, "Box-garden layer contains terraces, ramps and stepping routes")

    for node in mimos:
        var mimo := node as MimoBase
        if mimo != null and mimo.state != MimoBase.State.CAPTURED:
            mimo.capture()
    await get_tree().process_frame
    await get_tree().process_frame

    _check(game_state.get_capture_count() == 6, "Six unique captures produce 6/6 progress")
    _check(_stage_clear_count == 1, "Stage Clear emits exactly once")
    if save_manager != null:
        _check(int(save_manager.call("get_stage_clear_count", &"stage1")) >= 1, "Stage Clear persists through SaveManager")
        var summary: Array = save_manager.call("get_bestiary_summary")
        _check(summary.size() == 6, "Persistent bestiary exposes all six Stage 1 entries")
        _check(int(save_manager.call("get_unique_capture_count")) == 6, "Persistent bestiary count cannot exceed six known Mimo")
        var result: Dictionary = save_manager.call("get_stage_result", &"stage1")
        _check(not result.is_empty(), "Ranked Stage 1 result persists through SaveManager")
        _check(String(result.get("best_rank", "")) == "S", "Fast 6/6 relic QA clear records S rank")
        _check(int(result.get("best_relics", 0)) == 6, "Ranked result stores full relic completion")

    game_state.mark_captured(&"extra_should_not_reclear")
    await get_tree().process_frame
    _check(_stage_clear_count == 1, "Progress above target cannot emit Stage Clear twice")
    if save_manager != null:
        _check(int(save_manager.call("get_unique_capture_count")) == 6, "Unknown capture IDs do not pollute persistent bestiary")

    for required_audio in [&"lure", &"pulse", &"drone", &"relic", &"unlock", &"capture", &"scan", &"stage_clear"]:
        _check(_audio_events.has(required_audio), "Audio event emitted: %s" % String(required_audio))

    _finish()

func _on_stage_cleared(_stage_id: StringName) -> void:
    _stage_clear_count += 1

func _on_scan_result(payload: Dictionary) -> void:
    _scan_payload = payload.duplicate(true)

func _on_signature_action(_mimo_id: StringName, action_name: StringName) -> void:
    _signature_actions[action_name] = true

func _on_audio_event(event_id: StringName) -> void:
    _audio_events[event_id] = true

func _check(condition: bool, label: String) -> void:
    if condition:
        print("[RUNTIME_QA][PASS] ", label)
    else:
        _failures.append(label)
        push_error("[RUNTIME_QA][FAIL] %s" % label)

func _finish() -> void:
    if _failures.is_empty():
        print("[RUNTIME_QA] PASS")
        get_tree().quit(0)
    else:
        print("[RUNTIME_QA] FAILURES: ", _failures.size())
        for failure in _failures:
            print("  - ", failure)
        get_tree().quit(1)
