extends Node

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
    if node is InterferenceEnemy:
        call_deferred("_install", node)

func _install(enemy: InterferenceEnemy) -> void:
    await get_tree().process_frame
    if not is_instance_valid(enemy):
        return
    var visual := enemy.get_node_or_null("Visual") as Node3D
    if visual == null or visual.get_node_or_null("ProductionArt") != null:
        return
    var packed := ProductionArtPaths.interference_scene(enemy.variant_id)
    if packed == null:
        return
    var instance := packed.instantiate()
    if not (instance is Node3D):
        push_warning("Interference production art root must be Node3D")
        instance.queue_free()
        return
    for child in visual.get_children():
        if child is VisualInstance3D:
            (child as VisualInstance3D).visible = false
        elif child is Node3D:
            _hide_visual_descendants(child)
    var production := instance as Node3D
    production.name = "ProductionArt"
    visual.add_child(production)
    enemy.set_meta("production_art_active", true)

func _hide_visual_descendants(root: Node) -> void:
    for child in root.get_children():
        if child is VisualInstance3D:
            (child as VisualInstance3D).visible = false
        _hide_visual_descendants(child)
