extends Node3D
class_name Door

signal robot_entered(door: Door)

## If always open, the door won't show any label as well
@export var always_open: bool = false

@onready var label: Label3D = $Label3D
@onready var entrance_collision_shape := $EntranceCollider/CollisionShape3D
@onready var anim := $door/AnimationPlayer

var category = 0
var _physics_bodies: Array


func _ready() -> void:
	_physics_bodies = find_children("*", "CollisionObject3D")
	if always_open:
		open()
		label.visible = false


func set_category(new_category: int):
	category = new_category
	label.text = str(category)
	for body in _physics_bodies:
		body = body as CollisionObject3D
		body.collision_layer = 0
		# Door layers start at 2 (to avoiding mixing with walls at layer1)
		body.set_collision_layer_value(category + 2, true)


func open():
	anim.play("open")
	entrance_collision_shape.set_deferred("disabled", true)


func close():
	if always_open:
		return
	anim.play("close")
	entrance_collision_shape.set_deferred("disabled", false)


func _on_player_sensor_body_entered(body: Node3D) -> void:
	if body is Robot:
		robot_entered.emit(self)
