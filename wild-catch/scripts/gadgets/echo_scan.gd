extends GadgetBase
class_name EchoScan

signal scan_result(payload: Dictionary)
signal scan_empty

@export var max_range := 80.0
var _player: Node3D

func _ready() -> void:
    add_to_group("echo_scan")
    _player = get_tree().get_first_node_in_group("player") as Node3D

func _process(_delta: float) -> void:
    if Input.is_action_just_pressed("scan"):
        request_scan()

func request_scan() -> void:
    if not is_instance_valid(_player):
        _player = get_tree().get_first_node_in_group("player") as Node3D
    if not is_instance_valid(_player):
        scan_empty.emit()
        return
    AudioManager.play_event(&"scan")
    var nearest: MimoBase
    var nearest_distance := max_range
    for node in get_tree().get_nodes_in_group("mimo"):
        var mimo := node as MimoBase
        if mimo == null or mimo.state == MimoBase.State.CAPTURED:
            continue
        if bool(mimo.get_meta("scan_hidden", false)) and not mimo.is_lured():
            continue
        var distance := _player.global_position.distance_to(mimo.global_position)
        if distance < nearest_distance:
            nearest = mimo
            nearest_distance = distance
    _play_scan_feedback(nearest)
    if nearest == null:
        scan_empty.emit()
        return
    scan_result.emit(nearest.get_scan_payload(_player.global_position))

func _play_scan_feedback(target: MimoBase) -> void:
    var scene_root := get_tree().current_scene
    if scene_root == null:
        return
    var feedback := ScanFeedback.new()
    feedback.name = "EchoScanFeedback"
    scene_root.add_child(feedback)
    feedback.play(_player, target)
