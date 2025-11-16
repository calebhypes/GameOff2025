extends CharacterBody2D

@export var speed: float = 300.00
@export var wave_scene: PackedScene
@export var current_weapon_strength: int = 1 # Change in Inspector to test
@export var max_health: float = 100.0

@onready var shoot_point = $AimPivot/ShootPoint
@onready var body_sprite = $BodySprite
@onready var aim_pivot = $AimPivot
@onready var tier1_cooldown = $Tier1Cooldown

var hud: CanvasLayer = null
var input_vector: = Vector2.ZERO
var last_input_vector: = Vector2.ZERO
var health: float = 100.0
var can_shoot: bool = true;

func _ready() -> void:
	add_to_group("player")
	await get_tree().process_frame
	
	tier1_cooldown.timeout.connect(_on_tier1_cooldown)
	
	hud = get_tree().get_first_node_in_group("hud")
	health = max_health
	
	if hud and hud.has_method("update_health"):
		hud.update_health(health, max_health)
	
	print("AimPivot: ", aim_pivot)
	print("ShootPoint: ", shoot_point)
	print("BodySprite: ", body_sprite)

func take_damage(amount: float) -> void:
	health -= amount
	# TODO: Health counter
	print("Player took ", amount, " gamage. Health: ", health)
	
	if hud and hud.has_method("update_health"):
		hud.update_health(health, max_health)
	
	# Flash red
	modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE
	
	if health <= 0:
		die()

func die() -> void:
	print("Player died!")
	# TODO: Game over screen
	get_tree().reload_current_scene()

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
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and can_shoot:
			shoot()

func shoot() -> void:
	if not wave_scene:
		return
	
	can_shoot = false
	tier1_cooldown.start()
	
	var wave = wave_scene.instantiate()
	var shoot_direction = (get_global_mouse_position() - global_position).normalized()
	wave.direction = shoot_direction
	wave.wave_strength = current_weapon_strength
	print('Wave Strength: ', wave.wave_strength)
	
	wave.shooter = self
	wave.team = "player"
	
	wave.add_to_group("sound_waves")
	
	get_parent().add_child(wave)
	wave.global_position = shoot_point.global_position

func _on_tier1_cooldown() -> void:
	can_shoot = true
