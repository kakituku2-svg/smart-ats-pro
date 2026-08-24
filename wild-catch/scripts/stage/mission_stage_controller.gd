extends Node3D
class_name MissionStageController

@export var stage_id: StringName = &"stage2"
@export var theme_id: StringName = &"sky_canyon"
@export var target_total := 5
@export var relic_total := 4

var hud: MobileHUD
var net: HexNet
var scan: EchoScan
var lure_pod: LurePod
var pulse_disc: PulseDisc
var scout_drone: ScoutDrone
var drone_feedback: DroneRevealFeedback
var capture_feedback: CaptureFeedback

func _ready() -> void:
    var mission := MissionRouter.get_mission(stage_id)
    target_total = int(mission.get("target_total", target_total))
    relic_total = int(mission.get("relic_total", relic_total))
    GameState.reset_stage_progress(stage_id, target_total, relic_total)
    _build_environment()
    _spawn_player_and_tools()
    _spawn_targets()
    _spawn_relics()
    _connect_runtime()

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("lure"):
        _use_lure()
    elif event.is_action_pressed("pulse"):
        _use_pulse()
    elif event.is_action_pressed("drone"):
        _use_drone()

func _build_environment() -> void:
    var world := WorldEnvironment.new()
    world.name = "WorldEnvironment"
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    if theme_id == &"sky_canyon":
        env.background_color = Color(0.22, 0.55, 0.78, 1.0)
        env.ambient_light_color = Color(0.62, 0.72, 0.72, 1.0)
        env.fog_light_color = Color(0.72, 0.82, 0.86, 1.0)
        env.fog_density = 0.008
    else:
        env.background_color = Color(0.035, 0.06, 0.12, 1.0)
        env.ambient_light_color = Color(0.25, 0.32, 0.42, 1.0)
        env.fog_light_color = Color(0.14, 0.18, 0.28, 1.0)
        env.fog_density = 0.024
    env.ambient_light_energy = 0.82
    env.fog_enabled = true
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    world.environment = env
    add_child(world)

    var light := DirectionalLight3D.new()
    light.name = "DirectionalLight3D"
    light.rotation_degrees = Vector3(-48, -32, 0)
    light.light_energy = 1.32 if theme_id == &"sky_canyon" else 0.72
    light.light_color = Color(1.0, 0.93, 0.76, 1.0) if theme_id == &"sky_canyon" else Color(0.48, 0.58, 1.0, 1.0)
    light.shadow_enabled = true
    add_child(light)

    var ground_color := Color(0.36, 0.31, 0.22, 1.0) if theme_id == &"sky_canyon" else Color(0.07, 0.18, 0.15, 1.0)
    _add_static_box(self, "Ground", Vector3(0, -0.25, 0), Vector3(62, 0.5, 62), ground_color)

    if theme_id == &"sky_canyon":
        _build_sky_canyon()
    else:
        _build_neon_swamp()

func _build_sky_canyon() -> void:
    var stone := Color(0.48, 0.42, 0.31, 1.0)
    var wood := Color(0.35, 0.22, 0.11, 1.0)
    _add_static_box(self, "NorthCliff", Vector3(-12, 1.4, -14), Vector3(13, 2.8, 8), stone)
    _add_static_box(self, "EastShelf", Vector3(13, 1.0, -8), Vector3(10, 2.0, 8), stone.lightened(0.05))
    _add_static_box(self, "WindBridge", Vector3(2, 1.0, -10), Vector3(14, 0.55, 2.0), wood)
    _add_static_box(self, "SouthRise", Vector3(12, 0.7, 13), Vector3(9, 1.4, 9), stone.darkened(0.06))
    for i in range(6):
        var x := -18.0 + float(i) * 7.2
        _add_wind_turbine(Vector3(x, 1.6 + float(i % 2) * 0.7, 5.5 - float(i % 3) * 3.0), i)
    for i in range(18):
        var angle := TAU * float(i) / 18.0
        var radius := 19.0 + float(i % 4)
        _add_decor_rock(Vector3(sin(angle) * radius, 0.35, cos(angle) * radius), 0.65 + float(i % 3) * 0.18, stone)

