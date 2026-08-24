extends Node3D

@onready var hud: MobileHUD = $UI/MobileHUD
@onready var scan: EchoScan = $EchoScan
@onready var net: HexNet = $HexNet

var lure_pod: LurePod
var pulse_disc: PulseDisc
var scout_drone: ScoutDrone
var pulse_switch: PulseSwitch
var secret_shrine: SecretShrine
var capture_feedback: CaptureFeedback
var signature_director: SignatureActionDirector
var drone_feedback: DroneRevealFeedback

func _ready() -> void:
    GameState.reset_stage_progress(&"stage1", 6, 6)
    _install_gadgets_and_gimmicks()
    _build_box_garden_traversal()
    _build_mimo_escape_routes()
    _install_field_relics()

    GameState.capture_count_changed.connect(_on_capture_count_changed)
    GameState.relic_count_changed.connect(_on_relic_count_changed)
    GameState.stage_cleared.connect(_on_stage_cleared)
    scan.scan_result.connect(_on_scan_result)
    scan.scan_empty.connect(hud.show_scan_empty)
    net.net_contact.connect(_on_net_contact)
    net.net_miss.connect(_on_net_miss)
    lure_pod.pod_deployed.connect(_on_lure_deployed)
    pulse_disc.pulse_fired.connect(_on_pulse_fired)
    scout_drone.intel_ready.connect(_on_drone_intel)
    pulse_switch.opened.connect(_on_pulse_gate_opened)
    secret_shrine.shrine_awakened.connect(_on_secret_shrine_awakened)
    signature_director.signature_action.connect(_on_signature_action)

    for node in get_tree().get_nodes_in_group("mimo"):
        var mimo := node as MimoBase
        if mimo != null:
            mimo.state_changed.connect(_on_mimo_state_changed)

    var player := get_tree().get_first_node_in_group("player") as PlayerController
    if player != null:
        player.status_effect_changed.connect(hud.show_player_status)

    hud.replay_requested.connect(_on_replay_requested)
    hud.title_requested.connect(_on_title_requested)
    hud.lure_requested.connect(_use_lure_pod)
    hud.pulse_requested.connect(_use_pulse_disc)
    hud.drone_requested.connect(_use_scout_drone)
    hud.update_capture(GameState.get_capture_count(), GameState.stage_target_total)
    hud.update_relic(GameState.get_relic_count(), GameState.stage_relic_total)

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("lure"):
        _use_lure_pod()
    elif event.is_action_pressed("pulse"):
        _use_pulse_disc()
    elif event.is_action_pressed("drone"):
        _use_scout_drone()

func _install_gadgets_and_gimmicks() -> void:
    lure_pod = LurePod.new()
    lure_pod.name = "LurePod"
    add_child(lure_pod)

    pulse_disc = PulseDisc.new()
    pulse_disc.name = "PulseDisc"
    add_child(pulse_disc)

    scout_drone = ScoutDrone.new()
    scout_drone.name = "ScoutDrone"
    add_child(scout_drone)

    drone_feedback = DroneRevealFeedback.new()
    drone_feedback.name = "DroneRevealFeedback"
    add_child(drone_feedback)

    pulse_switch = PulseSwitch.new()
    pulse_switch.name = "RuinsPulseGate"
    add_child(pulse_switch)
    pulse_switch.global_position = Vector3(-9.0, 0.25, -8.5)

    secret_shrine = SecretShrine.new()
    secret_shrine.name = "SecretResonanceShrine"
    add_child(secret_shrine)
    secret_shrine.global_position = Vector3(21.0, 0.30, -21.0)

    capture_feedback = CaptureFeedback.new()
    capture_feedback.name = "CaptureFeedback"
    add_child(capture_feedback)

    signature_director = SignatureActionDirector.new()
    signature_director.name = "SignatureActionDirector"
    add_child(signature_director)

