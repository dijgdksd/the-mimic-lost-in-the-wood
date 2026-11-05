extends Node3D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const PICKUP_SCRIPT = preload("res://scripts/pickup.gd")
const DOOR_SCRIPT = preload("res://scripts/door.gd")
const ENEMY_SCRIPT = preload("res://scripts/enemy.gd")

var player: CharacterBody3D
var key_node: StaticBody3D
var enemy: CharacterBody3D
var objective_label: Label
var message_label: Label
var message_timer := 0.0

func _ready() -> void:
    _setup_inputs()
    _setup_world()
    _setup_hud()
    _spawn_player()
    _build_house()
    _spawn_key()
    _spawn_enemy()
    GameState.objective_changed.connect(_on_objective_changed)
    GameState.escaped.connect(_on_escaped)
    GameState.caught.connect(_on_caught)
    _on_objective_changed(GameState.objective)

func _process(delta: float) -> void:
    if message_timer > 0.0:
        message_timer -= delta
        if message_timer <= 0.0 and not GameState.has_escaped:
            message_label.text = ""

func _setup_inputs() -> void:
    _bind_key("move_forward", KEY_W)
    _bind_key("move_back", KEY_S)
    _bind_key("move_left", KEY_A)
    _bind_key("move_right", KEY_D)
    _bind_key("sprint", KEY_SHIFT)
    _bind_key("crouch", KEY_CTRL)
    _bind_key("interact", KEY_E)
    _bind_key("flashlight", KEY_F)

func _bind_key(action: String, key: Key) -> void:
    if not InputMap.has_action(action):
        InputMap.add_action(action)
    var event := InputEventKey.new()
    event.physical_keycode = key
    InputMap.action_add_event(action, event)

func _setup_world() -> void:
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color(0.012, 0.018, 0.02)
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.18, 0.22, 0.24)
    environment.ambient_light_energy = 0.35
    environment.fog_enabled = true
    environment.fog_light_color = Color(0.08, 0.12, 0.13)
    environment.fog_density = 0.025
    var world := WorldEnvironment.new()
    world.environment = environment
    add_child(world)
    var moon := DirectionalLight3D.new()
    moon.rotation_degrees = Vector3(-48.0, -25.0, 0.0)
    moon.light_color = Color(0.48, 0.58, 0.63)
    moon.light_energy = 0.45
    moon.shadow_enabled = true
    add_child(moon)

func _setup_hud() -> void:
    var canvas := CanvasLayer.new()
    canvas.name = "HUD"
    add_child(canvas)
    objective_label = Label.new()
    objective_label.position = Vector2(24, 22)
    objective_label.add_theme_font_size_override("font_size", 20)
    canvas.add_child(objective_label)
    var center := Label.new()
    center.text = "+"
    center.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    center.position = Vector2(-5, -12)
    center.add_theme_font_size_override("font_size", 22)
    canvas.add_child(center)
    var prompt := Label.new()
    prompt.name = "Prompt"
    prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
    prompt.position = Vector2(-150, -90)
    prompt.size = Vector2(300, 36)
    prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    prompt.add_theme_font_size_override("font_size", 18)
    canvas.add_child(prompt)
    message_label = Label.new()
    message_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    message_label.position = Vector2(-240, 80)
    message_label.size = Vector2(480, 100)
    message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    message_label.add_theme_font_size_override("font_size", 30)
    message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    canvas.add_child(message_label)

func _spawn_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Player"
    player.set_script(PLAYER_SCRIPT)
    player.position = Vector3(0, 0.1, 3.5)
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.32
    capsule.height = 1.8
    var collision := CollisionShape3D.new()
    collision.shape = capsule
    collision.position.y = 0.9
    player.add_child(collision)
    var camera := Camera3D.new()
    camera.name = "Camera3D"
    camera.position.y = 1.58
    camera.current = true
    player.add_child(camera)
    var ray := RayCast3D.new()
    ray.name = "InteractRay"
    ray.target_position = Vector3(0, 0, -2.6)
    ray.collision_mask = 3
    ray.collide_with_areas = true
    camera.add_child(ray)
    var light := SpotLight3D.new()
    light.name = "Flashlight"
    light.position = Vector3(0, -0.08, -0.12)
    light.rotation.x = deg_to_rad(-2)
    light.spot_range = 15.0
    light.spot_angle = 34.0
    light.light_energy = 2.3
    light.shadow_enabled = true
    camera.add_child(light)
    var hud := get_node("HUD")
    player.add_child(hud)
    # Keep the HUD in screen space while the player moves.
    hud.top_level = true
    add_child(player)

