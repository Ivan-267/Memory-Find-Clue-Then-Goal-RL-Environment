extends Area3D
class_name CorrectDoorClue

@export var door_manager: DoorManager
@export var spawn_positions: Node3D
@onready var label := $Label3D


func reset():
	var all_spawn_points = spawn_positions.get_children()
	var rand_spawn_point = all_spawn_points.pick_random()
	global_transform = rand_spawn_point.global_transform


## Sets category for a specific door, layer is adjusted
func set_category(new_category: int):
	label.text = str(new_category)
	# Door layers start at 2 (to avoiding mixing with walls at layer1)
	# We also want to avoid mixing the category with doors
	# (to make each clue category unique from doors in the raycast data)
	var doors_layer_start := 2
	var door_count := door_manager.active_doors.size()
	var layer_offset := doors_layer_start + door_count
	collision_layer = 0
	set_collision_layer_value(layer_offset + new_category, true)


func set_category_from_door(door: Door):
	set_category(door.category)
