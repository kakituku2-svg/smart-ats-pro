extends Node

const STAGE_HAZARDS := {
    "Stage2": [
        [MissionHazardZone.Kind.UPDRAFT, Vector3(-9.0, 0.0, -5.0), 3.4, Color(0.28, 0.86, 1.0, 1.0)],
        [MissionHazardZone.Kind.UPDRAFT, Vector3(7.0, 0.0, -10.0), 3.0, Color(0.40, 0.96, 1.0, 1.0)],
        [MissionHazardZone.Kind.UPDRAFT, Vector3(12.0, 0.0, 12.0), 3.8, Color(0.24, 0.72, 1.0, 1.0)],
    ],
    "Stage3": [
        [MissionHazardZone.Kind.GLOW_MUD, Vector3(-7.0, 0.0, 9.0), 3.8, Color(0.34, 1.0, 0.70, 1.0)],
        [MissionHazardZone.Kind.GLOW_MUD, Vector3(8.0, 0.0, 14.0), 4.1, Color(0.72, 0.38, 1.0, 1.0)],
        [MissionHazardZone.Kind.GLOW_MUD, Vector3(-15.0, 0.0, -9.0), 3.2, Color(1.0, 0.34, 0.76, 1.0)],
    ],
}

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
    if node is Node3D and STAGE_HAZARDS.has(String(node.name)):
        call_deferred("_install", node)

func _install(stage: Node3D) -> void:
    if not is_instance_valid(stage) or stage.get_node_or_null("MissionHazards") != null:
        return
    var root := Node3D.new()
    root.name = "MissionHazards"
    stage.add_child(root)
    var entries: Array = STAGE_HAZARDS.get(String(stage.name), [])
    for i in range(entries.size()):
        var entry: Array = entries[i]
        var kind_value := int(entry[0])
        var hazard := MissionHazardZone.new()
        hazard.name = "%s%02d" % ["Updraft" if kind_value == MissionHazardZone.Kind.UPDRAFT else "GlowMud", i + 1]
        hazard.kind = kind_value
        hazard.position = entry[1] as Vector3
        hazard.radius = float(entry[2])
        hazard.accent_color = entry[3] as Color
        hazard.strength = 6.4 if kind_value == MissionHazardZone.Kind.UPDRAFT else 0.0
        root.add_child(hazard)