func _build_house() -> void:
    _make_box("Floor", Vector3(0, -0.2, 0), Vector3(12, 0.4, 16), Color(0.16, 0.14, 0.12))
    _make_box("Left wall", Vector3(-6, 1.5, 0), Vector3(0.3, 3, 16), Color(0.20, 0.19, 0.17))
    _make_box("Right wall", Vector3(6, 1.5, 0), Vector3(0.3, 3, 16), Color(0.20, 0.19, 0.17))
    _make_box("Back wall", Vector3(0, 1.5, 8), Vector3(12, 3, 0.3), Color(0.19, 0.17, 0.15))
    _make_box("Front wall left", Vector3(-4, 1.5, -8), Vector3(4, 3, 0.3), Color(0.19, 0.17, 0.15))
    _make_box("Front wall right", Vector3(4, 1.5, -8), Vector3(4, 3, 0.3), Color(0.19, 0.17, 0.15))
    _make_box("Ceiling", Vector3(0, 3.15, 0), Vector3(12, 0.3, 16), Color(0.11, 0.11, 0.10))
    _make_box("Kitchen island", Vector3(-3.2, 0.65, -1.0), Vector3(2.0, 1.3, 1.0), Color(0.22, 0.17, 0.13))
    _make_box("Dining table", Vector3(2.8, 0.75, 2.0), Vector3(2.2, 1.5, 1.4), Color(0.19, 0.14, 0.11))
    _make_box("Hall divider", Vector3(0, 1.4, -4.7), Vector3(7.5, 2.8, 0.2), Color(0.16, 0.16, 0.15))
    # Leave a central opening in the divider to guide the player toward the front door.
    _make_box("Divider left", Vector3(-4.3, 1.4, -4.7), Vector3(3.0, 2.8, 0.2), Color(0.16, 0.16, 0.15))
    _make_lamp(Vector3(-2.2, 2.72, 1.8), Color(0.78, 0.58, 0.34))
    _make_lamp(Vector3(3.4, 2.72, -3.2), Color(0.34, 0.47, 0.52))
    _make_tree(Vector3(-3.5, 0, -12.0), 2.7)
    _make_tree(Vector3(3.6, 0, -14.0), 3.1)
    _make_tree(Vector3(-7.3, 0, -8.8), 3.4)
    _make_tree(Vector3(7.1, 0, -11.0), 2.4)
    _make_box("Forest path", Vector3(0, -0.28, -12.5), Vector3(5, 0.12, 10), Color(0.10, 0.12, 0.10), false)
    var hinge := Node3D.new()
    hinge.name = "DoorHinge"
    hinge.position = Vector3(0.9, 0, -8)
    add_child(hinge)
    var door := StaticBody3D.new()
    door.name = "ExitDoor"
    door.set_script(DOOR_SCRIPT)
    door.position = Vector3(-0.9, 1.1, 0)
    door.collision_layer = 1
    door.collision_mask = 1
    hinge.add_child(door)
    _add_box_visual(door, Vector3.ZERO, Vector3(1.8, 2.2, 0.18), Color(0.24, 0.12, 0.08), true)
    _make_box("Door step", Vector3(0, 0.02, -8.5), Vector3(2.2, 0.12, 0.9), Color(0.22, 0.20, 0.17), false)

func _spawn_key() -> void:
    key_node = StaticBody3D.new()
    key_node.name = "SpareKey"
    key_node.set_script(PICKUP_SCRIPT)
    key_node.collision_layer = 2
    key_node.collision_mask = 0
    key_node.position = Vector3(-3.2, 1.42, -1.0)
    add_child(key_node)
    var shape := SphereShape3D.new()
    shape.radius = 0.2
    var collision := CollisionShape3D.new()
    collision.shape = shape
    key_node.add_child(collision)
    var mesh := MeshInstance3D.new()
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = 0.045
    cylinder.bottom_radius = 0.045
    cylinder.height = 0.48
    mesh.mesh = cylinder
    mesh.rotation_degrees.z = 90
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.78, 0.56, 0.14)
    material.metallic = 0.75
    material.roughness = 0.25
    mesh.material_override = material
    key_node.add_child(mesh)

