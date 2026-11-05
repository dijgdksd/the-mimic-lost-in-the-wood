extends StaticBody3D

@export var item_id := "spare_key"
@export var display_name := "small brass key"
var collected := false

func get_interaction_text() -> String:
    return "Pick up the " + display_name

func interact(_player: Node) -> void:
    if collected:
        return
    collected = true
    GameState.add_item(item_id)
    queue_free()
