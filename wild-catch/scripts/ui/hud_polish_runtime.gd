extends Node
class_name HudPolishRuntime

var _log_label: Label

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_apply")

func _process(_delta: float) -> void:
    if _log_label != null and is_instance_valid(_log_label) and _log_label.visible:
        _refresh_bestiary_header()

func _apply() -> void:
    var hud := get_parent() as Control
    if hud == null:
        return
    var log_button := hud.get_node_or_null("FieldLogButton") as Button
    if log_button != null:
        log_button.position = Vector2(760, 18)
        log_button.size = Vector2(148, 42)
        log_button.text = "フィールドログ"
        GameUISkin.style_button(log_button, Color(0.98, 0.69, 0.24, 1.0), 15)

    var log_panel := hud.get_node_or_null("FieldLogPanel") as PanelContainer
    if log_panel != null:
        log_panel.position = Vector2(300, 96)
        log_panel.size = Vector2(680, 520)
        GameUISkin.style_panel(log_panel, Color(0.92, 0.66, 0.24, 1.0))
        _log_label = log_panel.find_child("*", true, false) as Label
        if _log_label != null:
            GameUISkin.style_body(_log_label, 18)
            _refresh_bestiary_header()

    var gadget_status := hud.get_node_or_null("GadgetStatusLabel") as Label
    if gadget_status != null:
        gadget_status.modulate = Color(1, 1, 1, 0.96)

    var scan_panel := hud.get_node_or_null("ScanPanel") as PanelContainer
    if scan_panel != null:
        scan_panel.pivot_offset = scan_panel.size * 0.5

    # Keep persistent buttons away from the floating gadget shortcut dock.
    var achievement_layer := get_tree().root.get_node_or_null("AchievementOverlay")
    if achievement_layer != null:
        var achievement_button := achievement_layer.get_node_or_null("AchievementButton") as Button
        if achievement_button != null:
            achievement_button.position = Vector2(760, 70)
            achievement_button.size = Vector2(148, 42)

func _refresh_bestiary_header() -> void:
    if _log_label == null:
        return
    var total := SaveManager.get_bestiary_total()
    var captured := SaveManager.get_unique_capture_count()
    var lines := _log_label.text.split("\n")
    if lines.size() >= 3 and String(lines[2]).begins_with("ミモ図鑑"):
        lines[2] = "ミモ図鑑  %d/%d" % [captured, total]
        _log_label.text = "\n".join(lines)
