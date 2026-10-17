extends Node3D

const OUT_DIR := "res://build/screenshots"
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const MIMO_SCENE := preload("res://scenes/mimo/mimo.tscn")

var _subjects: Array[Node3D] = []

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_run")

func _run() -> void:
    var absolute_dir := ProjectSettings.globalize_path(OUT_DIR)
    var err := DirAccess.make_dir_recursive_absolute(absolute_dir)
    if err != OK and err != ERR_ALREADY_EXISTS:
        push_error("[CHARACTER_QA] cannot create screenshot directory")
        get_tree().quit(1)
        return

    _build_studio()
    await _wait_frames(12)
    await _save_viewport("19_character_lineup_front.png")

    for subject in _subjects:
        subject.rotation.y += PI
    await _wait_frames(5)
    await _save_viewport("20_character_lineup_back.png")

    print("[CHARACTER_QA] PASS — front/back character lineup saved")
    get_tree().quit(0)

func _build_studio() -> void:
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color(0.055, 0.105, 0.125, 1.0)
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.55, 0.68, 0.70, 1.0)
    environment.ambient_light_energy = 0.78
    var world := WorldEnvironment.new()
    world.environment = environment
    add_child(world)

    var key := DirectionalLight3D.new()
    key.rotation_degrees = Vector3(-48, -28, 0)
    key.light_color = Color(1.0, 0.91, 0.77, 1.0)
    key.light_energy = 1.7
    key.shadow_enabled = true
    add_child(key)

    var rim := DirectionalLight3D.new()
    rim.rotation_degrees = Vector3(-25, 145, 0)
    rim.light_color = Color(0.28, 0.75, 1.0, 1.0)
    rim.light_energy = 0.65
    add_child(rim)

    var floor_mesh := PlaneMesh.new()
    floor_mesh.size = Vector2(22, 7)
    var floor_material := StandardMaterial3D.new()
    floor_material.albedo_color = Color(0.10, 0.17, 0.18, 1.0)
    floor_material.roughness = 0.93
    floor_mesh.material = floor_material
    var floor := MeshInstance3D.new()
    floor.mesh = floor_mesh
    floor.position.y = 0.0
    add_child(floor)

    var player := PLAYER_SCENE.instantiate() as PlayerController
    player.name = "Ren_QA"
    player.position = Vector3(-4.25, 0.02, 0)
    player.set_physics_process(false)
    player.set_process_input(false)
    player.set_process_unhandled_input(false)
    add_child(player)
    _subjects.append(player)
    _add_label(player, "Ren", Vector3(0, 2.35, 0))

    var mimo_data := [
        [&"lumi", "ルミ", Color(1.0, 0.35, 0.31, 1.0)],
        [&"goro", "ゴロ", Color(1.0, 0.72, 0.16, 1.0)],
        [&"boka", "ボカ", Color(0.12, 0.80, 0.96, 1.0)],
        [&"nera", "ネラ", Color(0.66, 0.36, 1.0, 1.0)],
        [&"moku", "モク", Color(0.30, 0.76, 0.38, 1.0)],
        [&"raku", "ラク", Color(1.0, 0.32, 0.66, 1.0)],
    ]
    for i in range(mimo_data.size()):
        var data: Array = mimo_data[i]
        var mimo := MIMO_SCENE.instantiate() as MimoBase
        mimo.mimo_id = data[0]
        mimo.display_name = data[1]
        mimo.accent_color = data[2]
        mimo.position = Vector3(-2.45 + float(i) * 1.28, 0.02, 0)
        mimo.set_physics_process(false)
        add_child(mimo)
        _subjects.append(mimo)
        _add_label(mimo, data[1], Vector3(0, 2.25, 0))

    var camera := Camera3D.new()
    camera.position = Vector3(-0.35, 2.65, 13.2)
    camera.fov = 48.0
    camera.current = true
    camera.look_at_from_position(camera.position, Vector3(-0.35, 1.05, 0), Vector3.UP)
    add_child(camera)

func _add_label(parent: Node3D, text: String, offset: Vector3) -> void:
    var label := Label3D.new()
    label.text = text
    label.position = offset
    label.font_size = 42
    label.outline_size = 10
    label.modulate = Color(0.90, 1.0, 0.97, 1.0)
    label.outline_modulate = Color(0.01, 0.04, 0.05, 0.95)
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    parent.add_child(label)

func _wait_frames(count: int) -> void:
    for _i in range(count):
        await get_tree().process_frame

func _save_viewport(file_name: String) -> void:
    await RenderingServer.frame_post_draw
    var image := get_viewport().get_texture().get_image()
    if image == null or image.is_empty():
        push_error("[CHARACTER_QA] empty image: %s" % file_name)
        get_tree().quit(1)
        return
    var path := "%s/%s" % [OUT_DIR, file_name]
    var save_err := image.save_png(path)
    if save_err != OK:
        push_error("[CHARACTER_QA] save failed: %s" % file_name)
        get_tree().quit(1)
        return
    print("[CHARACTER_QA] saved ", ProjectSettings.globalize_path(path))
