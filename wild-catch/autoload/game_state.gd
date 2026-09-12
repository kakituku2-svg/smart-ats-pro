extends Node

signal capture_count_changed(current: int, total: int, mimo_id: StringName)
signal relic_count_changed(current: int, total: int, relic_id: StringName)
signal reward_unlocked(reward_id: StringName)
signal stage_cleared(stage_id: StringName)
signal stage_result_ready(stage_id: StringName, clear_time: float, relic_count: int, rank: String)

const STAGE1_TARGET_TOTAL := 6
const STAGE1_RELIC_TOTAL := 6
const STAGE1_RELIC_IDS := [
    &"sun_disc", &"gate_tablet", &"river_pearl", &"watch_eye", &"moss_seal", &"far_bank_coin"
]
const RUINS_CARTOGRAPHER := &"ruins_cartographer"

var captured_mimo: Dictionary = {}
var found_relics: Dictionary = {}
var current_stage_id: StringName = &"stage1"
var stage_target_total := STAGE1_TARGET_TOTAL
var stage_relic_total := STAGE1_RELIC_TOTAL
var _clear_emitted := false
var _stage_start_msec := 0

func mark_captured(mimo_id: StringName) -> bool:
    if captured_mimo.has(mimo_id):
        return false
    captured_mimo[mimo_id] = true
    SaveManager.record_capture(mimo_id)
    AudioManager.play_event(&"capture")
    capture_count_changed.emit(captured_mimo.size(), stage_target_total, mimo_id)
    if captured_mimo.size() >= stage_target_total and not _clear_emitted:
        _clear_emitted = true
        var clear_time := get_stage_elapsed_seconds()
        var rank := _calculate_stage_rank(clear_time, found_relics.size())
        SaveManager.record_stage_clear(current_stage_id)
        SaveManager.record_stage_result(current_stage_id, clear_time, found_relics.size(), rank)
        AudioManager.play_event(&"stage_clear")
        stage_result_ready.emit(current_stage_id, clear_time, found_relics.size(), rank)
        stage_cleared.emit(current_stage_id)
    return true

func mark_relic_found(relic_id: StringName) -> bool:
    if found_relics.has(relic_id):
        return false
    found_relics[relic_id] = true
    SaveManager.record_relic(relic_id)
    AudioManager.play_event(&"relic")
    relic_count_changed.emit(found_relics.size(), stage_relic_total, relic_id)
    _check_exploration_reward()
    return true

func is_captured(mimo_id: StringName) -> bool:
    return bool(captured_mimo.get(mimo_id, false))

func get_capture_count() -> int:
    return captured_mimo.size()

func get_relic_count() -> int:
    return found_relics.size()

func get_stage_elapsed_seconds() -> float:
    if _stage_start_msec <= 0:
        return 0.0
    return float(Time.get_ticks_msec() - _stage_start_msec) / 1000.0

func reset_stage_progress(stage_id: StringName = &"stage1", target_total: int = STAGE1_TARGET_TOTAL, relic_total: int = STAGE1_RELIC_TOTAL) -> void:
    current_stage_id = stage_id
    stage_target_total = target_total
    stage_relic_total = relic_total
    captured_mimo.clear()
    found_relics.clear()
    _restore_persistent_relics(stage_id, relic_total)
    _clear_emitted = false
    _stage_start_msec = Time.get_ticks_msec()
    capture_count_changed.emit(0, stage_target_total, &"")
    relic_count_changed.emit(found_relics.size(), stage_relic_total, &"")
    _check_exploration_reward()

func _restore_persistent_relics(stage_id: StringName, relic_total: int) -> void:
    if stage_id == &"stage1":
        for relic_id in STAGE1_RELIC_IDS:
            if SaveManager.has_relic(relic_id):
                found_relics[relic_id] = true
        return
    for i in range(relic_total):
        var relic_id := StringName("%s_relic_%02d" % [String(stage_id), i + 1])
        if SaveManager.has_relic(relic_id):
            found_relics[relic_id] = true

func _check_exploration_reward() -> void:
    if current_stage_id != &"stage1" or found_relics.size() < stage_relic_total:
        return
    if SaveManager.unlock_reward(RUINS_CARTOGRAPHER):
        AudioManager.play_event(&"unlock")
        reward_unlocked.emit(RUINS_CARTOGRAPHER)

func _calculate_stage_rank(clear_time: float, relic_count: int) -> String:
    var score := 0
    if clear_time <= 150.0:
        score += 3
    elif clear_time <= 240.0:
        score += 2
    elif clear_time <= 360.0:
        score += 1
    if relic_count >= stage_relic_total:
        score += 3
    elif relic_count >= maxi(stage_relic_total - 2, 1):
        score += 2
    elif relic_count >= maxi(int(ceil(float(stage_relic_total) * 0.33)), 1):
        score += 1
    if score >= 6:
        return "S"
    if score >= 4:
        return "A"
    if score >= 2:
        return "B"
    return "C"
