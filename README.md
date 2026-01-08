# Memory-Find-Clue-Then-Goal-RL-Environment
A reinforcement learning environment made using Godot and Godot RL Agents. The agent needs to find the clue showing the correct door, then reach the goal behind the door.
The env is based on https://github.com/Ivan-267/GDRLSimpleEnvTutorial.

https://github.com/user-attachments/assets/612bc7ea-6dd2-42fb-b5d4-a30088683051

## Training:
Check the Godot RL Agents readme first to familiarize yourself with the framework https://github.com/edbeeching/godot_rl_agents?tab=readme-ov-file#godot-rl-agents.

I was able to train this env locally using a modified CleanRL PPO LSTM Atari script, the modifications make it use RNN/GRU, work with vector obs, and adjust the hyperparams and other details to work with Godot RL Agents envs. 
PR for adding the script to Godot RL Agents: https://github.com/edbeeching/godot_rl_agents/pull/250

> [!NOTE]
> Check the readme for the training script from the PR for more info on how to train using the script.

> [!NOTE]
> There's no ONNX inference file or checkpoint included with this env. ONNX inference for RNN based models is not currently integrated into Godot RL Agents at the time of this writing.

Reward from the training run:
> [!NOTE]
> The results below are from a single run only. The results might vary with more runs.

<img width="1746" height="457" alt="image" src="https://github.com/user-attachments/assets/43626d90-b8ec-4fb3-96b0-32086e12143c" />

Hyperparams/args recorded:
```text
param 	value
n_parallel 	4
viz 	False
speedup 	100
use_vanilla_rnn 	False

seed 	1
torch_deterministic 	True
cuda 	False
save_model_frequency_global_steps 	200000
load_model_path 	None
inference 	False
track 	False
wandb_project_name 	cleanRL
wandb_entity 	None
capture_video 	False
env_id 	GodotRLEnv
total_timesteps 	15000000
learning_rate 	0.0003
num_envs 	64
num_steps 	1024
anneal_lr 	True
gamma 	0.99
gae_lambda 	0.95
num_minibatches 	1
update_epochs 	60
norm_adv 	True
clip_coef 	0.15
clip_vloss 	False
ent_coef 	0.005
vf_coef 	0.5
max_grad_norm 	0.5
target_kl 	0.0065
batch_size 	65536
minibatch_size 	65536
num_iterations 	228
```

Notes:
- Many of these were set automatically as defaults in the Python script, not set as command line args (except for `env_path`, `n_parallel`, `speedup`, `save_model_frequency_global_steps`, and `no-cuda` which were set as command line args when calling the script),
the default hyperparams might be different in the Godot RL Training script from the above, adjust as/if needed.
- env_path removed from the log, you should export the environment to Godot, then point it to the executable of the exported env using command line args
- exp_name also removed from the log

## Observations:
```gdscript
func get_current_frame_obs() -> Array:
	var obs: Array
	for sensor in sensors:
		obs.append_array(sensor.get_observation())
	obs.append(n_steps / float(reset_after))
	obs.append(player.requested_movement)
	obs.append(player.requested_turn)
	return obs
```

There is only one sensor, assigned in `res://scenes/game_scene/game_scene.tscn` to the `AIController3D` node, which is a `MultiLayerRaycastSensor3D`, a modified version of `RaycastSensor3D` from the [Godot RL Agents Plugin](https://github.com/edbeeching/godot_rl_agents_plugin).
The modified sensor checks for collisions in multiple physics layers, and orders the distance data based on the physics layer (so the neural network can easily differentiate between the different object categories hit, e.g. walls/obstacles, the category of the active doors, and the category that the clue is showing).

The other observations involve the requested movement/turn assigned to the robot, and the normalized episode time (the episode ends after `reset_after` steps unless the robot reaches the goal first).

## Actions:
```gdscript
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
```

There is a single discrete action space that allows turning and standing still or moving forward. 

## Rewards:
- An `ApproachNodeReward3D` reward is used, which first rewards approaching the clue based on the best distance reached, and once the clue is reached, the target node is changed to the treasure chest.
- There is a small penalty (reward -1) for opening the wrong door (any of the 3 doors at the top of the map can automatically open on approach). This ends the episode.
- There is a reward of +5 for reaching the treasure chest. This ends the episode.
- There is a -1 reward if the robot falls, this is left over from the original environment, this condition shouldn't trigger in the env unless a bug occurs. This ends the episode.