func _build_box_garden_traversal() -> void:
    var layer := Node3D.new()
    layer.name = "TraversalLayer"
    add_child(layer)

    _add_platform(layer, "LowerTerrace", Vector3(-1.5, 0.72, -13.5), Vector3(10.0, 1.15, 6.5), Color(0.26, 0.33, 0.29, 1.0))
    _add_platform(layer, "UpperTerrace", Vector3(8.5, 1.25, -10.5), Vector3(6.8, 2.2, 5.2), Color(0.31, 0.37, 0.32, 1.0))
    _add_platform(layer, "ForestLedge", Vector3(-17.0, 0.95, -10.5), Vector3(6.5, 1.55, 4.2), Color(0.18, 0.34, 0.22, 1.0))
    _add_platform(layer, "WaterBridge", Vector3(12.0, 0.58, 14.0), Vector3(9.0, 0.55, 1.8), Color(0.38, 0.27, 0.13, 1.0))
    _add_platform(layer, "SecretShrineLedge", Vector3(21.0, 0.70, -21.0), Vector3(5.5, 1.0, 5.0), Color(0.22, 0.31, 0.29, 1.0))
    _add_platform(layer, "SecretShrineStep", Vector3(17.0, 0.42, -18.0), Vector3(2.4, 0.35, 2.4), Color(0.30, 0.38, 0.34, 1.0))

    _add_ramp(layer, "TerraceRamp", Vector3(-1.5, 0.50, -9.2), Vector3(4.2, 0.55, 6.8), Vector3(-10.0, 0.0, 0.0), Color(0.39, 0.35, 0.25, 1.0))
    _add_ramp(layer, "ObservationRamp", Vector3(8.4, 0.82, -6.8), Vector3(3.4, 0.55, 6.0), Vector3(-15.0, 0.0, 0.0), Color(0.34, 0.31, 0.23, 1.0))

    for i in range(4):
        _add_platform(
            layer,
            "WaterStep%d" % (i + 1),
            Vector3(6.5 + float(i) * 2.0, 0.42 + float(i % 2) * 0.10, 17.0),
            Vector3(1.35, 0.32, 1.35),
            Color(0.34, 0.40, 0.37, 1.0)
        )

func _build_mimo_escape_routes() -> void:
    var routes := Node3D.new()
    routes.name = "MimoEscapeRoutes"
    add_child(routes)
    var route_data := {
        &"lumi": [[Vector3(-16, 0.4, 9), &"grass"], [Vector3(-20, 0.4, 3), &"brush"], [Vector3(-12, 0.4, 4), &"clearing"]],
        &"goro": [[Vector3(17, 0.5, 9), &"ravine"], [Vector3(13, 0.8, 4), &"rock_loop"], [Vector3(7, 0.5, 8), &"open_turn"]],
        &"boka": [[Vector3(-9, 0.5, -8), &"gate"], [Vector3(-2, 1.3, -13), &"terrace"], [Vector3(-15, 0.5, -2), &"ruins"]],
        &"nera": [[Vector3(10, 2.5, -11), &"upper_terrace"], [Vector3(15, 2.2, -15), &"watch_point"], [Vector3(7, 1.2, -8), &"ramp"]],
        &"moku": [[Vector3(-18, 1.4, -11), &"forest_ledge"], [Vector3(-22, 0.5, -16), &"deep_forest"], [Vector3(-13, 0.5, -18), &"moss_path"]],
        &"raku": [[Vector3(8, 0.6, 17), &"water_steps"], [Vector3(15, 0.6, 15), &"water_bridge"], [Vector3(18, 0.5, 20), &"far_bank"]],
    }
    for mimo_id in route_data.keys():
        var points: Array = route_data[mimo_id]
        for i in range(points.size()):
            var entry: Array = points[i]
            var marker := Marker3D.new()
            marker.name = "%sRoute%d" % [String(mimo_id).capitalize(), i + 1]
            marker.position = entry[0] as Vector3
            marker.set_meta("target_mimo", mimo_id)
            marker.set_meta("anchor_kind", entry[1])
            marker.add_to_group("mimo_escape_anchor")
            routes.add_child(marker)