func _build_neon_swamp() -> void:
    var ruin := Color(0.17, 0.23, 0.27, 1.0)
    var path := Color(0.10, 0.26, 0.20, 1.0)
    _add_static_box(self, "ResearchDeck", Vector3(0, 0.35, -10), Vector3(16, 0.7, 8), ruin)
    _add_static_box(self, "WestLab", Vector3(-15, 1.2, 1), Vector3(8, 2.4, 10), ruin.darkened(0.04))
    _add_static_box(self, "EastLab", Vector3(15, 0.9, 4), Vector3(7, 1.8, 9), ruin.lightened(0.03))
    _add_static_box(self, "RaisedPath", Vector3(0, 0.32, 7), Vector3(5, 0.64, 20), path)
    _add_water_patch(Vector3(-7, 0.05, 9), Vector3(9, 0.12, 10))
    _add_water_patch(Vector3(8, 0.05, 14), Vector3(10, 0.12, 8))
    for i in range(30):
        var x := -23.0 + float((i * 7) % 46)
        var z := -20.0 + float((i * 11) % 42)
        var hue := [Color(0.28, 1.0, 0.68, 1.0), Color(0.58, 0.38, 1.0, 1.0), Color(1.0, 0.34, 0.76, 1.0)][i % 3]
        _add_glow_plant(Vector3(x, 0.25, z), hue, 0.7 + float(i % 4) * 0.12)

func _spawn_player_and_tools() -> void:
    var player_scene := load("res://scenes/player/player.tscn") as PackedScene
    var player := player_scene.instantiate() as PlayerController
    player.name = "Player"
    player.position = Vector3(0, 0.35, 14)
    add_child(player)

    var net_scene := load("res://scenes/gadgets/hex_net.tscn") as PackedScene
    net = net_scene.instantiate() as HexNet
    net.name = "HexNet"
    add_child(net)
    var scan_scene := load("res://scenes/gadgets/echo_scan.tscn") as PackedScene
    scan = scan_scene.instantiate() as EchoScan
    scan.name = "EchoScan"
    add_child(scan)
    var hud_scene := load("res://scenes/ui/mobile_hud.tscn") as PackedScene
    hud = hud_scene.instantiate() as MobileHUD
    var canvas := CanvasLayer.new()
    canvas.name = "UI"
    add_child(canvas)
    canvas.add_child(hud)

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
    capture_feedback = CaptureFeedback.new()
    capture_feedback.name = "CaptureFeedback"
    add_child(capture_feedback)

func _spawn_targets() -> void:
    var configs := _target_configs()
    var scene := load("res://scenes/mimo/mimo.tscn") as PackedScene
    var root := Node3D.new()
    root.name = "MissionTargets"
    add_child(root)
    for i in range(mini(target_total, configs.size())):
        var config: Dictionary = configs[i]
        var mimo := scene.instantiate() as MimoBase
        mimo.name = String(config["name"])
        mimo.mimo_id = StringName(config["id"])
        mimo.display_name = String(config["name"])
        mimo.personality = String(config["personality"])
        mimo.area_name = String(config["area"])
        mimo.capture_hint = String(config["hint"])
        mimo.behavior_profile = StringName(config["profile"])
        mimo.accent_color = config["color"] as Color
        mimo.position = config["position"] as Vector3
        mimo.move_speed = float(config.get("move_speed", 2.3))
        mimo.panic_speed = float(config.get("panic_speed", 6.0))
        root.add_child(mimo)

func _spawn_relics() -> void:
    var root := Node3D.new()
    root.name = "FieldRelics"
    add_child(root)
    var positions := _relic_positions()
    for i in range(mini(relic_total, positions.size())):
        var relic := FieldRelic.new()
        relic.relic_id = StringName("%s_relic_%02d" % [String(stage_id), i + 1])
        relic.display_name = "探索記録 %02d" % (i + 1)
        relic.position = positions[i] as Vector3
        relic.accent_color = Color(0.45, 0.90, 1.0, 1.0) if theme_id == &"sky_canyon" else Color(0.78, 0.42, 1.0, 1.0)
        root.add_child(relic)

func _connect_runtime() -> void:
    GameState.capture_count_changed.connect(_on_capture_count_changed)
    GameState.relic_count_changed.connect(_on_relic_count_changed)
    GameState.stage_cleared.connect(_on_stage_cleared)
    scan.scan_result.connect(hud.show_scan)
    scan.scan_empty.connect(hud.show_scan_empty)
    net.net_contact.connect(_on_net_contact)
    net.net_miss.connect(func(step: int) -> void: hud.show_toast("捕獲ネット %d段目  •  空振り" % step))
    scout_drone.intel_ready.connect(_on_drone_intel)
    hud.lure_requested.connect(_use_lure)
    hud.pulse_requested.connect(_use_pulse)
    hud.drone_requested.connect(_use_drone)
    hud.replay_requested.connect(func() -> void: get_tree().reload_current_scene())
    hud.title_requested.connect(func() -> void: MissionRouter.return_to_hub(stage_id))
    var player := get_tree().get_first_node_in_group("player") as PlayerController
    if player != null:
        player.status_effect_changed.connect(hud.show_player_status)
    for node in get_tree().get_nodes_in_group("mimo"):
        var mimo := node as MimoBase
        if mimo != null:
            mimo.state_changed.connect(_on_mimo_state_changed)
    hud.update_capture(0, target_total)
    hud.update_relic(0, relic_total)

