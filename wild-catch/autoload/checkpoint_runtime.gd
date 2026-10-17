extends Node

const ROOT_NAME := "RuntimeCheckpoints"
const CHECKPOINTS := {
    "Stage1": [
        ["RuinsGateCheckpoint", "古代ゲート", Vector3(-9.0, 0.35, -0.4), Color(0.24, 0.92, 0.72, 1.0)],
        ["ObservationCheckpoint", "観測台", Vector3(9.0, 2.70, -10.0), Color(0.34, 0.72, 1.0, 1.0)],
        ["WaterwayCheckpoint", "水路遺跡", Vector3(11.0, 0.42, 12.0), Color(0.25, 0.90, 1.0, 1.0)],
    ],
    "Stage2": [
        ["WindBridgeCheckpoint", "風橋中継点", Vector3(2.0, 1.45, -7.5), Color(0.34, 0.86, 1.0, 1.0)],
        ["NorthCliffCheckpoint", "北断崖展望点", Vector3(-12.0, 3.1, -12.0), Color(0.58, 0.94, 1.0, 1.0)],
        ["SouthRiseCheckpoint", "南風丘", Vector3(12.0, 1.55, 11.0), Color(1.0, 0.78, 0.30, 1.0)],
    ],
    "Stage3": [
        ["ResearchDeckCheckpoint", "研究デッキ", Vector3(0.0, 0.82, -8.0), Color(0.38, 1.0, 0.72, 1.0)],
        ["WestLabCheckpoint", "西研究棟", Vector3(-14.0, 2.65, 1.0), Color(0.72, 0.42, 1.0, 1.0)],
        ["RaisedPathCheckpoint", "湿地高架路", Vector3(0.0, 0.76, 8.0), Color(1.0, 0.42, 0.78, 1.0)],
    ],
}

var _installed_ids: Dictionary = {}

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().node_added.connect(_on_node_added)
    if get_tree().current_scene != null:
        _try_install(get_tree().current_scene)

func _on_node_added(node: Node) -> void:
    if node is Node3D and CHECKPOINTS.has(String(node.name)):
        call_deferred("_try_install", node)

func _try_install(stage: Node) -> void:
    if not is_instance_valid(stage) or not (stage is Node3D):
        return
    var stage_name := String(stage.name)
    if not CHECKPOINTS.has(stage_name):
        return
    var id := stage.get_instance_id()
    if _installed_ids.has(id):
        return
    _installed_ids[id] = true
    var stage3d := stage as Node3D
    if stage3d.get_node_or_null(ROOT_NAME) != null:
        return
    var root := Node3D.new()
    root.name = ROOT_NAME
    stage3d.add_child(root)
    var entries: Array = CHECKPOINTS.get(stage_name, [])
    for entry_value in entries:
        var entry: Array = entry_value
        _add_checkpoint(root, String(entry[0]), String(entry[1]), entry[2] as Vector3, entry[3] as Color)

func _add_checkpoint(parent: Node3D, node_name: String, label: String, position_value: Vector3, accent: Color) -> void:
    var checkpoint := FieldCheckpoint.new()
    checkpoint.name = node_name
    checkpoint.checkpoint_label = label
    checkpoint.position = position_value
    checkpoint.accent_color = accent
    parent.add_child(checkpoint)
