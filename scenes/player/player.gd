extends CharacterBody2D

@export var speed: float = 300.00
@export var wave_scene: PackedScene

@onready var shoot_point = $AimPivot/ShootPoint
@onready var body_sprite = $BodySprite
@onready var aim_pivot = $AimPivot

var input_vector: = Vector2.ZERO
var last_input_vector: = Vector2.ZERO

func _ready() -> void:
	print("AimPivot: ", aim_pivot)
	print("ShootPoint: ", shoot_point)
	print("BodySprite: ", body_sprite)

func _physics_process(delta: float) -> void:
	input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_vector * speed
	move_and_slide()
	
	var mouse_direction = get_global_mouse_position() - global_position
	aim_pivot.rotation = mouse_direction.angle()
	#print("Aim rotation: ", aim_pivot.rotation_degrees)
	
	#if mouse_direction.x < 0:
		#body_sprite.flip_h = true # face left
	#else:
		#body_sprite.flip_h = false # face right
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			shoot()

func shoot() -> void:
	if not wave_scene:
		return
	
	var wave = wave_scene.instantiate()
	get_parent().add_child(wave)
	wave.global_position = shoot_point.global_position
	
	var shoot_direction = (get_global_mouse_position() - global_position).normalized()
	wave.direction = shoot_direction
