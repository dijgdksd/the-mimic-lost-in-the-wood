extends Node

signal objective_changed(text: String)
signal inventory_changed
signal escaped
signal caught

var inventory: Dictionary = {}
var objective := "Find the spare key in the house."
var has_escaped := false

func _ready() -> void:
    reset_run()

func reset_run() -> void:
    inventory.clear()
    has_escaped = false
    set_objective("Find the spare key in the house.")
    inventory_changed.emit()

func set_objective(text: String) -> void:
    objective = text
    objective_changed.emit(objective)

func add_item(item_id: String) -> void:
    if inventory.has(item_id):
        return
    inventory[item_id] = true
    inventory_changed.emit()
    if item_id == "spare_key":
        set_objective("Unlock the front door and escape.")

func has_item(item_id: String) -> bool:
    return inventory.get(item_id, false)

func win() -> void:
    if has_escaped:
        return
    has_escaped = true
    set_objective("You escaped... for now.")
    escaped.emit()

func notify_caught() -> void:
    caught.emit()
