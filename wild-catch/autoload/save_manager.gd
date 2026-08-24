extends Node

signal progress_saved

const SAVE_PATH := "user://wild_catch_progress.json"
const MIMO_IDS_BY_STAGE := {
    &"stage1": ["lumi", "goro", "boka", "nera", "moku", "raku"],
    &"stage2": ["aero", "kuru", "vivi", "toto", "nagi"],
    &"stage3": ["pico", "luna", "doro", "nix", "fufu", "zari", "ema"],
}
const MIMO_IDS := [
    "lumi", "goro", "boka", "nera", "moku", "raku",
    "aero", "kuru", "vivi", "toto", "nagi",
    "pico", "luna", "doro", "nix", "fufu", "zari", "ema",
]

var data: Dictionary = {}

func _ready() -> void:
    _load_or_create()

func record_capture(mimo_id: StringName) -> void:
    var key := String(mimo_id)
    if key not in MIMO_IDS:
        return
    var captured := data.get("captured_mimo", {}) as Dictionary
    if not captured.has(key):
        captured[key] = true
        data["total_unique_captures"] = int(data.get("total_unique_captures", 0)) + 1
    data["captured_mimo"] = captured
    _save()

func record_relic(relic_id: StringName) -> void:
    var key := String(relic_id)
    var relics := data.get("relics", {}) as Dictionary
    relics[key] = true
    data["relics"] = relics
    _save()

func record_stage_clear(stage_id: StringName) -> void:
    var clears := data.get("stage_clears", {}) as Dictionary
    var key := String(stage_id)
    clears[key] = int(clears.get(key, 0)) + 1
    data["stage_clears"] = clears
    _save()

func record_stage_result(stage_id: StringName, clear_time: float, relic_count: int, rank: String) -> void:
    var results := data.get("stage_results", {}) as Dictionary
    var key := String(stage_id)
    var previous := results.get(key, {}) as Dictionary
    var best_time := float(previous.get("best_time", 0.0))
    if best_time <= 0.0 or clear_time < best_time:
        previous["best_time"] = clear_time
    previous["best_relics"] = maxi(int(previous.get("best_relics", 0)), relic_count)
    previous["best_rank"] = _better_rank(String(previous.get("best_rank", "")), rank)
    previous["last_time"] = clear_time
    previous["last_relics"] = relic_count
    previous["last_rank"] = rank
    results[key] = previous
    data["stage_results"] = results
    _save()

func record_interference_defeat(stage_id: StringName, variant_id: StringName) -> void:
    var stage_key := String(stage_id)
    var defeats := data.get("interference_defeats", {}) as Dictionary
    var stage_entry := defeats.get(stage_key, {}) as Dictionary
    var variant_key := String(variant_id)
    stage_entry[variant_key] = int(stage_entry.get(variant_key, 0)) + 1
    stage_entry["total"] = int(stage_entry.get("total", 0)) + 1
    defeats[stage_key] = stage_entry
    data["interference_defeats"] = defeats
    data["total_interference_defeats"] = int(data.get("total_interference_defeats", 0)) + 1
    _save()

func record_interference_sweep(stage_id: StringName) -> void:
    var sweeps := data.get("interference_sweeps", {}) as Dictionary
    var key := String(stage_id)
    sweeps[key] = int(sweeps.get(key, 0)) + 1
    data["interference_sweeps"] = sweeps
    _save()

func get_interference_defeats(stage_id: StringName) -> int:
    var defeats := data.get("interference_defeats", {}) as Dictionary
    var stage_entry := defeats.get(String(stage_id), {}) as Dictionary
    return int(stage_entry.get("total", 0))

func get_interference_sweeps(stage_id: StringName) -> int:
    return int((data.get("interference_sweeps", {}) as Dictionary).get(String(stage_id), 0))

func get_total_interference_defeats() -> int:
    return int(data.get("total_interference_defeats", 0))

func unlock_reward(reward_id: StringName) -> bool:
    var unlocks := data.get("unlocks", {}) as Dictionary
    var key := String(reward_id)
    if bool(unlocks.get(key, false)):
        return false
    unlocks[key] = true
    data["unlocks"] = unlocks
    _save()
    return true

func has_unlock(reward_id: StringName) -> bool:
    return bool((data.get("unlocks", {}) as Dictionary).get(String(reward_id), false))

func has_captured(mimo_id: StringName) -> bool:
    return bool((data.get("captured_mimo", {}) as Dictionary).get(String(mimo_id), false))

func has_relic(relic_id: StringName) -> bool:
    return bool((data.get("relics", {}) as Dictionary).get(String(relic_id), false))

func get_unique_capture_count() -> int:
    return int(data.get("total_unique_captures", 0))

func get_relic_count() -> int:
    return (data.get("relics", {}) as Dictionary).size()

func get_stage_clear_count(stage_id: StringName) -> int:
    return int((data.get("stage_clears", {}) as Dictionary).get(String(stage_id), 0))

func get_stage_result(stage_id: StringName) -> Dictionary:
    return ((data.get("stage_results", {}) as Dictionary).get(String(stage_id), {}) as Dictionary).duplicate(true)

func get_bestiary_summary(stage_id: StringName = &"") -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    var ids: Array = MIMO_IDS
    if stage_id != &"" and MIMO_IDS_BY_STAGE.has(stage_id):
        ids = MIMO_IDS_BY_STAGE[stage_id]
    for id in ids:
        result.append({"id": id, "captured": has_captured(StringName(id))})
    return result

func get_bestiary_total() -> int:
    return MIMO_IDS.size()

func get_stage_bestiary_total(stage_id: StringName) -> int:
    return (MIMO_IDS_BY_STAGE.get(stage_id, []) as Array).size()

func reset_all_progress() -> void:
    data = _default_data()
    _save()

func _better_rank(old_rank: String, new_rank: String) -> String:
    var order := {"": 0, "C": 1, "B": 2, "A": 3, "S": 4}
    return new_rank if int(order.get(new_rank, 0)) >= int(order.get(old_rank, 0)) else old_rank

func _load_or_create() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        data = _default_data()
        _save()
        return
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        data = _default_data()
        return
    var parsed = JSON.parse_string(file.get_as_text())
    if parsed is Dictionary:
        data = parsed as Dictionary
        _migrate_data()
    else:
        data = _default_data()

func _migrate_data() -> void:
    var defaults := _default_data()
    for key in defaults.keys():
        if not data.has(key):
            data[key] = defaults[key]
    var captured := data.get("captured_mimo", {}) as Dictionary
    var valid_count := 0
    for id in MIMO_IDS:
        if bool(captured.get(id, false)):
            valid_count += 1
    data["total_unique_captures"] = valid_count
    data["version"] = 5
    _save()

func _save() -> void:
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        push_warning("SaveManager could not open save path")
        return
    file.store_string(JSON.stringify(data, "  "))
    progress_saved.emit()

func _default_data() -> Dictionary:
    return {
        "version": 5,
        "captured_mimo": {},
        "relics": {},
        "unlocks": {},
        "stage_clears": {},
        "stage_results": {},
        "interference_defeats": {},
        "interference_sweeps": {},
        "total_interference_defeats": 0,
        "total_unique_captures": 0,
    }
