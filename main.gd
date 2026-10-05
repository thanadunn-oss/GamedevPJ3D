extends Node3D

## Gameplay controller: edit visuals in Player/Obstacle/Coin/RoadSection scenes.
const LANES := [-3.0, 0.0, 3.0]
@export var run_speed := 12.0
@export var jump_power := 9.0
@export var gravity := 24.0
@export var obstacle_scene: PackedScene
@export var coin_scene: PackedScene
@onready var player: Node3D = $Player
@onready var moving_objects: Node3D = $MovingObjects
@onready var score_label: Label = $UI/ScoreLabel
@onready var state_label: Label = $UI/StateLabel
@onready var restart_button: Button = $UI/RestartButton
var lane := 1
var player_y := 0.0
var vertical_velocity := 0.0
var score := 0
var game_over := false
var elapsed := 0.0
var next_spawn := 1.3
var hazards: Array[Node3D] = []
var pickups: Array[Node3D] = []

func _ready() -> void:

	restart_button.pressed.connect(restart)
	spawn_hazard(0, 18.0)
	spawn_pickup(2, 10.0)
	update_ui()

func spawn_hazard(lane_index: int, z: float) -> void:

	var object := obstacle_scene.instantiate() as Node3D
	object.position = Vector3(LANES[lane_index], 0, z)
	object.set_meta("lane", lane_index)
	moving_objects.add_child(object)
	hazards.append(object)

func spawn_pickup(lane_index: int, z: float) -> void:

	var object := coin_scene.instantiate() as Node3D
	object.position = Vector3(LANES[lane_index], 1.2, z)
	object.set_meta("lane", lane_index)
	moving_objects.add_child(object)
	pickups.append(object)

func _process(delta: float) -> void:

	if game_over:
		return
	elapsed += delta
	if Input.is_action_just_pressed("ui_left"):
		lane = max(0, lane - 1)
	if Input.is_action_just_pressed("ui_right"):
		lane = min(2, lane + 1)
	if (Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_up")) and player_y <= 0.02:
		vertical_velocity = jump_power
	vertical_velocity -= gravity * delta
	player_y = maxf(0.0, player_y + vertical_velocity * delta)
	if player_y == 0.0:
		vertical_velocity = 0.0
	player.position.x = move_toward(player.position.x, LANES[lane], 15.0 * delta)
	player.position.y = player_y
	player.rotation_degrees.z = sin(elapsed * 10.0) * 4.0
	move_objects(delta)
	if elapsed > next_spawn:
		next_spawn = elapsed + randf_range(0.78, 1.25)
		if randf() < 0.60:
			spawn_hazard(randi_range(0, 2), 31.0)
		else:
			spawn_pickup(randi_range(0, 2), 31.0)
	update_ui()

func move_objects(delta: float) -> void:

	for object in hazards.duplicate():
		object.position.z -= run_speed * delta
		if object.position.z < -5.0:
			hazards.erase(object); object.queue_free()
		elif object.position.z < 1.0 and object.position.z > -1.0 and object.get_meta("lane") == lane and player_y < 1.1:
			end_game()
	for object in pickups.duplicate():
		object.position.z -= run_speed * delta
		object.rotation.y += delta * 5.0
		if object.position.z < -5.0:
			pickups.erase(object); object.queue_free()
		elif object.position.z < 1.0 and object.position.z > -1.0 and object.get_meta("lane") == lane and player_y < 1.3:
			score += 10; pickups.erase(object); object.queue_free()

func end_game() -> void:

	game_over = true
	state_label.text = "GAME OVER\nชนสิ่งกีดขวาง!"
	restart_button.visible = true

func restart() -> void:

	get_tree().reload_current_scene()

func _unhandled_key_input(event: InputEvent) -> void:

	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		restart()

func update_ui() -> void:

	score_label.text = "คะแนน: %d    ระยะทาง: %dm" % [score, int(elapsed * run_speed)]
