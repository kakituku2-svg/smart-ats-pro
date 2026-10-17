extends Node3D

var _portal_ring: MeshInstance3D
var _portal_core: MeshInstance3D
var _mission_panel: PanelContainer
var _selected_label: Label
var _launch_button: Button
var _time := 0.0

func _ready() -> void:
    AudioManager.play_music(&"hub")
    _build_base_environment()
    _build_portal()
    _spawn_player()
    _build_hub_ui()
    MissionRouter.select_mission(MissionRouter.get_pending_stage_id())
    _refresh_selection()
    if MissionRouter.returning_from_stage_id != &"":
        _show_return_notice(MissionRouter.returning_from_stage_id)
        MissionRouter.returning_from_stage_id = &""

func _process(delta: float) -> void:
    _time += delta
    if is_instance_valid(_portal_ring):
        _portal_ring.rotation.y = _time * 0.72
        _portal_ring.rotation.x = sin(_time * 0.62) * 0.08
    if is_instance_valid(_portal_core):
        var pulse := 0.92 + sin(_time * 2.4) * 0.06
        _portal_core.scale = Vector3.ONE * pulse

func _build_base_environment() -> void:
    var world := WorldEnvironment.new()
    world.name = "WorldEnvironment"
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.015, 0.055, 0.085, 1.0)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.28, 0.48, 0.62, 1.0)
    env.ambient_light_energy = 0.82
    env.fog_enabled = true
    env.fog_light_color = Color(0.05, 0.20, 0.28, 1.0)
    env.fog_density = 0.018
    world.environment = env
    add_child(world)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48, -28, 0)
    sun.light_color = Color(0.72, 0.88, 1.0, 1.0)
    sun.light_energy = 1.15
    sun.shadow_enabled = true
    add_child(sun)

    var floor := StaticBody3D.new()
    floor.name = "HubFloor"
    floor.position = Vector3(0, -0.2, 0)
    add_child(floor)
    var floor_mesh := MeshInstance3D.new()
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = 13.0
    cylinder.bottom_radius = 13.4
    cylinder.height = 0.4
    cylinder.radial_segments = 48
    floor_mesh.mesh = cylinder
    floor_mesh.material_override = _material(Color(0.055, 0.12, 0.15, 1.0), false, 0.72)
    floor.add_child(floor_mesh)
    var floor_collision := CollisionShape3D.new()
    var floor_shape := CylinderShape3D.new()
    floor_shape.radius = 13.0
    floor_shape.height = 0.4
    floor_collision.shape = floor_shape
    floor.add_child(floor_collision)

    for i in range(12):
        var marker := MeshInstance3D.new()
        marker.name = "FloorLight%02d" % i
        var box := BoxMesh.new()
        box.size = Vector3(0.18, 0.04, 2.0)
        marker.mesh = box
        marker.material_override = _material(Color(0.12, 0.76, 1.0, 1.0), true, 0.20)
        var angle := TAU * float(i) / 12.0
        marker.position = Vector3(sin(angle) * 9.4, 0.04, cos(angle) * 9.4)
        marker.rotation.y = angle
        add_child(marker)

func _build_portal() -> void:
    var root := Node3D.new()
    root.name = "TransferGate"
    root.position = Vector3(0, 2.6, -4.2)
    add_child(root)

    _portal_ring = MeshInstance3D.new()
    _portal_ring.name = "PortalRing"
    var torus := TorusMesh.new()
    torus.inner_radius = 1.55
    torus.outer_radius = 1.78
    torus.rings = 16
    torus.ring_segments = 36
    _portal_ring.mesh = torus
    _portal_ring.rotation_degrees = Vector3(90, 0, 0)
    _portal_ring.material_override = _material(Color(0.18, 0.94, 1.0, 1.0), true, 0.20)
    root.add_child(_portal_ring)

    _portal_core = MeshInstance3D.new()
    _portal_core.name = "PortalCore"
    var sphere := SphereMesh.new()
    sphere.radius = 1.42
    sphere.height = 2.84
    sphere.radial_segments = 24
    sphere.rings = 12
    _portal_core.mesh = sphere
    var core_mat := _material(Color(0.06, 0.54, 0.78, 0.36), true, 0.08)
    core_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    _portal_core.material_override = core_mat
    root.add_child(_portal_core)

    for side in [-1.0, 1.0]:
        var pillar := MeshInstance3D.new()
        var mesh := BoxMesh.new()
        mesh.size = Vector3(0.65, 4.8, 0.85)
        pillar.mesh = mesh
        pillar.position = Vector3(side * 2.15, -0.15, 0)
        pillar.material_override = _material(Color(0.08, 0.20, 0.24, 1.0), false, 0.58)
        root.add_child(pillar)

