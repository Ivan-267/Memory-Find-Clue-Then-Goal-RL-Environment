extends CharacterBody3D
class_name Robot

# Code based on and built upon Godot's CharacterBody3D template

@export var chest: Chest
@export var door_manager: DoorManager
@export var correct_door_clue: CorrectDoorClue

const SPEED = 5.0
const TURN_SPEED = 9.0
const FRICTION = 60.0
const JUMP_VELOCITY = 4.5
const GRAVITY = 20.0

# Used to set rewards and restart the AIController
@onready var ai_controller = $AIController3D
# Used to switch between walking/idle animations
@onready var animation_player := $robot/AnimationPlayer
# We rotate the "visual" robot to make it appear as if the robot
# turns toward its movement direction
@onready var visual_robot := $robot
# We use this when reseting the robot to its initial transform
@onready var initial_transform := transform

# Requested movement (and jump, if enabled) is set by AIController
# based on the action produced by the model
var requested_movement: float
var requested_turn: float

var requested_jump: bool


func _ready():
	reset()


var game_speed = 100


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("debug_reset_speed"):
		game_speed = 1 if game_speed == 100 else 100
		Engine.physics_ticks_per_second = game_speed * 60  # Replace with function body.
		Engine.time_scale = game_speed * 1.0

	# Add the gravity.
	if not is_on_floor():
		velocity += Vector3.DOWN * GRAVITY * delta

	if Input.is_action_just_pressed("print_raycast"):
		print(ai_controller.sensors[0].get_observation())

	var input_dir: Vector2
	# If we set sync node to human, we get the controls directly from keyboard/gamepad
	if ai_controller.heuristic == "human":
		# Movement
		requested_movement = Input.get_axis("move_back", "move_forward")
		requested_turn = Input.get_axis("turn_right", "turn_left")
		# Jump
		if Input.is_action_just_pressed("ui_accept"):
			try_to_jump()
	# Otherwise, get controls from the model
	else:
		# Movement
		#input_dir = requested_movement
		if requested_jump:
			try_to_jump()

	rotate_y(requested_turn * TURN_SPEED * delta)

	if requested_movement:
		velocity = transform.basis.z * requested_movement * SPEED
		animation_player.play("walking")
	else:
		animation_player.play("idle")

	# Applies the movement requested and handles collision
	move_and_slide()

	# If the player fell down, this resets the game with a negative reward
	if global_position.y < -2.0:
		game_over(-1)

	# Simple friction/stopping
	velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
	velocity.z = move_toward(velocity.z, 0, FRICTION * delta)


## Ends the episode and resets the game
func game_over(reward: float = 0, success := false):
	ai_controller.reward += reward
	ai_controller.done = true
	if success:
		door_manager.seed += 1
	reset()


func reset():
	in_clue = false
	clue_reward_given = false
	ai_controller.reset()
	door_manager.reset()
	chest.reset()
	correct_door_clue.reset()
	correct_door_clue.set_category_from_door(chest.correct_door)
	ai_controller.approach_goal_reward.target_node = correct_door_clue
	transform = initial_transform


## Restarts the game with a positive reward if the chest is reached
func _on_chest_body_entered(_body: Node3D) -> void:
	game_over(5)


## Will jump if possible (if robot is on ground)
func try_to_jump():
	if is_on_floor():
		velocity.y = JUMP_VELOCITY


var clue_reward_given := false
var in_clue := false


func _on_correct_door_clue_body_entered(_body: Node3D) -> void:
	if not clue_reward_given:
		ai_controller.approach_goal_reward.target_node = chest
		ai_controller.approach_goal_reward.reset()
		clue_reward_given = true
	in_clue = true


func _on_door_manager_door_just_opened(door: Door) -> void:
	if not (door == chest.correct_door):
		game_over(-1, false)
