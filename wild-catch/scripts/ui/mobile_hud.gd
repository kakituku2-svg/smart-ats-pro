extends Control
class_name MobileHUD

signal replay_requested
signal title_requested
signal lure_requested
signal pulse_requested
signal drone_requested

@onready var stick: VirtualStick = $MoveStick
@onready var camera_pad: Control = $CameraPad
@onready var jump_button: Button = $Actions/Jump
@onready var dash_button: Button = $Actions/Dash
@onready var net_button: Button = $Actions/Net
@onready var scan_button: Button = $Actions/Scan
@onready var lure_button: Button = $GadgetBar/Row/Lure
@onready var pulse_button: Button = $GadgetBar/Row/Pulse
@onready var drone_button: Button = $GadgetBar/Row/Drone
@onready var capture_label: Label = $TopBar/Margin/Rows/StatusRow/CaptureLabel
@onready var objective_label: Label = $TopBar/Margin/Rows/StatusRow/ObjectiveLabel
@onready var target_label: Label = $TopBar/Margin/Rows/TargetLabel
@onready var scan_panel: PanelContainer = $ScanPanel
@onready var scan_label: Label = $ScanPanel/Margin/ScanLabel
@onready var toast_label: Label = $ToastLabel
@onready var gadget_status_label: Label = $GadgetStatusLabel
@onready var capture_ready_label: Label = $CaptureReadyLabel
@onready var clear_panel: PanelContainer = $ClearPanel
@onready var replay_button: Button = $ClearPanel/Margin/Content/Buttons/Replay
@onready var title_button: Button = $ClearPanel/Margin/Content/Buttons/Title

var _player: PlayerController
var _net: HexNet
var _scan: EchoScan
var _camera_touch_index := -1
var _toast_timer := 0.0
var _gadget_status_timer := 0.0
var _capture_window_timer := 0.0
var _has_scanned := false
var _has_used_gadget := false
var _first_capture_done := false
var _relic_current := 0
var _relic_total := 6
var _last_clear_time := 0.0
var _last_clear_rank := ""
var _last_clear_relics := 0
var _field_log_button: Button
var _field_log_panel: PanelContainer
var _field_log_label: Label

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _apply_japanese_labels()
    _resolve_targets()
    _build_field_log_ui()
    if not GameState.stage_result_ready.is_connected(_on_stage_result_ready):
        GameState.stage_result_ready.connect(_on_stage_result_ready)
    if not GameState.reward_unlocked.is_connected(_on_reward_unlocked):
        GameState.reward_unlocked.connect(_on_reward_unlocked)
    stick.value_changed.connect(_on_stick_value)
    jump_button.pressed.connect(_on_jump)
    dash_button.pressed.connect(_on_dash)
    net_button.pressed.connect(_on_net)
    scan_button.pressed.connect(_on_scan)
    lure_button.pressed.connect(_on_lure)
    pulse_button.pressed.connect(_on_pulse)
    drone_button.pressed.connect(_on_drone)
    camera_pad.gui_input.connect(_on_camera_gui_input)
    replay_button.pressed.connect(_on_replay)
    title_button.pressed.connect(_on_title)
    scan_panel.visible = false
    clear_panel.visible = false
    toast_label.visible = false
    gadget_status_label.visible = false
    capture_ready_label.visible = false
    target_label.text = "スキャンしてミモを探そう"
    update_capture(0, GameState.stage_target_total)
    update_relic(GameState.get_relic_count(), GameState.stage_relic_total)

func _apply_japanese_labels() -> void:
    jump_button.text = "ジャンプ"
    dash_button.text = "ダッシュ"
    net_button.text = "捕獲ネット"
    scan_button.text = "スキャン"
    lure_button.text = "1  誘導ポッド"
    pulse_button.text = "2  パルス"
    drone_button.text = "3  ドローン"
    replay_button.text = "もう一度"
    title_button.text = "タイトルへ"
    scan_label.text = "エコースキャン"
    capture_ready_label.text = "捕獲チャンス！"
    $ClearPanel/Margin/Content/Title.text = "ステージクリア"
    $ClearPanel/Margin/Content/Body.text = "6体のミモをすべて捕獲しました。"

