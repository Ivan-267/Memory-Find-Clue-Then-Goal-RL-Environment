extends AIController3D

@export var sensors: Array[ISensor3D]

@onready var approach_goal_reward: ApproachNodeReward3D = $ApproachGoalReward
@onready var player: Robot = get_parent()

## We'll store all possible actions here
var possible_actions: Array[Array]


func _physics_process(_delta):
	n_steps += 1

	# A time-out for the player
	# note that the parent class we're inheriting from also implements this check
	# but we changed the method to end episode and set a different
	# reward for timeout and for when needs_reset is set to true (see more below)
	if n_steps > reset_after:
		player.game_over(0)

	# This will be set to true externally from Python sometimes to restart the env,
	# e.g. before the training begins, so we'll just reset the game
	# with a neutral final reward in that case
	if needs_reset:
		player.game_over(0)


# Here we provide observations to the model, the data it uses to
# observe the world and make actions (control the robot)
func get_obs() -> Dictionary:
	var obs: Array = get_current_frame_obs()
	return {"obs": obs}


func get_current_frame_obs() -> Array:
	var obs: Array
	for sensor in sensors:
		obs.append_array(sensor.get_observation())
	obs.append(n_steps / float(reset_after))
	obs.append(player.requested_movement)
	obs.append(player.requested_turn)
	return obs


# The method below will provide rewards to the model.
# Rewards are used only during training and the model needs them to learn
# which actions are best to take for a specific state (based on observations)
func get_reward() -> float:
	# Here we add the reward from our "approach goal reward" node,
	# which rewards when the robot reaches a "best/closest" distance to the goal,
	# but does not penalize moving away from the goal while exploring the environment
	reward += approach_goal_reward.get_reward()

	# Note: The reward variable is also set externally (e.g. from player script when
	# the goal is reached), and it is reset to 0 by the sync node
	# after being sent to the Python server (as the reward for that step is transferred)
	return reward


## Resets the AIController (e.g. when game is over)
func reset():
	super.reset()
	# We also reset the reward node when the episode is done.
	# This is needed when using `ApproachNodeReward` node,
	# as it resets the "closest position reached" data, so it can reward
	# the robot for moving toward the goal in the next episode as well.
	approach_goal_reward.reset()


func get_action_space() -> Dictionary:
	possible_actions = get_possible_actions()
	return {
		"move": {"size": possible_actions.size(), "action_type": "discrete"},
	}


## Returns all possible actions
## each action is a 2D array: [move_float, turn_float]
func get_possible_actions() -> Array[Array]:
	var actions: Array[Array]
	for move in range(-1, 2):
		for turn in range(-1, 2):
			#if move == 0:
				#continue # We skip standing still as an option
			if move == -1:
				continue # We skip moving backward as an option
			actions.append([move, turn])
	return actions


## Here we apply the actions received from the model
## to control the robot
func set_action(action) -> void:
	player.requested_movement = clampf(possible_actions[int(action.move)][0], -0.05, 1.0)
	player.requested_turn = possible_actions[int(action.move)][1]
