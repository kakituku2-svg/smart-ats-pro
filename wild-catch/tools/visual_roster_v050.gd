extends Node3D

const OUT_DIR := "res://build/screenshots"
const MIMO_SCENE := "res://scenes/mimo/mimo.tscn"
const PLAYER_SCENE := "res://scenes/player/player.tscn"

var _camera: Camera3D
var _subject_root: Node3D

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_run")

func _run() -> void:
    var absolute_dir := ProjectSettings.globalize_path(OUT_DIR)
    var err := DirAccess.make_dir_recursive_absolute(absolute_dir)
    if err != OK and err != ERR_ALREADY_EXISTS:
        push_error("[ROSTER_V050] cannot create screenshot directory")
        get_tree().quit(1)
        return
    _build_studio()
    await _wait_frames(4)

    _clear_subjects()
    _spawn_ren()
    await _wait_frames(8)
    await _save_viewport("34_ren_v3_front.png")

    _clear_subjects()
    _spawn_mimo_row([
        [&"lumi", "ルミ", Color(0.34, 0.92, 0.46, 1.0)],
        [&"goro", "ゴロ", Color(0.64, 0.52, 0.34, 1.0)],
        [&"boka", "ボカ", Color(0.96, 0.34, 0.20, 1.0)],
        [&"nera", "ネラ", Color(0.32, 0.68, 1.0, 1.0)],
        [&"moku", "モク", Color(0.52, 0.72, 0.30, 1.0)],
        [&"raku", "ラク", Color(0.92, 0.42, 0.76, 1.0)],
    ], 2.25)
    await _wait_frames(10)
    await _save_viewport("35_stage1_mimo_roster.png")

    _clear_subjects()
    _spawn_mimo_row([
        [&"aero", "アエロ", Color(0.30, 0.86, 1.0, 1.0)],
        [&"kuru", "クル", Color(1.0, 0.70, 0.24, 1.0)],
        [&"vivi", "ビビ", Color(0.42, 0.84, 0.36, 1.0)],
        [&"toto", "トト", Color(0.92, 0.38, 0.20, 1.0)],
        [&"nagi", "ナギ", Color(0.58, 0.70, 1.0, 1.0)],
    ], 2.55)
    await _wait_frames(10)
    await _save_viewport("36_stage2_mimo_roster.png")

    _clear_subjects()
    _spawn_mimo_row([
        [&"pico", "ピコ", Color(0.30, 1.0, 0.70, 1.0)],
        [&"luna", "ルナ", Color(0.62, 0.42, 1.0, 1.0)],
        [&"doro", "ドロ", Color(0.48, 0.72, 0.30, 1.0)],
        [&"nix", "ニクス", Color(0.32, 0.82, 1.0, 1.0)],
        [&"fufu", "フフ", Color(1.0, 0.42, 0.78, 1.0)],
        [&"zari", "ザリ", Color(1.0, 0.46, 0.24, 1.0)],
        [&"ema", "エマ", Color(0.92, 0.62, 1.0, 1.0)],
    ], 1.92)
    await _wait_frames(10)
    await _save_viewport("37_stage3_mimo_roster.png")

    _clear_subjects()
    _spawn_enemy_row()
    await _wait_frames(8)
    await _save_viewport("38_interference_roster.png")

    print("[ROSTER_V050] PASS — Ren, 18 Mimo and enemy lineup screenshots saved")
    get_tree().quit(0)

func _build_studio() -> void:
    var environment := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.025, 0.055, 0.07, 1.0)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.58, 0.70, 0.74, 1.0)
    env.ambient_light_energy = 0.82
    environment.environment = env
    add_child(environment)

    var key := DirectionalLight3D.new()
    key.rotation_degrees = Vector3(-48, -28, 0)
    key.light_color = Color(1.0, 0.91, 0.78, 1.0)
    key.light_energy = 1.35
    key.shadow_enabled = true
    add_child(key)

    var fill := OmniLight3D.new()
    fill.position = Vector3(-4.0, 4.0, 3.5)
    fill.omni_range = 14.0
    fill.light_color = Color(0.32, 0.78, 1.0, 1.0)
    fill.light_energy = 1.15
    add_child(fill)

    var floor := MeshInstance3D.new()
    var floor_mesh := PlaneMesh.new()
    floor_mesh.size = Vector2(22, 10)
    floor.mesh = floor_mesh
    var floor_mat := StandardMaterial3D.new()
    floor_mat.albedo_color = Color(0.07, 0.11, 0.12, 1.0)
    floor_mat.roughness = 0.94
    floor.material_override = floor_mat
    add_child(floor)

    _camera = Camera3D.new()
    _camera.position = Vector3(0, 2.15, 8.8)
    _camera.current = true
    add_child(_camera)
    _camera.look_at(Vector3(0, 1.0, 0), Vector3.UP)

    _subject_root = Node3D.new()
    _subject_root.name = "Subjects"
    add_child(_subject_root)