func _process(delta: float) -> void:
    if _toast_timer > 0.0:
        _toast_timer -= delta
        if _toast_timer <= 0.0:
            toast_label.visible = false
    if _gadget_status_timer > 0.0:
        _gadget_status_timer -= delta
        if _gadget_status_timer <= 0.0:
            gadget_status_label.visible = false
    if _capture_window_timer > 0.0:
        _capture_window_timer -= delta
        if _capture_window_timer <= 0.0:
            capture_ready_label.visible = false
    if not is_instance_valid(_player) or not is_instance_valid(_net) or not is_instance_valid(_scan):
        _resolve_targets()
    if Input.is_action_just_pressed("field_log"):
        toggle_field_log()

func _resolve_targets() -> void:
    _player = get_tree().get_first_node_in_group("player") as PlayerController
    _net = get_tree().get_first_node_in_group("hex_net") as HexNet
    _scan = get_tree().get_first_node_in_group("echo_scan") as EchoScan

func update_capture(current: int, total: int) -> void:
    capture_label.text = "%d / %d" % [current, total]
    if current <= 0:
        if not _has_scanned:
            objective_label.text = "STEP 1  •  ミモをスキャンしよう"
        elif not _has_used_gadget:
            objective_label.text = "STEP 2  •  逃走ルートを読み、ガジェットを試そう"
        else:
            objective_label.text = "STEP 3  •  接近してプレッシャーを上げよう"
    elif current < total:
        if not _first_capture_done:
            _first_capture_done = true
            show_toast("初捕獲成功！  •  残りは好きな順番で狙えます")
        objective_label.text = "残り %d体  •  遺物 %d/%d" % [total - current, _relic_current, _relic_total]
    else:
        objective_label.text = "全ターゲット捕獲  •  遺物 %d/%d" % [_relic_current, _relic_total]
    _refresh_field_log()

func update_relic(current: int, total: int) -> void:
    _relic_current = current
    _relic_total = total
    if GameState.get_capture_count() > 0 and GameState.get_capture_count() < GameState.stage_target_total:
        objective_label.text = "残り %d体  •  遺物 %d/%d" % [GameState.stage_target_total - GameState.get_capture_count(), current, total]
    _refresh_field_log()

func show_scan(payload: Dictionary) -> void:
    _has_scanned = true
    if GameState.get_capture_count() == 0 and not _has_used_gadget:
        objective_label.text = "STEP 2  •  逃走ルートを読み、ガジェットを試そう"
    scan_panel.visible = true
    var mimo_id := String(payload.get("id", ""))
    var stamina_pct := int(round(float(payload.get("stamina", 0.0)) * 100.0))
    var pressure_pct := int(round(float(payload.get("pressure", 0.0)) * 100.0))
    var name_ja := JapaneseText.mimo_name(mimo_id, String(payload.get("name", "ミモ")))
    var direction_ja := JapaneseText.direction(payload.get("direction", "?"))
    var area_ja := JapaneseText.area(mimo_id, String(payload.get("area", "不明エリア")))
    var personality_ja := JapaneseText.personality(mimo_id, String(payload.get("personality", "")))
    var behavior_ja := JapaneseText.behavior(payload.get("behavior", "runner"))
    var route_ja := JapaneseText.route(payload.get("route", "dynamic"))
    var state_ja := JapaneseText.state(payload.get("state", "ROUTINE"))
    var capture_status_ja := JapaneseText.capture_status(payload.get("capture_status", "TRACK"))
    var hint_ja := JapaneseText.hint(mimo_id, String(payload.get("hint", "")))
    scan_label.text = "エコースキャン\n%s  •  %.1fm  方角:%s\nエリア：%s\n性格：%s\n行動：%s  •  状態：%s\n逃走ルート：%s\nスタミナ %d%%   プレッシャー %d%%\n%s\n攻略：%s" % [
        name_ja, float(payload.get("distance", 0.0)), direction_ja, area_ja, personality_ja,
        behavior_ja, state_ja, route_ja, stamina_pct, pressure_pct, capture_status_ja, hint_ja]
    set_target_intel(payload)
    var tween := create_tween()
    scan_panel.modulate.a = 0.0
    tween.tween_property(scan_panel, "modulate:a", 1.0, 0.12)
    tween.tween_interval(4.2)
    tween.tween_property(scan_panel, "modulate:a", 0.0, 0.22)
    tween.tween_callback(func() -> void: scan_panel.visible = false)