func _use_lure() -> void:
    var player := get_tree().get_first_node_in_group("player") as Node3D
    var affected := lure_pod.deploy(player)
    if affected < 0:
        hud.show_toast("誘導ポッド  •  再使用まで待ってください")
    else:
        hud.show_toast("誘導ポッド  •  %d体が反応" % affected)

func _use_pulse() -> void:
    var player := get_tree().get_first_node_in_group("player") as Node3D
    var result := pulse_disc.fire(player)
    if result < 0:
        hud.show_toast("パルスディスク  •  再使用まで待ってください")
    else:
        hud.show_toast("パルス発射  •  ミモと妨害体に有効")

func _use_drone() -> void:
    var player := get_tree().get_first_node_in_group("player") as Node3D
    var revealed := scout_drone.launch(player)
    if revealed < 0:
        hud.show_toast("偵察ドローン  •  再使用まで待ってください")

func _on_capture_count_changed(current: int, total: int, mimo_id_value: StringName) -> void:
    hud.update_capture(current, total)
    if mimo_id_value != &"":
        hud.show_toast("%sを捕獲！  •  %d/%d" % [JapaneseText.mimo_name(mimo_id_value, String(mimo_id_value)), current, total])

func _on_relic_count_changed(current: int, total: int, relic_id: StringName) -> void:
    hud.update_relic(current, total)
    if relic_id != &"":
        hud.show_toast("探索記録を発見  •  %d/%d" % [current, total])

func _on_stage_cleared(cleared_id: StringName) -> void:
    if cleared_id == stage_id:
        hud.show_stage_clear()

func _on_net_contact(mimo: MimoBase, captured_now: bool, step: int) -> void:
    if captured_now:
        capture_feedback.play_capture(mimo.global_position, mimo.accent_color)
        hud.show_toast("捕獲成功！  •  %s" % mimo.display_name)
    else:
        hud.show_toast("捕獲ネット %d段目  •  まだ元気だ" % step)

func _on_mimo_state_changed(mimo: MimoBase, next_state: MimoBase.State) -> void:
    if next_state == MimoBase.State.FATIGUED:
        hud.show_capture_window(mimo.display_name)

func _on_drone_intel(payloads: Array) -> void:
    if payloads.is_empty():
        hud.show_toast("偵察ドローン  •  反応なし")
        return
    drone_feedback.reveal(payloads)
    hud.show_toast("偵察ドローン  •  %d体を短時間マーキング" % payloads.size())

func _target_configs() -> Array[Dictionary]:
    if theme_id == &"sky_canyon":
        return [
            _target("aero", "アエロ", "風を読む", "風車高台", "強風の切れ目に追い込む", &"zigzag", Color(0.28, 0.78, 1.0, 1.0), Vector3(-13, 3.0, -14)),
            _target("kuru", "クル", "落ち着きがない", "風橋", "橋の出口で待ち伏せ", &"trickster", Color(1.0, 0.68, 0.22, 1.0), Vector3(1, 1.5, -10)),
            _target("vivi", "ビビ", "臆病", "西側崖", "誘導ポッドで広場へ出す", &"timid", Color(0.45, 1.0, 0.58, 1.0), Vector3(-18, 0.5, 5)),
            _target("toto", "トト", "勝負好き", "東棚", "突進後の隙を狙う", &"challenger", Color(1.0, 0.38, 0.26, 1.0), Vector3(14, 2.2, -8)),
            _target("nagi", "ナギ", "高所好き", "南丘", "ドローンで高所位置を確認", &"sentinel", Color(0.62, 0.50, 1.0, 1.0), Vector3(12, 1.6, 13)),
        ]
    return [
        _target("pico", "ピコ", "発光好き", "研究デッキ", "光る床から追い出す", &"zigzag", Color(0.25, 1.0, 0.78, 1.0), Vector3(0, 1.0, -10)),
        _target("luna", "ルナ", "夜行性", "西研究棟", "暗所でドローンを使う", &"sentinel", Color(0.62, 0.42, 1.0, 1.0), Vector3(-15, 2.8, 1)),
        _target("doro", "ドロ", "泥遊び好き", "西湿地", "誘導ポッドで足場へ誘う", &"sleepy", Color(0.48, 0.76, 0.30, 1.0), Vector3(-8, 0.5, 10)),
        _target("nix", "ニクス", "警戒心が強い", "東研究棟", "パルスで逃走を止める", &"timid", Color(0.30, 0.70, 1.0, 1.0), Vector3(15, 2.0, 4)),
        _target("fufu", "フフ", "いたずら好き", "夜光林", "分岐で先回りする", &"trickster", Color(1.0, 0.38, 0.78, 1.0), Vector3(-16, 0.5, -14)),
        _target("zari", "ザリ", "攻撃的", "水路跡", "突進をかわして反撃", &"challenger", Color(1.0, 0.40, 0.24, 1.0), Vector3(10, 0.5, 15)),
        _target("ema", "エマ", "静か", "中央高架", "疲れるまで追跡する", &"runner", Color(0.92, 0.82, 0.32, 1.0), Vector3(0, 1.1, 6)),
    ]