func _spawn_player() -> void:
    var packed := load("res://scenes/player/player.tscn") as PackedScene
    if packed == null:
        return
    var player := packed.instantiate() as PlayerController
    player.name = "Player"
    player.position = Vector3(0, 0.3, 5.4)
    add_child(player)

func _build_hub_ui() -> void:
    var canvas := CanvasLayer.new()
    canvas.name = "HubUI"
    canvas.layer = 20
    add_child(canvas)

    var title := Label.new()
    title.position = Vector2(28, 24)
    title.size = Vector2(570, 64)
    title.text = "WILD CATCH // FIELD BASE"
    GameUISkin.style_heading(title, Color(0.42, 1.0, 0.88, 1.0), 30)
    canvas.add_child(title)

    var hint := Label.new()
    hint.position = Vector2(30, 79)
    hint.size = Vector2(520, 42)
    hint.text = "中央転送ゲートから探索エリアへ出撃"
    GameUISkin.style_body(hint, 16)
    canvas.add_child(hint)

    _mission_panel = PanelContainer.new()
    _mission_panel.position = Vector2(800, 96)
    _mission_panel.size = Vector2(450, 540)
    GameUISkin.style_panel(_mission_panel, Color(0.32, 0.90, 1.0, 1.0))
    canvas.add_child(_mission_panel)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 24)
    margin.add_theme_constant_override("margin_top", 20)
    margin.add_theme_constant_override("margin_right", 24)
    margin.add_theme_constant_override("margin_bottom", 20)
    _mission_panel.add_child(margin)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 11)
    margin.add_child(column)

    var heading := Label.new()
    heading.text = "転送ミッション"
    GameUISkin.style_heading(heading, Color(0.48, 0.92, 1.0, 1.0), 27)
    column.add_child(heading)

    for stage_id in MissionRouter.get_mission_ids():
        var mission := MissionRouter.get_mission(stage_id)
        var button := Button.new()
        button.custom_minimum_size.y = 74
        button.text = "%s\n%s" % [String(mission.get("name", stage_id)), String(mission.get("objective", ""))]
        button.disabled = not MissionRouter.is_unlocked(stage_id)
        var accent := mission.get("accent", Color.WHITE) as Color
        GameUISkin.style_button(button, accent, 15)
        button.pressed.connect(_select_mission.bind(stage_id))
        if button.disabled:
            button.text = "LOCKED // %s" % String(mission.get("name", stage_id))
        column.add_child(button)

    _selected_label = Label.new()
    _selected_label.custom_minimum_size.y = 112
    _selected_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    GameUISkin.style_body(_selected_label, 15)
    column.add_child(_selected_label)

    _launch_button = Button.new()
    _launch_button.custom_minimum_size.y = 62
    _launch_button.text = "転送開始"
    GameUISkin.style_button(_launch_button, Color(0.40, 1.0, 0.64, 1.0), 21)
    _launch_button.pressed.connect(_launch_selected)
    column.add_child(_launch_button)

func _select_mission(stage_id: StringName) -> void:
    MissionRouter.select_mission(stage_id)
    AudioManager.play_event(&"scan")
    _refresh_selection()

func _refresh_selection() -> void:
    var stage_id := MissionRouter.get_pending_stage_id()
    var mission := MissionRouter.get_mission(stage_id)
    _selected_label.text = "%s\n%s\n妨害体：%d  /  遺物：%d" % [
        String(mission.get("subtitle", "")),
        String(mission.get("brief", "")),
        int(mission.get("interference_total", 0)),
        int(mission.get("relic_total", 0)),
    ]
    _launch_button.disabled = not MissionRouter.is_unlocked(stage_id)

func _launch_selected() -> void:
    if _launch_button.disabled:
        return
    AudioManager.stop_music()
    MissionRouter.launch_selected_mission()

func _show_return_notice(stage_id: StringName) -> void:
    var mission := MissionRouter.get_mission(stage_id)
    var canvas := get_node_or_null("HubUI") as CanvasLayer
    if canvas == null:
        return
    var banner := Label.new()
    banner.position = Vector2(370, 32)
    banner.size = Vector2(540, 70)
    banner.text = "RETURN COMPLETE // %s" % String(mission.get("name", stage_id))
    banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    GameUISkin.style_heading(banner, Color(1.0, 0.86, 0.34, 1.0), 22)
    canvas.add_child(banner)
    banner.modulate.a = 0.0
    var tween := create_tween()
    tween.tween_property(banner, "modulate:a", 1.0, 0.18)
    tween.tween_interval(2.2)
    tween.tween_property(banner, "modulate:a", 0.0, 0.35)
    tween.tween_callback(banner.queue_free)

func _material(color: Color, emissive: bool, roughness: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = roughness
    if emissive:
        material.emission_enabled = true
        material.emission = Color(color.r, color.g, color.b, 1.0) * 0.72
        material.emission_energy_multiplier = 1.8
    return material
