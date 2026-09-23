extends Node

const SecretShrineScript = preload("res://scripts/stage/secret_shrine.gd")

var _scan_timer := 0.0
var _bound_stage: Node3D
var _shrine: SecretShrine

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
    _scan_timer -= delta
    if _scan_timer > 0.0 and is_instance_valid(_bound_stage):
        return
    _scan_timer = 0.30
    _resolve_stage()

func _resolve_stage() -> void:
    var scene := get_tree().current_scene
    if scene == null:
        _bound_stage = null
        _shrine = null
        return
    var stage := scene.find_child("Stage1", true, false) as Node3D
    if stage == null:
        _bound_stage = null
        _shrine = null
        return
    if stage == _bound_stage and is_instance_valid(_shrine):
        return
    _bound_stage = stage
    var existing := stage.find_child("SecretCartographerShrine", true, false) as SecretShrine
    if existing != null:
        _shrine = existing
        return
    _shrine = SecretShrineScript.new() as SecretShrine
    _shrine.name = "SecretCartographerShrine"
    _shrine.position = Vector3(20.5, 0.45, -19.5)
    stage.add_child(_shrine)
    _shrine.shrine_awakened.connect(_on_shrine_awakened)

func _on_shrine_awakened(reward_id: StringName) -> void:
    if reward_id != &"hex_resonance":
        return
    for node in get_tree().get_nodes_in_group("hex_net"):
        var net := node as HexNet
        if net != null:
            net.refresh_persistent_upgrade()
    var scene := get_tree().current_scene
    if scene != null:
        var hud := scene.find_child("MobileHUD", true, false)
        if hud != null and hud.has_method("show_toast"):
            hud.call("show_toast", "SECRET SHRINE AWAKENED  •  HEX RESONANCE UNLOCKED")
        if hud != null and hud.has_method("show_gadget_status"):
            hud.call("show_gadget_status", "HEX NET UPGRADED  •  Combo window ↑  Step 3 reach ↑")