func _target(id: String, name_value: String, personality_value: String, area: String, hint: String, profile: StringName, color: Color, position_value: Vector3) -> Dictionary:
    return {"id": id, "name": name_value, "personality": personality_value, "area": area, "hint": hint, "profile": profile, "color": color, "position": position_value}

func _relic_positions() -> Array[Vector3]:
    if theme_id == &"sky_canyon":
        return [Vector3(-16, 3.4, -14), Vector3(14, 2.5, -8), Vector3(12, 1.8, 13), Vector3(-20, 0.8, 16)]
    return [Vector3(-15, 3.0, 1), Vector3(15, 2.4, 4), Vector3(-7, 0.8, 9), Vector3(8, 0.8, 14), Vector3(0, 1.3, -10)]

func _add_static_box(parent: Node3D, node_name: String, pos: Vector3, size_value: Vector3, color: Color) -> StaticBody3D:
    var body := StaticBody3D.new()
    body.name = node_name
    body.position = pos
    parent.add_child(body)
    var mesh_instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size_value
    mesh_instance.mesh = mesh
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.94
    mesh_instance.material_override = mat
    body.add_child(mesh_instance)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size_value
    collision.shape = shape
    body.add_child(collision)
    return body

func _add_wind_turbine(pos: Vector3, index: int) -> void:
    var root := Node3D.new()
    root.name = "WindTurbine%02d" % index
    root.position = pos
    add_child(root)
    var mast := MeshInstance3D.new()
    var mast_mesh := CylinderMesh.new()
    mast_mesh.top_radius = 0.10
    mast_mesh.bottom_radius = 0.18
    mast_mesh.height = 3.2
    mast_mesh.radial_segments = 7
    mast.mesh = mast_mesh
    mast.position.y = 1.6
    mast.material_override = _simple_mat(Color(0.28, 0.32, 0.31, 1.0), false)
    root.add_child(mast)
    var hub := MeshInstance3D.new()
    var hub_mesh := SphereMesh.new()
    hub_mesh.radius = 0.22
    hub_mesh.height = 0.44
    hub.mesh = hub_mesh
    hub.position = Vector3(0, 3.15, 0)
    hub.material_override = _simple_mat(Color(0.24, 0.82, 1.0, 1.0), true)
    root.add_child(hub)
    for blade_i in range(4):
        var blade := MeshInstance3D.new()
        var blade_mesh := BoxMesh.new()
        blade_mesh.size = Vector3(0.12, 1.65, 0.07)
        blade.mesh = blade_mesh
        blade.position = Vector3(0, 3.15, 0)
        blade.rotation.z = TAU * float(blade_i) / 4.0
        blade.material_override = _simple_mat(Color(0.70, 0.82, 0.78, 1.0), false)
        root.add_child(blade)

func _add_decor_rock(pos: Vector3, scale_value: float, color: Color) -> void:
    var rock := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = 0.55
    mesh.height = 0.9
    mesh.radial_segments = 7
    mesh.rings = 4
    rock.mesh = mesh
    rock.position = pos
    rock.scale = Vector3(scale_value * 1.2, scale_value, scale_value)
    rock.material_override = _simple_mat(color, false)
    add_child(rock)

func _add_water_patch(pos: Vector3, size_value: Vector3) -> void:
    var water := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size_value
    water.mesh = mesh
    water.position = pos
    var mat := _simple_mat(Color(0.08, 0.28, 0.40, 0.68), true)
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    water.material_override = mat
    add_child(water)

func _add_glow_plant(pos: Vector3, color: Color, scale_value: float) -> void:
    var plant := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = 0.20
    mesh.height = 0.42
    mesh.radial_segments = 7
    mesh.rings = 4
    plant.mesh = mesh
    plant.position = pos
    plant.scale = Vector3(0.8, 1.7, 0.8) * scale_value
    plant.material_override = _simple_mat(color, true)
    add_child(plant)

func _simple_mat(color: Color, emissive: bool) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.84
    if emissive:
        mat.emission_enabled = true
        mat.emission = color
        mat.emission_energy_multiplier = 1.6
    return mat
