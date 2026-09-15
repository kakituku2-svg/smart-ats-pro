extends Node

var _hub: Node3D
var _panel: PanelContainer
var _body: Label

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().node_added.connect(_on_node_added)
    SaveManager.progress_saved.connect(_refresh)

func _on_node_added(node: Node) -> void:
    if node is Node3D and node.name == "FieldBase":
        call_deferred("_install", node)

func _install(hub: Node3D) -> void:
    await get_tree().process_frame
    if not is_instance_valid(hub):
        return
    _hub = hub
    var canvas := hub.get_node_or_null("HubUI") as CanvasLayer
    if canvas == null:
        return
    if canvas.get_node_or_null("FieldRecordPanel") != null:
        _panel = canvas.get_node("FieldRecordPanel") as PanelContainer
        _body = _panel.find_child("RecordBody", true, false) as Label
        _refresh()
        return

    _panel = PanelContainer.new()
    _panel.name = "FieldRecordPanel"
    _panel.position = Vector2(28, 126)
    _panel.size = Vector2(236, 272)
    _panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    GameUISkin.style_panel(_panel, Color(0.32, 1.0, 0.78, 1.0))
    canvas.add_child(_panel)

    var margin := MarginContainer.new()
    margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
    margin.add_theme_constant_override("margin_left", 16)
    margin.add_theme_constant_override("margin_top", 14)
    margin.add_theme_constant_override("margin_right", 16)
    margin.add_theme_constant_override("margin_bottom", 14)
    _panel.add_child(margin)

    var column := VBoxContainer.new()
    column.mouse_filter = Control.MOUSE_FILTER_IGNORE
    column.add_theme_constant_override("separation", 8)
    margin.add_child(column)

    var heading := Label.new()
    heading.text = "FIELD RECORD"
    heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
    GameUISkin.style_heading(heading, Color(0.52, 1.0, 0.84, 1.0), 19)
    column.add_child(heading)

    _body = Label.new()
    _body.name = "RecordBody"
    _body.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _body.custom_minimum_size = Vector2(198, 208)
    GameUISkin.style_body(_body, 14)
    column.add_child(_body)
    _refresh()

func _refresh() -> void:
    if _body == null or not is_instance_valid(_body):
        return
    var lines: Array[String] = []
    lines.append("ミモ図鑑  %02d / %02d" % [SaveManager.get_unique_capture_count(), SaveManager.get_bestiary_total()])
    lines.append("妨害撃退  %03d" % SaveManager.get_total_interference_defeats())
    lines.append("")
    for stage_id in MissionRouter.get_mission_ids():
        var mission := MissionRouter.get_mission(stage_id)
        var name_value := String(mission.get("name", stage_id))
        if not MissionRouter.is_unlocked(stage_id):
            lines.append("%s\n  LOCKED" % name_value)
            continue
        var result := SaveManager.get_stage_result(stage_id)
        var rank := String(result.get("best_rank", "—"))
        var clears := SaveManager.get_stage_clear_count(stage_id)
        var sweeps := SaveManager.get_interference_sweeps(stage_id)
        lines.append("%s\n  RANK %s  CLEAR %d  SWEEP %d" % [name_value, rank, clears, sweeps])
    _body.text = "\n".join(lines)