func _spawn_enemy() -> void:
    enemy = CharacterBody3D.new()
    enemy.name = "TheMimic"
    enemy.set_script(ENEMY_SCRIPT)
    enemy.position = Vector3(0, 0, -13.8)
    enemy.collision_layer = 1
    enemy.collision_mask = 1
    var shape := CapsuleShape3D.new()
    shape.radius = 0.42
    shape.height = 2.1
    var collision := CollisionShape3D.new()
    collision.shape = shape
    collision.position.y = 1.05
    enemy.add_child(collision)
    var body := MeshInstance3D.new()
    var body_mesh := CapsuleMesh.new()
    body_mesh.radius = 0.42
    body_mesh.height = 2.1
    body.mesh = body_mesh
    body.position.y = 1.05
    var dark := StandardMaterial3D.new()
    dark.albedo_color = Color(0.018, 0.022, 0.022)
    dark.roughness = 0.95
    body.material_override = dark
    enemy.add_child(body)
    var eyes := MeshInstance3D.new()
    var eye_mesh := SphereMesh.new()
    eye_mesh.radius = 0.07
    eye_mesh.height = 0.14
    eyes.mesh = eye_mesh
    eyes.position = Vector3(0, 1.45, -0.36)
    var eye_material := StandardMaterial3D.new()
    eye_material.albedo_color = Color(0.8, 0.03, 0.015)
    eye_material.emission_enabled = true
    eye_material.emission = Color(0.9, 0.02, 0.01)
    eye_material.emission_energy_multiplier = 1.8
    eyes.material_override = eye_material
    enemy.add_child(eyes)
    add_child(enemy)

func _make_box(label: String, position: Vector3, size: Vector3, color: Color, solid := true) -> void:
    var body := StaticBody3D.new()
    body.name = label
    body.position = position
    if solid:
        body.collision_layer = 1
        var shape := BoxShape3D.new()
        shape.size = size
        var collision := CollisionShape3D.new()
        collision.shape = shape
        body.add_child(collision)
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    mesh.mesh = box
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.9
    mesh.material_override = material
    body.add_child(mesh)
    add_child(body)

func _add_box_visual(parent: Node3D, offset: Vector3, size: Vector3, color: Color, solid: bool) -> void:
    if solid:
        var shape := BoxShape3D.new()
        shape.size = size
        var collision := CollisionShape3D.new()
        collision.shape = shape
        collision.position = offset
        parent.add_child(collision)
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    mesh.mesh = box
    mesh.position = offset
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.8
    mesh.material_override = material
    parent.add_child(mesh)

func _make_lamp(position: Vector3, color: Color) -> void:
    var lamp := OmniLight3D.new()
    lamp.position = position
    lamp.light_color = color
    lamp.light_energy = 1.15
    lamp.omni_range = 7.5
    lamp.shadow_enabled = true
    add_child(lamp)

func _make_tree(position: Vector3, height: float) -> void:
    var trunk := StaticBody3D.new()
    trunk.position = position + Vector3(0, height * 0.5, 0)
    var shape := CylinderShape3D.new()
    shape.radius = 0.28
    shape.height = height
    var collision := CollisionShape3D.new()
    collision.shape = shape
    trunk.add_child(collision)
    var mesh := MeshInstance3D.new()
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = 0.12
    cylinder.bottom_radius = 0.32
    cylinder.height = height
    mesh.mesh = cylinder
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.09, 0.08, 0.065)
    material.roughness = 1.0
    mesh.material_override = material
    trunk.add_child(mesh)
    add_child(trunk)

func _on_objective_changed(text: String) -> void:
    if is_instance_valid(objective_label):
        objective_label.text = "OBJECTIVE  •  " + text

func _on_caught() -> void:
    if GameState.has_escaped:
        return
    message_label.text = "Something found you.\nYou wake where you began..."
    message_timer = 3.0
    player.global_position = Vector3(0, 0.1, 3.5)
    player.velocity = Vector3.ZERO
    enemy.global_position = Vector3(0, 0, -13.8)
    enemy.active = true

func _on_escaped() -> void:
    message_label.text = "YOU ESCAPED\nThe trees swallowed the house behind you."
    message_timer = 9999.0
    player.set_controls_enabled(false)
