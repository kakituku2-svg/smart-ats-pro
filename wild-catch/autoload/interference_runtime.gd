extends Node

const STAGE_IDS := {
    "Stage1": &"stage1",
    "Stage2": &"stage2",
    "Stage3": &"stage3",
}
const SPAWNS := {
    "Stage1": [
        {"variant": &"guard_bug", "position": Vector3(-4.0, 0.45, 2.5), "color": Color(1.0, 0.35, 0.20, 1.0)},
        {"variant": &"guard_bug", "position": Vector3(15.0, 0.45, -5.5), "color": Color(1.0, 0.62, 0.18, 1.0)},
    ],
    "Stage2": [
        {"variant": &"wind_stinger", "position": Vector3(-8.0, 1.15, 4.0), "color": Color(0.30, 0.78, 1.0, 1.0)},
        {"variant": &"wind_stinger", "position": Vector3(7.0, 1.55, -8.0), "color": Color(0.36, 0.92, 1.0, 1.0)},
        {"variant": &"guard_bug", "position": Vector3(13.0, 0.45, 9.0), "color": Color(1.0, 0.68, 0.22, 1.0)},
    ],
    "Stage3": [
        {"variant": &"glow_leech", "position": Vector3(-10.0, 0.45, -5.0), "color": Color(0.78, 0.35, 1.0, 1.0)},
        {"variant": &"glow_leech", "position": Vector3(8.0, 0.45, -11.0), "color": Color(0.96, 0.30, 0.78, 1.0)},
        {"variant": &"wind_stinger", "position": Vector3(14.0, 1.10, 8.0), "color": Color(0.36, 0.86, 1.0, 1.0)},
        {"variant": &"guard_bug", "position": Vector3(-15.0, 0.45, 10.0), "color": Color(1.0, 0.42, 0.22, 1.0)},
    ],
}

var _remaining_by_stage_instance: Dictionary = {}

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
    if node is Node3D and SPAWNS.has(String(node.name)):
        call_deferred("_install", node)

func _install(stage: Node3D) -> void:
    if not is_instance_valid(stage) or stage.get_node_or_null("InterferenceEnemies") != null:
        return
    var stage_name := String(stage.name)
    var stage_id := StringName(STAGE_IDS.get(stage_name, &"stage1"))
    var root := Node3D.new()
    root.name = "InterferenceEnemies"
    stage.add_child(root)
    var entries: Array = SPAWNS.get(stage_name, [])
    var instance_id := stage.get_instance_id()
    _remaining_by_stage_instance[instance_id] = entries.size()
    stage.tree_exited.connect(func() -> void: _remaining_by_stage_instance.erase(instance_id))
    for i in range(entries.size()):
        var entry := entries[i] as Dictionary
        var enemy := InterferenceEnemy.new()
        enemy.variant_id = StringName(entry.get("variant", &"guard_bug"))
        enemy.name = "%s%02d" % [_node_prefix(enemy.variant_id), i + 1]
        enemy.position = entry.get("position", Vector3.ZERO) as Vector3
        enemy.accent_color = entry.get("color", Color(1.0, 0.35, 0.20, 1.0)) as Color
        enemy.defeated.connect(_on_enemy_defeated.bind(stage_id, instance_id))
        enemy.damaged.connect(_on_enemy_damaged)
        root.add_child(enemy)

func _node_prefix(variant_id: StringName) -> String:
    match variant_id:
        &"wind_stinger": return "WindStinger"
        &"glow_leech": return "GlowLeech"
        _: return "GuardBug"

func _on_enemy_damaged(enemy: InterferenceEnemy, health: int) -> void:
    var hud := _find_mobile_hud()
    if hud != null:
        hud.show_toast("%sにパルス命中  •  耐久 %d/%d" % [enemy.display_name, health, enemy.max_health])

func _on_enemy_defeated(enemy: InterferenceEnemy, stage_id: StringName, stage_instance_id: int) -> void:
    SaveManager.record_interference_defeat(stage_id, enemy.variant_id)
    var hud := _find_mobile_hud()
    var remaining := maxi(0, int(_remaining_by_stage_instance.get(stage_instance_id, 1)) - 1)
    _remaining_by_stage_instance[stage_instance_id] = remaining
    if hud != null:
        hud.show_toast("%sを撃退！  •  妨害残数 %d" % [enemy.display_name, remaining])
    if remaining <= 0:
        SaveManager.record_interference_sweep(stage_id)
        AudioManager.play_event(&"unlock")
        if hud != null:
            hud.show_gadget_status("妨害体を全排除！  •  FIELD SWEEP BONUS 記録更新")
            hud.show_toast("FIELD SWEEP COMPLETE！")

func _find_mobile_hud() -> MobileHUD:
    for node in get_tree().get_nodes_in_group("player"):
        var root := node.get_parent()
        while root != null:
            var found := root.find_child("MobileHUD", true, false) as MobileHUD
            if found != null:
                return found
            root = root.get_parent()
    return null
