extends Node

signal mission_selected(stage_id: StringName)
signal mission_launching(stage_id: StringName)
signal mission_returning(stage_id: StringName)

const HUB_SCENE := "res://scenes/hub/hub.tscn"
const LOADING_SCENE := "res://scenes/ui/mission_loading.tscn"

const MISSIONS := {
    &"stage1": {
        "name": "トロピカル遺跡パーク",
        "subtitle": "緑に沈んだ古代観測区",
        "scene": "res://scenes/stage1/stage1.tscn",
        "target_total": 6,
        "relic_total": 6,
        "interference_total": 2,
        "objective": "捕獲対象6体を確保せよ",
        "brief": "遺跡・水路・高台を移動するミモを追跡し、規定数を捕獲してください。",
        "accent": Color(0.24, 0.94, 0.66, 1.0),
        "unlocked_by": &"",
    },
    &"stage2": {
        "name": "スカイウィンド峡谷",
        "subtitle": "風車と断崖の空中回廊",
        "scene": "res://scenes/stage2/stage2.tscn",
        "target_total": 5,
        "relic_total": 4,
        "interference_total": 3,
        "objective": "捕獲対象5体を確保せよ",
        "brief": "強風で逃走ルートが変化します。妨害生物を排除しながら高低差を利用してください。",
        "accent": Color(0.35, 0.78, 1.0, 1.0),
        "unlocked_by": &"stage1",
    },
    &"stage3": {
        "name": "ネオン湿地研究区",
        "subtitle": "夜光植物に覆われた旧研究施設",
        "scene": "res://scenes/stage3/stage3.tscn",
        "target_total": 7,
        "relic_total": 5,
        "interference_total": 4,
        "objective": "捕獲対象7体を確保せよ",
        "brief": "暗所と発光植物を利用するミモが出現。索敵と妨害対処の両立が必要です。",
        "accent": Color(0.77, 0.42, 1.0, 1.0),
        "unlocked_by": &"stage2",
    },
}

var pending_stage_id: StringName = &"stage1"
var returning_from_stage_id: StringName = &""
var launch_from_hub := false

func get_mission(stage_id: StringName) -> Dictionary:
    return (MISSIONS.get(stage_id, MISSIONS[&"stage1"]) as Dictionary).duplicate(true)

func get_mission_ids() -> Array[StringName]:
    return [&"stage1", &"stage2", &"stage3"]

func is_unlocked(stage_id: StringName) -> bool:
    var mission := get_mission(stage_id)
    var prerequisite := StringName(mission.get("unlocked_by", &""))
    if prerequisite == &"":
        return true
    return SaveManager.get_stage_clear_count(prerequisite) > 0

func select_mission(stage_id: StringName) -> void:
    if not MISSIONS.has(stage_id):
        return
    pending_stage_id = stage_id
    mission_selected.emit(stage_id)

func launch_selected_mission() -> void:
    if not is_unlocked(pending_stage_id):
        AudioManager.play_event(&"warning")
        return
    launch_from_hub = true
    mission_launching.emit(pending_stage_id)
    AudioManager.play_event(&"transfer")
    get_tree().change_scene_to_file(LOADING_SCENE)

func load_pending_stage() -> void:
    var mission := get_mission(pending_stage_id)
    var scene_path := String(mission.get("scene", ""))
    if scene_path == "" or not ResourceLoader.exists(scene_path):
        push_error("Mission scene missing: %s" % scene_path)
        get_tree().change_scene_to_file(HUB_SCENE)
        return
    get_tree().change_scene_to_file(scene_path)

func return_to_hub(stage_id: StringName = &"") -> void:
    returning_from_stage_id = stage_id
    launch_from_hub = false
    mission_returning.emit(stage_id)
    AudioManager.play_event(&"transfer_return")
    get_tree().change_scene_to_file(HUB_SCENE)

func get_pending_stage_id() -> StringName:
    return pending_stage_id
