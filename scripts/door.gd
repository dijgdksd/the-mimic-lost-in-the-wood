extends StaticBody3D

@export var is_exit := true
@export var open_degrees := 92.0
var is_open := false
var busy := false

func get_interaction_text() -> String:
    if is_exit and not GameState.has_item("spare_key"):
        return "The door is locked"
    return "Open door" if not is_open else "Close door"

func interact(_player: Node) -> void:
    if busy:
        return
    if is_exit and not GameState.has_item("spare_key"):
        GameState.set_objective("The front door is locked. Find the spare key.")
        return
    busy = true
    is_open = not is_open
    var hinge: Node3D = get_parent()
    var target_angle := deg_to_rad(open_degrees) if is_open else 0.0
    var tween := create_tween()
    tween.tween_property(hinge, "rotation:y", target_angle, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    tween.finished.connect(func():
        busy = false
        if is_exit and is_open:
            GameState.win()
    )
