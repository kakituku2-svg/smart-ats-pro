extends Node

var _failures: Array[String] = []

func _ready() -> void:
    call_deferred("_run")

func _run() -> void:
    print("[V041_QA] Japanese / secret progression smoke start")
    SaveManager.reset_all_progress()

    _check(JapaneseText.mimo_name(&"lumi") == "ルミ", "Japanese display layer maps Lumi")
    _check(JapaneseText.behavior(&"trickster").contains("トリックスター"), "Japanese display layer maps behavior")
    _check(JapaneseText.capture_status("READY — HEX NET NOW").contains("捕獲"), "Japanese display layer maps capture status")
    _check(JapaneseText.relic_name(&"sun_disc") == "太陽の円盤", "Japanese display layer maps relic name")

    var title_scene := load("res://scenes/ui/title_screen.tscn") as PackedScene
    _check(title_scene != null, "Japanese title scene loads")
    if title_scene != null:
        var title := title_scene.instantiate()
        add_child(title)
        await get_tree().process_frame
        var start_button := title.get_node_or_null("Center/Card/Content/StartButton") as Button
        var stage_label := title.get_node_or_null("Center/Card/Content/Stage") as Label
        _check(start_button != null and start_button.text == "探索を開始", "Title START button is Japanese")
        _check(stage_label != null and stage_label.text.contains("トロピカル遺跡パーク"), "Title stage label is Japanese")
        title.queue_free()
        await get_tree().process_frame

    var packed := load("res://scenes/stage1/stage1.tscn") as PackedScene
    _check(packed != null, "Stage 1 scene loads for v0.4.1 QA")
    if packed == null:
        _finish()
        return
    var stage := packed.instantiate()
    add_child(stage)
    await get_tree().process_frame
    await get_tree().process_frame

    var hud := stage.get_node_or_null("UI/MobileHUD") as MobileHUD
    _check(hud != null, "Mobile HUD exists")
    if hud != null:
        var field_button := hud.get_node_or_null("FieldLogButton") as Button
        _check(field_button != null and field_button.text == "フィールドログ", "Field Log button is Japanese")
        var jump_button := hud.get_node_or_null("Actions/Jump") as Button
        var net_button := hud.get_node_or_null("Actions/Net") as Button
        _check(jump_button != null and jump_button.text == "ジャンプ", "Jump button is Japanese")
        _check(net_button != null and net_button.text == "捕獲ネット", "HEX NET button is Japanese")

    var shrines := get_tree().get_nodes_in_group("secret_shrine")
    _check(shrines.size() == 1, "Stage 1 exposes one secret resonance shrine")
    if shrines.is_empty():
        _finish()
        return
    var shrine := shrines[0] as SecretShrine
    _check(not shrine.is_available, "Secret shrine starts hidden before Cartographer unlock")
    _check(not SaveManager.has_unlock(&"hex_resonance"), "HEX resonance starts locked")

    var relics := get_tree().get_nodes_in_group("field_relic")
    _check(relics.size() == 6, "Stage 1 has six field relics")
    for node in relics:
        var relic := node as FieldRelic
        if relic != null:
            relic.collect()
    await get_tree().process_frame
    await get_tree().process_frame
    _check(SaveManager.has_unlock(&"ruins_cartographer"), "Six relics unlock Ruins Cartographer")
    _check(shrine.is_available, "Ruins Cartographer reveals secret shrine")

    var pulses := get_tree().get_nodes_in_group("pulse_disc")
    _check(pulses.size() == 1, "One PULSE DISC is available")
    if not pulses.is_empty():
        var pulse := pulses[0] as PulseDisc
        pulse.debug_fire_at(shrine.global_position)
        await get_tree().process_frame
        await get_tree().process_frame
    _check(SaveManager.has_unlock(&"hex_resonance"), "Secret shrine unlocks HEX resonance permanently")
    _check(shrine.is_awakened, "Secret shrine reports awakened state")

    var nets := get_tree().get_nodes_in_group("hex_net")
    _check(nets.size() == 1, "One HEX NET is available")
    if not nets.is_empty():
        var net := nets[0] as HexNet
        net.refresh_persistent_upgrade()
        _check(net.is_resonance_upgraded(), "HEX NET applies persistent resonance upgrade")
        _check(net.get_step_three_reach() >= 4.05, "HEX resonance extends third swing reach")
        _check(net.combo_reset_seconds >= 0.96, "HEX resonance extends combo input window")

    if hud != null:
        hud.toggle_field_log()
        await get_tree().process_frame
        var field_panel := hud.get_node_or_null("FieldLogPanel") as PanelContainer
        _check(field_panel != null and field_panel.visible, "Japanese Field Log opens")
        var field_label := field_panel.find_child("Label", true, false) as Label if field_panel != null else null
        if field_label == null and field_panel != null:
            field_label = field_panel.find_child("*", true, false) as Label
        _check(hud.get_node_or_null("FieldLogButton") != null, "Field Log modal controls exist")
        hud.toggle_field_log()

    _finish()

func _check(condition: bool, label: String) -> void:
    if condition:
        print("[V041_QA][PASS] ", label)
    else:
        _failures.append(label)
        push_error("[V041_QA][FAIL] %s" % label)

func _finish() -> void:
    if _failures.is_empty():
        print("[V041_QA] PASS")
        get_tree().quit(0)
    else:
        print("[V041_QA] FAILURES: ", _failures.size())
        for failure in _failures:
            print("  - ", failure)
        get_tree().quit(1)