func _clear_subjects() -> void:
    for child in _subject_root.get_children():
        child.queue_free()
    await _wait_frames(2)

func _spawn_ren() -> void:
    var packed := load(PLAYER_SCENE) as PackedScene
    if packed == null:
        return
    var ren := packed.instantiate() as PlayerController
    ren.name = "RenRoster"
    ren.position = Vector3(0, 0.05, 0)
    _subject_root.add_child(ren)
    ren.set_physics_process(false)
    var label := _label("REN • Preview V3", Vector3(0, 2.35, 0))
    _subject_root.add_child(label)
    _camera.position = Vector3(0, 1.55, 5.2)
    _camera.look_at(Vector3(0, 0.85, 0), Vector3.UP)

func _spawn_mimo_row(entries: Array, spacing: float) -> void:
    var packed := load(MIMO_SCENE) as PackedScene
    if packed == null:
        return
    var start_x := -spacing * float(entries.size() - 1) * 0.5
    for i in range(entries.size()):
        var entry: Array = entries[i]
        var mimo := packed.instantiate() as MimoBase
        mimo.mimo_id = entry[0] as StringName
        mimo.display_name = String(entry[1])
        mimo.accent_color = entry[2] as Color
        mimo.position = Vector3(start_x + float(i) * spacing, 0.05, 0)
        _subject_root.add_child(mimo)
        mimo.set_physics_process(false)
        var label := _label(String(entry[1]), mimo.position + Vector3(0, 1.95, 0))
        _subject_root.add_child(label)
    _camera.position = Vector3(0, 2.1, 9.8 if entries.size() >= 6 else 8.8)
    _camera.look_at(Vector3(0, 0.95, 0), Vector3.UP)

func _spawn_enemy_row() -> void:
    var entries := [
        [&"guard_bug", "ガードバグ", Color(1.0, 0.38, 0.20, 1.0)],
        [&"wind_stinger", "ウィンドスティンガー", Color(0.32, 0.86, 1.0, 1.0)],
        [&"glow_leech", "グロウリーチ", Color(0.82, 0.38, 1.0, 1.0)],
    ]
    for i in range(entries.size()):
        var entry: Array = entries[i]
        var enemy := InterferenceEnemy.new()
        enemy.variant_id = entry[0] as StringName
        enemy.accent_color = entry[2] as Color
        enemy.position = Vector3(-2.8 + float(i) * 2.8, 0.05, 0)
        _subject_root.add_child(enemy)
        enemy.set_physics_process(false)
        var label := _label(String(entry[1]), enemy.position + Vector3(0, 1.75, 0))
        _subject_root.add_child(label)
    _camera.position = Vector3(0, 1.8, 7.2)
    _camera.look_at(Vector3(0, 0.75, 0), Vector3.UP)

func _label(text_value: String, position_value: Vector3) -> Label3D:
    var label := Label3D.new()
    label.text = text_value
    label.position = position_value
    label.font_size = 32
    label.outline_size = 6
    label.modulate = Color(0.90, 1.0, 0.97, 1.0)
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    return label

func _wait_frames(count: int) -> void:
    for _i in range(count):
        await get_tree().process_frame

func _save_viewport(file_name: String) -> void:
    await RenderingServer.frame_post_draw
    var image := get_viewport().get_texture().get_image()
    if image == null or image.is_empty():
        push_error("[ROSTER_V050] empty image: %s" % file_name)
        get_tree().quit(1)
        return
    var path := "%s/%s" % [OUT_DIR, file_name]
    var save_err := image.save_png(path)
    if save_err != OK:
        push_error("[ROSTER_V050] save failed: %s" % file_name)
        get_tree().quit(1)
        return
    print("[ROSTER_V050] saved ", ProjectSettings.globalize_path(path))
