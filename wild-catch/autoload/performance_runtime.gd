extends Node

const SMALL_DECOR := {
    "GrassTufts": true,
    "ShrubClusters": true,
    "RuinPebbles": true,
    "SunFlowers": true,
    "CoralFlowers": true,
    "SkyFlowers": true,
    "WaterReeds": true,
}

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().node_added.connect(_on_node_added)
    call_deferred("_scan_existing")

func _scan_existing() -> void:
    var root := get_tree().current_scene
    if root == null:
        return
    _walk(root)

func _walk(node: Node) -> void:
    _optimize_node(node)
    for child in node.get_children():
        _walk(child)

func _on_node_added(node: Node) -> void:
    call_deferred("_optimize_node", node)

func _optimize_node(node: Node) -> void:
    if not (node is MultiMeshInstance3D):
        return
    var instance := node as MultiMeshInstance3D
    if not SMALL_DECOR.has(String(instance.name)):
        return
    instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    if OS.has_feature("mobile") or OS.has_feature("android"):
        instance.visibility_range_end = 42.0
        instance.visibility_range_end_margin = 6.0
