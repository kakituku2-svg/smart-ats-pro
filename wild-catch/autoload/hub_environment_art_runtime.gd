extends Node

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
    if node is Node3D and node.name == "FieldBase":
        call_deferred("_install", node)

func _install(hub: Node3D) -> void:
    for _i in range(2):
        await get_tree().process_frame
    if not is_instance_valid(hub) or hub.get_node_or_null("ProductionEnvironmentArt") != null:
        return
    var packed := ProductionArtPaths.hub_environment_scene()
    if packed == null:
        return
    var instance := packed.instantiate()
    if not (instance is Node3D):
        push_warning("Field Base production environment root must be Node3D")
        instance.queue_free()
        return
    var production := instance as Node3D
    production.name = "ProductionEnvironmentArt"
    hub.add_child(production)
    _hide_placeholder_architecture(hub)
    hub.set_meta("production_environment_active", true)

func _hide_placeholder_architecture(hub: Node3D) -> void:
    var floor := hub.get_node_or_null("HubFloor")
    if floor != null:
        for child in floor.get_children():
            if child is VisualInstance3D:
                (child as VisualInstance3D).visible = false
    for child in hub.get_children():
        if child is MeshInstance3D and String(child.name).begins_with("FloorLight"):
            (child as MeshInstance3D).visible = false
