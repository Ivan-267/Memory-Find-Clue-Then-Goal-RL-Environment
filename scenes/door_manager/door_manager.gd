extends Node3D
class_name DoorManager

signal door_just_opened(door: Door)

## Controls all doors that are not set to be "always open"
var active_doors: Array[Door]
var doors_open := 0


func _ready() -> void:
	for door in get_children():
		door = door as Door
		if not door.always_open:
			active_doors.append(door)
			door.robot_entered.connect(robot_near_door)


func reset():
	doors_open = 0
	close_all_doors()
	randomize_categories()


func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("debug_open_all_doors"):
		open_all_doors()
	if Input.is_action_just_pressed("debug_close_all_doors"):
		close_all_doors()


func randomize_categories():
	var all_categories = range(active_doors.size())
	all_categories.shuffle()

	for door in active_doors:
		door.set_category(all_categories.pop_back())


func open_all_doors():
	for door in active_doors:
		door.open()


func close_all_doors():
	for door in active_doors:
		door.close()


func robot_near_door(door: Door):
	# Only one active door can be opened
	if doors_open > 0:
		return
	door.open()
	doors_open += 1
	door_just_opened.emit(door)
