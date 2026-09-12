extends Node

const STAGE_IDS := {
    "Stage2": &"stage2",
    "Stage3": &"stage3",
}
const KEEP_ROOTS := {
    "Player": true,
    "UI": true,
    "HexNet": true,
    "EchoScan": true,
    "MissionTargets": true,
    "FieldRelics": true,
    "InterferenceEnemies": true,
    "MissionHazards": true,
    "MissionAmbientFX": true,
    "RuntimeCheckpoints": true,
    "WorldEnvironment": true,
    "DirectionalLight3D": true,
}

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
    if node is Node3D and STAGE_IDS.has(String(node.name)):
        call_deferred("_install", node)

func _install(stage: Node3D) -> void:
    for _i in range(3):
        await get_tree().process_frame
    if not is_instance_valid(stage) or stage.get_node_or_null("ProductionEnvironmentArt") != null:
        return
    var stage_id := StringName(STAGE_IDS.get(String(stage.name), &""))
    var packed := ProductionArtPaths.mission_environment_scene(stage_id)
    if packed == null:
        return
    var instance := packed.instantiate()
    if not (instance is Node3D):
        push_warning("Mission production environment root must be Node3D")
        instance.queue_free()
        return
    var art := instance as Node3D
    art.name = "ProductionEnvironmentArt"
    stage.add_child(art)
    _hide_procedural_visuals(stage, art)
    stage.set_meta("production_environment_active", true)

func _hide_procedural_visuals(stage: Node3D, production_art: Node3D) -> void:
    for child in stage.get_children():
        if child == production_art:
            continue
        var name_value := String(child.name)
        if KEEP_ROOTS.has(name_value):
            continue
        if name_value == "MissionProps":
            if child is Node3D:
                (child as Node3D).visible = false
            continue
        if child is MeshInstance3D:
            (child as MeshInstance3D).visible = false
            continue
        if child is StaticBody3D or name_value.begins_with("WindTurbine"):
            _hide_visual_descendants(child)

func _hide_visual_descendants(root: Node) -> void:
    for child in root.get_children():
        if child is VisualInstance3D:
            (child as VisualInstance3D).visible = false
        _hide_visual_descendants(child)
