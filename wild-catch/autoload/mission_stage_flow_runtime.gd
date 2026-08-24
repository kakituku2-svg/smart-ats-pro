extends Node

const STAGE_NAMES := {
    "Stage1": &"stage1",
    "Stage2": &"stage2",
    "Stage3": &"stage3",
}

var _current_stage_root: Node3D
var _current_stage_id: StringName = &""
var _extraction_started := false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().node_added.connect(_on_node_added)
    if not GameState.stage_cleared.is_connected(_on_stage_cleared):
        GameState.stage_cleared.connect(_on_stage_cleared)

func _on_node_added(node: Node) -> void:
    if node is Node3D and STAGE_NAMES.has(String(node.name)):
        call_deferred("_bind_stage", node)

func _bind_stage(stage: Node3D) -> void:
    if not is_instance_valid(stage):
        return
    _current_stage_root = stage
    _current_stage_id = StringName(STAGE_NAMES.get(String(stage.name), &""))
    _extraction_started = false
    call_deferred("_sync_hud")
    if MissionRouter.launch_from_hub and MissionRouter.get_pending_stage_id() == _current_stage_id:
        call_deferred("_play_arrival")

func _sync_hud() -> void:
    await get_tree().process_frame
    var hud := _find_mobile_hud(_current_stage_root)
    if hud == null:
        return
    hud.update_capture(GameState.get_capture_count(), GameState.stage_target_total)
    hud.update_relic(GameState.get_relic_count(), GameState.stage_relic_total)

func _find_mobile_hud(root: Node) -> MobileHUD:
    if root == null:
        return null
    if root is MobileHUD:
        return root as MobileHUD
    for child in root.get_children():
        var found := _find_mobile_hud(child)
        if found != null:
            return found
    return null

func _play_arrival() -> void:
    await get_tree().process_frame
    var player := get_tree().get_first_node_in_group("player") as PlayerController
    if player == null or not is_instance_valid(_current_stage_root):
        return
    var sequence := TransferSequence.new()
    sequence.name = "ArrivalTransferSequence"
    _current_stage_root.add_child(sequence)
    AudioManager.play_event(&"transfer")
    sequence.play_arrival(player)
    MissionRouter.launch_from_hub = false

func _on_stage_cleared(stage_id: StringName) -> void:
    if stage_id != _current_stage_id or _extraction_started:
        return
    _extraction_started = true
    call_deferred("_begin_extraction", stage_id)

func _begin_extraction(stage_id: StringName) -> void:
    var hud := _find_mobile_hud(_current_stage_root)
    if hud != null:
        hud.show_toast("MISSION COMPLETE  •  規定数確保  •  本拠地へ帰還します")
    await get_tree().create_timer(0.72).timeout
    if hud != null:
        var clear_panel := hud.get_node_or_null("ClearPanel") as Control
        if clear_panel != null:
            clear_panel.visible = false
        var scan_panel := hud.get_node_or_null("ScanPanel") as Control
        if scan_panel != null:
            scan_panel.visible = false
        var gadget_bar := hud.get_node_or_null("GadgetBar") as Control
        if gadget_bar != null:
            gadget_bar.visible = false
        var actions := hud.get_node_or_null("Actions") as Control
        if actions != null:
            actions.visible = false
        var stick := hud.get_node_or_null("MoveStick") as Control
        if stick != null:
            stick.visible = false
    await get_tree().create_timer(0.28).timeout
    var player := get_tree().get_first_node_in_group("player") as PlayerController
    if player == null or not is_instance_valid(_current_stage_root):
        MissionRouter.return_to_hub(stage_id)
        return
    var sequence := TransferSequence.new()
    sequence.name = "ExtractionTransferSequence"
    _current_stage_root.add_child(sequence)
    AudioManager.play_event(&"transfer_return")
    sequence.play_departure(player, func() -> void: MissionRouter.return_to_hub(stage_id))
