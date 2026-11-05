extends CharacterBody3D

@export var walk_speed := 3.2
@export var sprint_speed := 5.0
@export var crouch_speed := 1.6
@export var mouse_sensitivity := 0.0022
@export var gravity := 18.0

var look_pitch := 0.0
var flashlight_on := true
var can_move := true

@onready var camera: Camera3D = $Camera3D
@onready var ray: RayCast3D = $Camera3D/InteractRay
@onready var flashlight: SpotLight3D = $Camera3D/Flashlight
@onready var prompt: Label = $HUD/Prompt

func _ready() -> void:
    add_to_group("player")
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and can_move:
        rotate_y(-event.relative.x * mouse_sensitivity)
        look_pitch = clampf(look_pitch - event.relative.y * mouse_sensitivity, -1.35, 1.35)
        camera.rotation.x = look_pitch
    elif event.is_action_pressed("ui_cancel"):
        var next_mode := Input.MOUSE_MODE_VISIBLE if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
        Input.set_mouse_mode(next_mode)
    elif event.is_action_pressed("flashlight"):
        flashlight_on = not flashlight_on
        flashlight.visible = flashlight_on
    elif event.is_action_pressed("interact") and can_move:
        _try_interact()

func _physics_process(delta: float) -> void:
    if not can_move:
        velocity = Vector3.ZERO
        return
    var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var local_direction := Vector3(input_vector.x, 0.0, input_vector.y)
    var direction := (global_transform.basis * local_direction).normalized()
    var speed := walk_speed
    if Input.is_action_pressed("sprint"):
        speed = sprint_speed
    elif Input.is_action_pressed("crouch"):
        speed = crouch_speed
    velocity.x = direction.x * speed
    velocity.z = direction.z * speed
    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = 0.0
    move_and_slide()
    _update_prompt()

func _update_prompt() -> void:
    ray.force_raycast_update()
    if ray.is_colliding():
        var target := ray.get_collider()
        if target and target.has_method("get_interaction_text"):
            prompt.text = "[E] " + target.get_interaction_text()
            return
    prompt.text = ""

func _try_interact() -> void:
    ray.force_raycast_update()
    if ray.is_colliding():
        var target := ray.get_collider()
        if target and target.has_method("interact"):
            target.interact(self)

func set_controls_enabled(enabled: bool) -> void:
    can_move = enabled
