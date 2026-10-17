extends Node3D
class_name GadgetBase

signal activated
signal deactivated

var is_active := false

func activate() -> void:
    if is_active:
        return
    is_active = true
    activated.emit()

func deactivate() -> void:
    if not is_active:
        return
    is_active = false
    deactivated.emit()
