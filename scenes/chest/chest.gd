extends Area3D
class_name Chest

@export var door_manager: DoorManager

var correct_door_category := 0
var correct_door: Door


func reset():
	correct_door = null
	correct_door_category = 0
	place_chest_behind_door()


func place_chest_behind_door():
	var door = door_manager.active_doors.pick_random()
	global_position = door.global_position + Vector3.FORWARD * 1
	correct_door_category = door.category
	correct_door = door
