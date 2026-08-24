extends Node

signal settings_changed

const SETTINGS_PATH := "user://wild_catch_settings.json"
const INPUT_PROFILE_VERSION := 2

var master_volume := 0.85
var camera_sensitivity := 0.65
var camera_shake_enabled := true
var hitstop_enabled := true
var ui_scale := 1.0

func _ready() -> void:
    _load()
    apply_audio()

func apply_audio() -> void:
    var bus := AudioServer.get_bus_index("Master")
    if bus >= 0:
        AudioServer.set_bus_volume_db(bus, linear_to_db(clampf(master_volume, 0.001, 1.0)))

func set_master_volume(value: float) -> void:
    master_volume = clampf(value, 0.0, 1.0)
    apply_audio()
    _save_and_emit()

func set_camera_sensitivity(value: float) -> void:
    camera_sensitivity = clampf(value, 0.30, 1.20)
    _save_and_emit()

func set_camera_shake(enabled: bool) -> void:
    camera_shake_enabled = enabled
    _save_and_emit()

func set_hitstop(enabled: bool) -> void:
    hitstop_enabled = enabled
    _save_and_emit()

func set_ui_scale(value: float) -> void:
    ui_scale = clampf(value, 0.85, 1.25)
    _save_and_emit()

func reset_defaults() -> void:
    master_volume = 0.85
    camera_sensitivity = 0.65
    camera_shake_enabled = true
    hitstop_enabled = true
    ui_scale = 1.0
    apply_audio()
    _save_and_emit()

func _save_and_emit() -> void:
    _save()
    settings_changed.emit()

func _save() -> void:
    var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
    if file == null:
        push_warning("SettingsManager could not open settings path")
        return
    file.store_string(JSON.stringify({
        "input_profile_version": INPUT_PROFILE_VERSION,
        "master_volume": master_volume,
        "camera_sensitivity": camera_sensitivity,
        "camera_shake_enabled": camera_shake_enabled,
        "hitstop_enabled": hitstop_enabled,
        "ui_scale": ui_scale,
    }, "  "))

func _load() -> void:
    if not FileAccess.file_exists(SETTINGS_PATH):
        _save()
        return
    var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
    if file == null:
        return
    var parsed = JSON.parse_string(file.get_as_text())
    if not parsed is Dictionary:
        return
    var data := parsed as Dictionary
    var input_profile_version := int(data.get("input_profile_version", 1))
    master_volume = clampf(float(data.get("master_volume", master_volume)), 0.0, 1.0)
    var loaded_sensitivity := float(data.get("camera_sensitivity", camera_sensitivity))
    if input_profile_version < INPUT_PROFILE_VERSION:
        # v1 used a much faster camera base and a wider sensitivity range.
        # Re-map legacy values so an upgrade cannot preserve the old spin-heavy feel.
        loaded_sensitivity = minf(loaded_sensitivity * 0.65, 0.80)
    camera_sensitivity = clampf(loaded_sensitivity, 0.30, 1.20)
    camera_shake_enabled = bool(data.get("camera_shake_enabled", camera_shake_enabled))
    hitstop_enabled = bool(data.get("hitstop_enabled", hitstop_enabled))
    ui_scale = clampf(float(data.get("ui_scale", ui_scale)), 0.85, 1.25)
    if input_profile_version < INPUT_PROFILE_VERSION:
        _save()
