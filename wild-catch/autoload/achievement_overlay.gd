extends CanvasLayer

var _root: Control
var _button: Button
var _label: Label

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    layer = 94
    _build_ui()
    _button.visible = false

func _process(_delta: float) -> void:
    var has_player := get_tree().get_first_node_in_group("player") != null
    if not _root.visible:
        _button.visible = has_player and not get_tree().paused

func toggle() -> void:
    if get_tree().get_first_node_in_group("player") == null:
        return
    var opening := not _root.visible
    _root.visible = opening
    _button.visible = not opening
    get_tree().paused = opening
    if opening:
        var player := get_tree().get_first_node_in_group("player") as PlayerController
        if player != null:
            player.clear_transient_input_state()
        _refresh()

func close() -> void:
    if not _root.visible:
        return
    _root.visible = false
    get_tree().paused = false
    _button.visible = get_tree().get_first_node_in_group("player") != null

func _build_ui() -> void:
    _button = Button.new()
    _button.name = "AchievementButton"
    _button.text = "実績"
    _button.position = Vector2(760, 70)
    _button.size = Vector2(148, 42)
    _button.pressed.connect(toggle)
    GameUISkin.style_button(_button, Color(0.78, 0.56, 1.0, 1.0), 15)
    add_child(_button)

    _root = Control.new()
    _root.name = "AchievementOverlay"
    _root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _root.visible = false
    _root.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(_root)

    var shade := ColorRect.new()
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.color = Color(0.008, 0.025, 0.045, 0.82)
    shade.mouse_filter = Control.MOUSE_FILTER_STOP
    _root.add_child(shade)

    var panel := PanelContainer.new()
    panel.position = Vector2(288, 70)
    panel.size = Vector2(704, 580)
    GameUISkin.style_panel(panel, Color(0.72, 0.52, 1.0, 1.0))
    _root.add_child(panel)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 32)
    margin.add_theme_constant_override("margin_top", 26)
    margin.add_theme_constant_override("margin_right", 32)
    margin.add_theme_constant_override("margin_bottom", 26)
    panel.add_child(margin)

    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 12)
    margin.add_child(column)

    var title := Label.new()
    title.text = "実績"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    GameUISkin.style_heading(title, Color(0.82, 0.66, 1.0, 1.0), 32)
    column.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "探索・捕獲・周回の記録から自動判定"
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    GameUISkin.style_body(subtitle, 15)
    column.add_child(subtitle)

    _label = Label.new()
    _label.name = "AchievementList"
    _label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _label.custom_minimum_size.y = 400
    GameUISkin.style_body(_label, 18)
    column.add_child(_label)

    var close_button := Button.new()
    close_button.text = "ゲームへ戻る"
    close_button.custom_minimum_size.y = 52
    close_button.pressed.connect(close)
    GameUISkin.style_button(close_button, Color(0.54, 0.94, 1.0, 1.0), 18)
    column.add_child(close_button)

func _refresh() -> void:
    if _label == null:
        return
    var unique := SaveManager.get_unique_capture_count()
    var relics := SaveManager.get_relic_count()
    var clears := SaveManager.get_stage_clear_count(&"stage1")
    var result := SaveManager.get_stage_result(&"stage1")
    var best_rank := String(result.get("best_rank", ""))
    var entries := [
        [unique >= 1, "はじめての捕獲", "ミモを1体捕獲する", "%d/1" % mini(unique, 1)],
        [unique >= 6, "ミモハンター", "6体すべてを図鑑へ登録する", "%d/6" % mini(unique, 6)],
        [relics >= 6, "遺跡コレクター", "古代遺物を6個集める", "%d/6" % mini(relics, 6)],
        [best_rank == "S", "パーフェクトハント", "ステージ1でSランクを取る", best_rank if best_rank != "" else "-"],
        [SaveManager.has_unlock(&"ruins_cartographer"), "遺跡測量士", "ドローン永久強化を解放する", "解放済み" if SaveManager.has_unlock(&"ruins_cartographer") else "未解放"],
        [SaveManager.has_unlock(&"hex_resonance"), "HEX共鳴", "隠し祭壇で捕獲ネットを強化する", "解放済み" if SaveManager.has_unlock(&"hex_resonance") else "未解放"],
        [clears >= 2, "もう一度、遺跡へ", "ステージ1を2回クリアする", "%d/2" % mini(clears, 2)],
    ]
    var unlocked := 0
    var lines: Array[String] = []
    for entry in entries:
        var done := bool(entry[0])
        if done:
            unlocked += 1
        var icon := "★" if done else "☆"
        lines.append("%s  %s\n    %s  [%s]" % [icon, String(entry[1]), String(entry[2]), String(entry[3])])
    lines.push_front("解除数  %d / %d\n" % [unlocked, entries.size()])
    _label.text = "\n".join(lines)