func set_target_intel(payload: Dictionary) -> void:
    var mimo_id := String(payload.get("id", ""))
    var pressure_pct := int(round(float(payload.get("pressure", 0.0)) * 100.0))
    target_label.text = "%s  •  %s  •  プレッシャー %d%%" % [
        JapaneseText.mimo_name(mimo_id, String(payload.get("name", "ミモ"))),
        JapaneseText.capture_status(payload.get("capture_status", "TRACK")), pressure_pct]
    if bool(payload.get("capture_ready", false)):
        show_capture_window(JapaneseText.mimo_name(mimo_id, String(payload.get("name", "ミモ"))))

func clear_target_intel() -> void:
    target_label.text = "スキャンしてミモを探そう"

func show_capture_window(mimo_name: String) -> void:
    capture_ready_label.text = "捕獲チャンス！  •  %s  •  今すぐ捕獲ネット" % mimo_name
    capture_ready_label.visible = true
    _capture_window_timer = 2.2
    if GameState.get_capture_count() == 0:
        objective_label.text = "STEP 4  •  今すぐ捕獲ネット！"
    capture_ready_label.scale = Vector2(0.92, 0.92)
    var tween := create_tween()
    tween.tween_property(capture_ready_label, "scale", Vector2.ONE * 1.06, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_property(capture_ready_label, "scale", Vector2.ONE, 0.10)

func show_scan_empty() -> void:
    clear_target_intel()
    show_toast("エコースキャン  •  未捕獲のミモは近くにいません")

func show_toast(message: String) -> void:
    toast_label.text = message
    toast_label.visible = true
    _toast_timer = 2.0

func show_gadget_status(message: String) -> void:
    gadget_status_label.text = message
    gadget_status_label.visible = true
    _gadget_status_timer = 4.5

func show_stage_clear() -> void:
    clear_panel.visible = true
    capture_ready_label.visible = false
    gadget_status_label.visible = false
    $ClearPanel/Margin/Content/Title.text = "ステージクリア  •  ランク %s" % (_last_clear_rank if _last_clear_rank != "" else "-")
    if _last_clear_time > 0.0:
        $ClearPanel/Margin/Content/Body.text = "クリアタイム %.1f秒  •  遺物 %d/%d\n6体のミモをすべて捕獲！ トロピカル遺跡パーク攻略完了。" % [_last_clear_time, _last_clear_relics, _relic_total]
    else:
        $ClearPanel/Margin/Content/Body.text = "6体のミモをすべて捕獲！  遺物 %d/%d\nトロピカル遺跡パーク攻略完了。" % [_relic_current, _relic_total]

func show_player_status(label: String) -> void:
    if label == "":
        return
    var status_ja := label
    if label == "SLOWED":
        status_ja = "移動速度低下"
    elif label == "STAGGER":
        status_ja = "ひるみ"
    show_toast("状態変化  •  %s" % status_ja)

func toggle_field_log() -> void:
    if _field_log_panel == null:
        return
    _field_log_panel.visible = not _field_log_panel.visible
    _field_log_button.text = "閉じる" if _field_log_panel.visible else "フィールドログ"
    if _field_log_panel.visible:
        _refresh_field_log()

func _build_field_log_ui() -> void:
    _field_log_button = Button.new()
    _field_log_button.name = "FieldLogButton"
    _field_log_button.text = "フィールドログ"
    _field_log_button.position = Vector2(1080, 102)
    _field_log_button.size = Vector2(175, 46)
    _field_log_button.pressed.connect(toggle_field_log)
    add_child(_field_log_button)

    _field_log_panel = PanelContainer.new()
    _field_log_panel.name = "FieldLogPanel"
    _field_log_panel.position = Vector2(330, 105)
    _field_log_panel.size = Vector2(620, 510)
    _field_log_panel.visible = false
    add_child(_field_log_panel)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 24)
    margin.add_theme_constant_override("margin_top", 20)
    margin.add_theme_constant_override("margin_right", 24)
    margin.add_theme_constant_override("margin_bottom", 20)
    _field_log_panel.add_child(margin)

    _field_log_label = Label.new()
    _field_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _field_log_label.add_theme_font_size_override("font_size", 18)
    margin.add_child(_field_log_label)
    _refresh_field_log()

