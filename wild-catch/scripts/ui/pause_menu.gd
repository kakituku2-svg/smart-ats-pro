extends CanvasLayer
class_name PauseMenu

var _root: Control
var _panel: PanelContainer
var _pause_button: Button
var _volume_label: Label
var _sensitivity_label: Label
var _volume_slider: HSlider
var _sensitivity_slider: HSlider
var _shake_toggle: CheckButton
var _hitstop_toggle: CheckButton

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    layer = 95
    _build_ui()
    _sync_from_settings()
    _pause_button.visible = false

func _process(_delta: float) -> void:
    var has_player := get_tree().get_first_node_in_group("player") != null
    if not _root.visible:
        _pause_button.visible = has_player and not get_tree().paused
    if has_player and Input.is_action_just_pressed("pause_game"):
        if get_tree().paused and not _root.visible:
            return
        toggle_pause()

func toggle_pause() -> void:
    if get_tree().get_first_node_in_group("player") == null:
        return
    if get_tree().paused and not _root.visible:
        return
    var opening := not _root.visible
    _root.visible = opening
    _pause_button.visible = not opening
    get_tree().paused = opening
    if opening:
        var player := get_tree().get_first_node_in_group("player") as PlayerController
        if player != null:
            player.clear_transient_input_state()
        _sync_from_settings()

func close_pause() -> void:
    if not _root.visible:
        return
    _root.visible = false
    get_tree().paused = false
    _pause_button.visible = get_tree().get_first_node_in_group("player") != null

func _build_ui() -> void:
    _pause_button = Button.new()
    _pause_button.name = "PauseButton"
    _pause_button.text = "メニュー"
    _pause_button.position = Vector2(20, 124)
    _pause_button.size = Vector2(112, 44)
    _pause_button.pressed.connect(toggle_pause)
    GameUISkin.style_button(_pause_button, Color(1.0, 0.70, 0.24, 1.0), 16)
    add_child(_pause_button)

    _root = Control.new()
    _root.name = "PauseOverlay"
    _root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _root.visible = false
    _root.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(_root)

    var shade := ColorRect.new()
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.color = Color(0.005, 0.025, 0.035, 0.78)
    shade.mouse_filter = Control.MOUSE_FILTER_STOP
    _root.add_child(shade)

    _panel = PanelContainer.new()
    _panel.position = Vector2(352, 66)
    _panel.size = Vector2(576, 588)
    GameUISkin.style_panel(_panel, Color(1.0, 0.72, 0.28, 1.0))
    _root.add_child(_panel)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 34)
    margin.add_theme_constant_override("margin_top", 28)
    margin.add_theme_constant_override("margin_right", 34)
    margin.add_theme_constant_override("margin_bottom", 28)
    _panel.add_child(margin)

    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 14)
    margin.add_child(column)

    var title := Label.new()
    title.text = "ポーズ / 設定"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    GameUISkin.style_heading(title, Color(1.0, 0.80, 0.34, 1.0), 32)
    column.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "設定は自動保存されます"
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    GameUISkin.style_body(subtitle, 15)
    column.add_child(subtitle)

    _volume_label = Label.new()
    GameUISkin.style_body(_volume_label, 18)
    column.add_child(_volume_label)
    _volume_slider = HSlider.new()
    _volume_slider.min_value = 0.0
    _volume_slider.max_value = 1.0
    _volume_slider.step = 0.05
    _volume_slider.custom_minimum_size.y = 42
    _volume_slider.value_changed.connect(_on_volume_changed)
    GameUISkin.style_slider(_volume_slider, Color(0.38, 1.0, 0.70, 1.0))
    column.add_child(_volume_slider)

    _sensitivity_label = Label.new()
    GameUISkin.style_body(_sensitivity_label, 18)
    column.add_child(_sensitivity_label)
    _sensitivity_slider = HSlider.new()
    _sensitivity_slider.min_value = 0.30
    _sensitivity_slider.max_value = 1.20
    _sensitivity_slider.step = 0.05
    _sensitivity_slider.custom_minimum_size.y = 42
    _sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
    GameUISkin.style_slider(_sensitivity_slider, Color(0.30, 0.78, 1.0, 1.0))
    column.add_child(_sensitivity_slider)

    var sensitivity_hint := Label.new()
    sensitivity_hint.text = "スマホ推奨：0.55〜0.75  •  初期値 0.65"
    sensitivity_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    GameUISkin.style_body(sensitivity_hint, 14)
    column.add_child(sensitivity_hint)

    _shake_toggle = CheckButton.new()
    _shake_toggle.text = "カメラ揺れ"
    _shake_toggle.add_theme_font_size_override("font_size", 17)
    _shake_toggle.toggled.connect(SettingsManager.set_camera_shake)
    column.add_child(_shake_toggle)

    _hitstop_toggle = CheckButton.new()
    _hitstop_toggle.text = "捕獲時ヒットストップ"
    _hitstop_toggle.add_theme_font_size_override("font_size", 17)
    _hitstop_toggle.toggled.connect(SettingsManager.set_hitstop)
    column.add_child(_hitstop_toggle)

    var divider := HSeparator.new()
    column.add_child(divider)

    var resume := Button.new()
    resume.text = "ゲームへ戻る"
    resume.custom_minimum_size.y = 56
    resume.pressed.connect(close_pause)
    GameUISkin.style_button(resume, Color(0.34, 1.0, 0.67, 1.0), 19)
    column.add_child(resume)

    var defaults := Button.new()
    defaults.text = "設定を初期値に戻す"
    defaults.custom_minimum_size.y = 48
    defaults.pressed.connect(_on_reset_defaults)
    GameUISkin.style_button(defaults, Color(0.34, 0.76, 1.0, 1.0), 16)
    column.add_child(defaults)

    var title_button := Button.new()
    title_button.text = "タイトルへ戻る"
    title_button.custom_minimum_size.y = 48
    title_button.pressed.connect(_on_title)
    GameUISkin.style_button(title_button, Color(1.0, 0.46, 0.34, 1.0), 16)
    column.add_child(title_button)

func _sync_from_settings() -> void:
    _volume_slider.set_value_no_signal(SettingsManager.master_volume)
    _sensitivity_slider.set_value_no_signal(SettingsManager.camera_sensitivity)
    _shake_toggle.set_pressed_no_signal(SettingsManager.camera_shake_enabled)
    _hitstop_toggle.set_pressed_no_signal(SettingsManager.hitstop_enabled)
    _refresh_labels()

func _refresh_labels() -> void:
    _volume_label.text = "音量  %d%%" % int(round(SettingsManager.master_volume * 100.0))
    _sensitivity_label.text = "カメラ感度  %.2f" % SettingsManager.camera_sensitivity

func _on_volume_changed(value: float) -> void:
    SettingsManager.set_master_volume(value)
    _refresh_labels()

func _on_sensitivity_changed(value: float) -> void:
    SettingsManager.set_camera_sensitivity(value)
    _refresh_labels()

func _on_reset_defaults() -> void:
    SettingsManager.reset_defaults()
    _sync_from_settings()

func _on_title() -> void:
    close_pause()
    get_tree().change_scene_to_file("res://scenes/ui/title_screen.tscn")