func _install_field_relics() -> void:
    var root := Node3D.new()
    root.name = "FieldRelics"
    add_child(root)
    var relic_data := [
        [&"sun_disc", "太陽の円盤", Vector3(-18.5, 1.85, -10.5), Color(1.0, 0.72, 0.18, 1.0)],
        [&"gate_tablet", "門の石板", Vector3(-9.0, 0.9, -10.5), Color(0.32, 0.86, 1.0, 1.0)],
        [&"river_pearl", "水路の真珠", Vector3(10.5, 1.0, 17.0), Color(0.28, 0.92, 0.95, 1.0)],
        [&"watch_eye", "観測者の瞳", Vector3(13.5, 4.0, -12.0), Color(0.72, 0.52, 1.0, 1.0)],
        [&"moss_seal", "苔の封印", Vector3(-2.0, 2.1, -13.5), Color(0.42, 0.92, 0.38, 1.0)],
        [&"far_bank_coin", "対岸の古銭", Vector3(18.0, 0.9, 20.0), Color(1.0, 0.45, 0.28, 1.0)],
    ]
    for item in relic_data:
        var relic := FieldRelic.new()
        relic.relic_id = item[0] as StringName
        relic.display_name = String(item[1])
        relic.position = item[2] as Vector3
        relic.accent_color = item[3] as Color
        relic.collected.connect(_on_relic_collected)
        root.add_child(relic)

func _add_platform(parent: Node3D, node_name: String, position: Vector3, size: Vector3, color: Color) -> StaticBody3D:
    var body := StaticBody3D.new()
    body.name = node_name
    body.position = position
    parent.add_child(body)

    var mesh_instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    mesh_instance.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.96
    mesh_instance.material_override = material
    body.add_child(mesh_instance)

    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)
    return body

func _add_ramp(parent: Node3D, node_name: String, position: Vector3, size: Vector3, rotation_degrees_value: Vector3, color: Color) -> StaticBody3D:
    var body := _add_platform(parent, node_name, position, size, color)
    body.rotation_degrees = rotation_degrees_value
    return body

func _use_lure_pod() -> void:
    var player := get_tree().get_first_node_in_group("player") as Node3D
    var affected := lure_pod.deploy(player)
    if affected < 0:
        hud.show_toast("誘導ポッド  •  再使用まで待ってください")
    else:
        hud.show_toast("誘導ポッド設置  •  %d体のミモが反応" % affected)
        hud.show_gadget_status("誘導フィールド作動中  •  逃走ルートから引き離して待ち伏せ")

func _use_pulse_disc() -> void:
    var player := get_tree().get_first_node_in_group("player") as Node3D
    var result := pulse_disc.fire(player)
    if result < 0:
        hud.show_toast("パルスディスク  •  再使用まで待ってください")
    else:
        hud.show_toast("パルスディスク投擲  •  ミモをスタン / 青い遺跡装置を起動")

func _use_scout_drone() -> void:
    var player := get_tree().get_first_node_in_group("player") as Node3D
    var revealed := scout_drone.launch(player)
    if revealed < 0:
        hud.show_toast("偵察ドローン  •  再使用まで待ってください")
    else:
        hud.show_toast("偵察ドローン  •  %d体を短時間マーキング" % revealed)

func _on_capture_count_changed(current: int, total: int, mimo_id: StringName) -> void:
    hud.update_capture(current, total)
    if mimo_id != &"":
        hud.show_toast("%sを捕獲！  •  %d/%d" % [JapaneseText.mimo_name(mimo_id, String(mimo_id)), current, total])

func _on_relic_count_changed(current: int, total: int, relic_id: StringName) -> void:
    hud.update_relic(current, total)
    if relic_id != &"":
        hud.show_toast("古代遺物を発見  •  %s  •  %d/%d" % [JapaneseText.relic_name(relic_id), current, total])

func _on_relic_collected(_relic: FieldRelic) -> void:
    hud.show_gadget_status("フィールドログ更新  •  高台・水路・隠しルートも探索しよう")

func _on_stage_cleared(stage_id: StringName) -> void:
    if stage_id == &"stage1":
        hud.show_stage_clear()

func _on_scan_result(payload: Dictionary) -> void:
    hud.show_scan(payload)
    hud.show_gadget_status(_strategy_for(payload))