func _refresh_field_log() -> void:
    if _field_log_label == null:
        return
    var lines: Array[String] = ["フィールドログ", "", "ミモ図鑑  %d/6" % SaveManager.get_unique_capture_count()]
    for entry in SaveManager.get_bestiary_summary():
        var item := entry as Dictionary
        var captured := bool(item.get("captured", false))
        var id := String(item.get("id", "mimo"))
        lines.append("  %s  %s" % ["●" if captured else "○", JapaneseText.mimo_name(id, id) if captured else "？？？？"])
    lines.append("")
    lines.append("古代遺物  %d/6" % SaveManager.get_relic_count())
    lines.append("今回の探索：%d/%d" % [_relic_current, _relic_total])
    if SaveManager.has_unlock(&"ruins_cartographer"):
        lines.append("遺跡測量士：解放済み")
        lines.append("  ドローン索敵範囲↑ / 同時発見数↑ / 再使用時間↓")
    else:
        lines.append("遺跡測量士：未解放  •  古代遺物を6個集めよう")
    if SaveManager.has_unlock(&"hex_resonance"):
        lines.append("HEX共鳴：解放済み  •  捕獲ネット強化")
    elif SaveManager.has_unlock(&"ruins_cartographer"):
        lines.append("HEX共鳴：未発見  •  遺跡の異常反応を探そう")
    else:
        lines.append("HEX共鳴：？？？？")
    lines.append("ステージ1 クリア回数：%d" % SaveManager.get_stage_clear_count(&"stage1"))
    var result := SaveManager.get_stage_result(&"stage1")
    if not result.is_empty():
        lines.append("最高ランク：%s" % String(result.get("best_rank", "-")))
        lines.append("ベストタイム：%.1f秒" % float(result.get("best_time", 0.0)))
        lines.append("最高遺物数：%d/6" % int(result.get("best_relics", 0)))
    lines.append("")
    lines.append("Fキー / 閉じるボタンでゲームへ戻る")
    _field_log_label.text = "\n".join(lines)

func _on_stage_result_ready(stage_id: StringName, clear_time: float, relic_count: int, rank: String) -> void:
    if stage_id != &"stage1":
        return
    _last_clear_time = clear_time
    _last_clear_relics = relic_count
    _last_clear_rank = rank
    _refresh_field_log()

func _on_reward_unlocked(reward_id: StringName) -> void:
    match reward_id:
        &"ruins_cartographer":
            show_toast("永久アップグレード解放  •  遺跡測量士")
            show_gadget_status("次回からドローン強化  •  索敵範囲↑ / 発見数↑ / 再使用時間↓")
        &"hex_resonance":
            show_toast("永久アップグレード解放  •  HEX共鳴")
            show_gadget_status("捕獲ネット強化  •  3段目の射程↑ / コンボ受付時間↑")
    _refresh_field_log()

func _mark_gadget_used() -> void:
    _has_used_gadget = true
    if GameState.get_capture_count() == 0:
        objective_label.text = "STEP 3  •  接近してプレッシャーを上げよう"

func _on_stick_value(value: Vector2) -> void:
    if is_instance_valid(_player):
        _player.set_touch_move_vector(value)

func _on_jump() -> void:
    if is_instance_valid(_player):
        _player.request_jump()

func _on_dash() -> void:
    if is_instance_valid(_player):
        _player.request_dash()

func _on_net() -> void:
    if is_instance_valid(_net):
        _net.request_swing()

func _on_scan() -> void:
    if is_instance_valid(_scan):
        _scan.request_scan()

func _on_lure() -> void:
    _mark_gadget_used()
    lure_requested.emit()

func _on_pulse() -> void:
    _mark_gadget_used()
    pulse_requested.emit()

func _on_drone() -> void:
    _mark_gadget_used()
    drone_requested.emit()

func _on_camera_gui_input(event: InputEvent) -> void:
    if not is_instance_valid(_player):
        return
    if event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch
        if touch.pressed and _camera_touch_index == -1:
            _camera_touch_index = touch.index
        elif not touch.pressed and touch.index == _camera_touch_index:
            _camera_touch_index = -1
    elif event is InputEventScreenDrag:
        var drag := event as InputEventScreenDrag
        if drag.index == _camera_touch_index:
            _player.add_camera_look_delta(drag.screen_relative)
    elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
        var motion := event as InputEventMouseMotion
        _player.add_camera_look_delta(motion.relative)

func _on_replay() -> void:
    replay_requested.emit()

func _on_title() -> void:
    title_requested.emit()
