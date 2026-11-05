extends CharacterBody3D

@export var move_speed := 2.4
@export var notice_distance := 8.0
@export var catch_distance := 1.25
var player: Node3D
var active := true

func _ready() -> void:
    player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
    if not active or player == null or GameState.has_escaped:
        return
    var offset := player.global_position - global_position
    var distance := offset.length()
    if distance <= notice_distance:
        var direction := offset.normalized()
        velocity.x = direction.x * move_speed
        velocity.z = direction.z * move_speed
        if direction.length() > 0.01:
            look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
        if distance <= catch_distance:
            active = false
            GameState.notify_caught()
    else:
        velocity.x = move_toward(velocity.x, 0.0, move_speed * delta)
        velocity.z = move_toward(velocity.z, 0.0, move_speed * delta)
    if not is_on_floor():
        velocity.y -= 18.0 * delta
    else:
        velocity.y = 0.0
    move_and_slide()
