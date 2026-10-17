extends Control

var _progress := 0.0
var _elapsed := 0.0
var _min_duration := 2.4
var _loading_started := false
var _stage_ready := false
var _load_error := false
var _stage_path := ""
var _title: Label
var _mission: Label
var _objective: Label
var _enemy: Label
var _tip: Label
var _bar: ProgressBar
var _status: Label
var _return_button: Button

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    AudioManager.play_music(&"transfer_loading")
    _build_ui()
    _begin_loading()
    queue_redraw()

func _process(delta: float) -> void:
    _elapsed += delta
    if not _load_error:
        _progress = minf(95.0, _progress + delta * 32.0)
    if _loading_started and not _stage_ready and not _load_error:
        var status := ResourceLoader.load_threaded_get_status(_stage_path)
        if status == ResourceLoader.THREAD_LOAD_LOADED:
            _stage_ready = true
            _progress = 100.0
        elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
            _set_load_error("転送先の読み込みに失敗しました")
    if _bar != null:
        _bar.value = _progress
    if _status != null and not _load_error:
        var dots := ".".repeat(int(_elapsed * 2.5) % 4)
        _status.text = "転送座標を同期中%s" % dots
    if _stage_ready and _elapsed >= _min_duration:
        AudioManager.stop_music()
        AudioManager.play_event(&"transfer")
        MissionRouter.load_pending_stage()
    queue_redraw()

func _draw() -> void:
    var size_value := size
    draw_rect(Rect2(Vector2.ZERO, size_value), Color(0.008, 0.025, 0.045, 1.0))
    var center := size_value * Vector2(0.5, 0.48)
    for i in range(6):
        var radius := 90.0 + float(i) * 54.0 + sin(_elapsed * 2.0 + i) * 7.0
        var alpha := 0.22 - float(i) * 0.026
        var ring_color := Color(1.0, 0.30, 0.24, maxf(alpha, 0.04)) if _load_error else Color(0.18, 0.92, 1.0, maxf(alpha, 0.04))
        draw_arc(center, radius, _elapsed * (0.25 + i * 0.04), TAU + _elapsed * (0.25 + i * 0.04), 64, ring_color, 3.0, true)
    var beam_width := 18.0 + sin(_elapsed * 5.0) * 5.0
    var beam_color := Color(1.0, 0.20, 0.16, 0.06) if _load_error else Color(0.28, 1.0, 0.90, 0.08)
    draw_rect(Rect2(center.x - beam_width * 0.5, 0, beam_width, size_value.y), beam_color)

func _build_ui() -> void:
    var mission_data := MissionRouter.get_mission(MissionRouter.get_pending_stage_id())

    _title = Label.new()
    _title.position = Vector2(70, 62)
    _title.size = Vector2(1140, 70)
    _title.text = "MISSION TRANSFER"
    GameUISkin.style_heading(_title, Color(0.42, 1.0, 0.90, 1.0), 38)
    add_child(_title)

    _mission = Label.new()
    _mission.position = Vector2(72, 138)
    _mission.size = Vector2(1120, 62)
    _mission.text = String(mission_data.get("name", "UNKNOWN AREA"))
    GameUISkin.style_heading(_mission, mission_data.get("accent", Color.WHITE) as Color, 31)
    add_child(_mission)

    var panel := PanelContainer.new()
    panel.position = Vector2(70, 220)
    panel.size = Vector2(520, 300)
    GameUISkin.style_panel(panel, mission_data.get("accent", Color.WHITE) as Color)
    add_child(panel)
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 26)
    margin.add_theme_constant_override("margin_top", 24)
    margin.add_theme_constant_override("margin_right", 26)
    margin.add_theme_constant_override("margin_bottom", 24)
    panel.add_child(margin)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 15)
    margin.add_child(column)

    _objective = Label.new()
    _objective.text = "確保任務\n%s" % String(mission_data.get("objective", "捕獲対象を確保せよ"))
    GameUISkin.style_heading(_objective, Color(1.0, 0.88, 0.42, 1.0), 24)
    column.add_child(_objective)

    var target_count := int(mission_data.get("target_total", 0))
    var relic_count := int(mission_data.get("relic_total", 0))
    _enemy = Label.new()
    _enemy.text = "捕獲対象   %02d\n妨害体      %02d\n探索遺物   %02d" % [target_count, int(mission_data.get("interference_total", 0)), relic_count]
    GameUISkin.style_body(_enemy, 20)
    column.add_child(_enemy)

    _tip = Label.new()
    _tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _tip.text = "FIELD NOTE\n%s" % String(mission_data.get("brief", ""))
    GameUISkin.style_body(_tip, 16)
    column.add_child(_tip)

    _bar = ProgressBar.new()
    _bar.position = Vector2(70, 586)
    _bar.size = Vector2(1140, 24)
    _bar.min_value = 0.0
    _bar.max_value = 100.0
    _bar.show_percentage = false
    add_child(_bar)

    _status = Label.new()
    _status.position = Vector2(70, 622)
    _status.size = Vector2(1140, 44)
    _status.text = "転送座標を同期中"
    _status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    GameUISkin.style_body(_status, 17)
    add_child(_status)

    _return_button = Button.new()
    _return_button.position = Vector2(490, 662)
    _return_button.size = Vector2(300, 46)
    _return_button.text = "本拠地へ戻る"
    _return_button.visible = false
    _return_button.pressed.connect(_return_to_hub)
    GameUISkin.style_button(_return_button, Color(1.0, 0.40, 0.30, 1.0), 16)
    add_child(_return_button)

func _begin_loading() -> void:
    var mission_data := MissionRouter.get_mission(MissionRouter.get_pending_stage_id())
    _stage_path = String(mission_data.get("scene", ""))
    if _stage_path == "" or not ResourceLoader.exists(_stage_path):
        _set_load_error("転送先がまだ準備されていません")
        return
    var err := ResourceLoader.load_threaded_request(_stage_path)
    _loading_started = err == OK
    if not _loading_started:
        _set_load_error("転送準備に失敗しました")

func _set_load_error(message: String) -> void:
    _load_error = true
    _loading_started = false
    AudioManager.play_event(&"warning")
    if _status != null:
        _status.text = message
        _status.add_theme_color_override("font_color", Color(1.0, 0.48, 0.40, 1.0))
    if _return_button != null:
        _return_button.visible = true

func _return_to_hub() -> void:
    AudioManager.stop_music()
    MissionRouter.return_to_hub(&"")
