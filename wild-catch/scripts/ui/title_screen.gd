extends Control

@onready var start_button: Button = $Center/Card/Content/StartButton

func _ready() -> void:
    start_button.pressed.connect(_start_game)
    start_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_accept"):
        _start_game()

func _start_game() -> void:
    AudioManager.play_event(&"transfer")
    get_tree().change_scene_to_file(MissionRouter.HUB_SCENE)
