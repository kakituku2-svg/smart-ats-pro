extends Node

var _failures: Array[String] = []
var _drone_payloads: Array = []

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_run")

func _run() -> void:
    print("[RUNTIME_V044] start")

    var title_pack := load("res://scenes/ui/title_screen.tscn") as PackedScene
    _check(title_pack != null, "Title scene loads")
    if title_pack != null:
        var title := title_pack.instantiate()
        add_child(title)
        await _wait_frames(2)
        _check(title.get_node_or_null("FX") is TitleFX, "Title scene uses animated gadget FX")
        var start_button := title.get_node_or_null("Center/Card/Content/StartButton") as Button
        _check(start_button != null and start_button.text.contains("探索を開始"), "Title start button uses Japanese game presentation")
        title.queue_free()
        await _wait_frames(2)

    var stage_pack := load("res://scenes/stage1/stage1.tscn") as PackedScene
    _check(stage_pack != null, "Stage 1 loads for UI QA")
    if stage_pack == null:
        _finish()
        return
    var stage := stage_pack.instantiate()
    add_child(stage)
    await _wait_frames(5)

    var hud := stage.get_node_or_null("UI/MobileHUD") as MobileHUD
    _check(hud != null, "Mobile HUD exists")
    if hud == null:
        _finish()
        return

    var icon_paths := {
        "GadgetBar/Row/Lure": "lure",
        "GadgetBar/Row/Pulse": "pulse",
        "GadgetBar/Row/Drone": "drone",
        "Actions/Jump": "jump",
        "Actions/Dash": "dash",
        "Actions/Net": "net",
        "Actions/Scan": "scan",
    }
    for path in icon_paths.keys():
        var button := hud.get_node_or_null(path) as GameIconButton
        _check(button != null, "%s is a GameIconButton" % path)
        if button != null:
            _check(String(button.icon_kind) == String(icon_paths[path]), "%s uses correct icon kind" % path)
            _check(button.get_theme_color("font_color").a <= 0.01, "%s hides persistent weapon/action text" % path)

    _check(not (hud.get_node("GadgetBar") is PanelContainer), "Gadget shortcut dock has no large background panel")
    _check(stage.find_child("*Radar*", true, false) == null, "No radar node exists")
    _check(stage.find_child("*Minimap*", true, false) == null, "No minimap node exists")

    var log_button := hud.get_node_or_null("FieldLogButton") as Button
    _check(log_button != null, "Field Log button exists")
    if log_button != null:
        _check(log_button.position.x >= 740.0 and log_button.position.x <= 920.0, "Field Log stays outside gadget dock")

    var player := get_tree().get_first_node_in_group("player") as PlayerController
    var mimos := get_tree().get_nodes_in_group("mimo")
    var drone := get_tree().get_first_node_in_group("scout_drone") as ScoutDrone
    _check(player != null and not mimos.is_empty() and drone != null, "Player, Mimo and drone exist")
    if player != null and not mimos.is_empty() and drone != null:
        var mimo := mimos[0] as MimoBase
        mimo.global_position = player.global_position + Vector3(2.0, 0.0, -2.0)
        drone.intel_ready.connect(_on_drone_intel, CONNECT_ONE_SHOT)
        var revealed := drone.launch(player)
        _check(revealed >= 1, "Drone reveals at least one nearby Mimo")
        await _wait_frames(3)
        _check(not _drone_payloads.is_empty(), "Drone intel payload is emitted")
        if not _drone_payloads.is_empty():
            _check((_drone_payloads[0] as Dictionary).has("world_position"), "Drone payload carries world position")
        var marker := stage.find_child("DroneTargetMarker", true, false)
        _check(marker != null, "Drone creates temporary world-space target marker")
        var scan_panel := hud.get_node_or_null("ScanPanel") as PanelContainer
        _check(scan_panel != null and not scan_panel.visible, "Drone does not open large SCAN/radar information panel")

    _finish()

func _on_drone_intel(payloads: Array) -> void:
    _drone_payloads = payloads.duplicate(true)

func _wait_frames(count: int) -> void:
    for _i in range(count):
        await get_tree().process_frame

func _check(condition: bool, label: String) -> void:
    if condition:
        print("[RUNTIME_V044][PASS] ", label)
    else:
        _failures.append(label)
        push_error("[RUNTIME_V044][FAIL] %s" % label)

func _finish() -> void:
    get_tree().paused = false
    if _failures.is_empty():
        print("[RUNTIME_V044] PASS")
        get_tree().quit(0)
    else:
        print("[RUNTIME_V044] FAILURES: ", _failures.size())
        for failure in _failures:
            print("  - ", failure)
        get_tree().quit(1)