func _strategy_for(payload: Dictionary) -> String:
    match StringName(payload.get("behavior", "runner")):
        &"timid":
            return "攻略  •  誘導ポッド → 広場へ誘い出す → 捕獲ネット"
        &"zigzag":
            return "攻略  •  パルスで横逃げを止めて距離を詰める"
        &"challenger":
            return "攻略  •  狭い遺跡から誘い出し、2段目の広い捕獲ネット"
        &"sentinel":
            return "攻略  •  ドローンで高台の本体を短時間マーキング → 加速の切れ目にパルス"
        &"sleepy":
            return "攻略  •  完全に起きる前は誘導ポッドが特に有効"
        &"trickster":
            return "攻略  •  ドローンで本物を短時間マーキング → 分身を無視してパルス"
    return "攻略  •  スキャンで逃走ルートを読み、先回りしよう"

func _on_net_contact(mimo: MimoBase, captured_now: bool, step: int) -> void:
    if captured_now:
        capture_feedback.play_capture(mimo.global_position, mimo.accent_color)
        var player := get_tree().get_first_node_in_group("player") as PlayerController
        if player != null:
            player.add_camera_impulse(Vector2(10.0, -6.0))
        hud.show_toast("捕獲ネット %d段目  •  捕獲成功！ %s" % [step, JapaneseText.mimo_name(mimo.mimo_id, mimo.display_name)])
    else:
        var pressure_pct := int(round(mimo.get_pressure() * 100.0))
        hud.show_toast("捕獲ネット %d段目  •  逃げられた  •  プレッシャー %d%%" % [step, pressure_pct])

func _on_net_miss(step: int) -> void:
    hud.show_toast("捕獲ネット %d段目  •  空振り" % step)

func _on_mimo_state_changed(mimo: MimoBase, next_state: MimoBase.State) -> void:
    if next_state == MimoBase.State.FATIGUED:
        hud.show_capture_window(JapaneseText.mimo_name(mimo.mimo_id, mimo.display_name))

func _on_signature_action(mimo_id: StringName, action_name: StringName) -> void:
    var mimo_name := JapaneseText.mimo_name(mimo_id, String(mimo_id))
    match action_name:
        &"grass_hide":
            hud.show_gadget_status("%sが草むらに隠れた！  •  スキャンか誘導ポッドで見つけよう" % mimo_name)
        &"stone_throw":
            hud.show_gadget_status("ゴロの投石！  •  動き続けるか、攻撃の隙にパルス")
        &"counter_charge":
            hud.show_gadget_status("ボカが突進！  •  横へ避けて捕獲ネットで反撃")
        &"spark_burst":
            hud.show_gadget_status("ネラの電撃！  •  離れるか、接近前にパルスで止める")
        &"sleep_cloud":
            hud.show_gadget_status("モクの眠気フィールド！  •  正面から突っ込まない")
        &"decoy_split":
            hud.show_gadget_status("ラクが分身！  •  ドローンで本物だけを短時間マーキング")

func _on_lure_deployed(_world_position: Vector3, affected_count: int) -> void:
    if affected_count == 0:
        hud.show_gadget_status("誘導フィールド作動中  •  まだ近くにミモはいません")

func _on_pulse_fired(world_position: Vector3, affected_count: int) -> void:
    capture_feedback.play_pulse_hit(world_position)
    if affected_count > 0:
        hud.show_toast("パルス命中  •  %d体のミモがひるんだ" % affected_count)
        hud.show_gadget_status("パルス命中  •  回復する前に距離を詰めよう")

func _on_drone_intel(payloads: Array) -> void:
    if payloads.is_empty():
        hud.show_toast("偵察ドローン  •  近くに反応なし")
        return
    drone_feedback.reveal(payloads)
    hud.show_toast("偵察ドローン  •  %d体を短時間マーキング" % payloads.size())

func _on_pulse_gate_opened() -> void:
    hud.show_toast("遺跡ゲート開放  •  新しい追跡ルートが使えるようになった")
    hud.show_gadget_status("ショートカット開通  •  パルスでステージ地形が変化")

func _on_secret_shrine_awakened(reward_id: StringName) -> void:
    if reward_id != &"hex_resonance":
        return
    net.refresh_persistent_upgrade()
    hud.show_toast("隠し遺跡が共鳴！  •  HEX共鳴を獲得")
    hud.show_gadget_status("捕獲ネット永久強化  •  3段目の射程↑ / コンボ受付時間↑")

func _on_replay_requested() -> void:
    get_tree().reload_current_scene()

func _on_title_requested() -> void:
    get_tree().change_scene_to_file("res://scenes/ui/title_screen.tscn")
