extends CharacterBody2D

@export var speed: float = 300.00
@export var wave_scene: PackedScene
@export var max_health: float = 100.0
@export var debug_force_strength: int = 0

@onready var shoot_point = $AimPivot/ShootPoint
@onready var body_sprite = $BodySprite
@onready var aim_pivot = $AimPivot
@onready var shot_cooldown = $ShotCooldown
@onready var shoot_sound = $ShootSound
@onready var weapon_sprite = $AimPivot/WeaponSprite

var hud: CanvasLayer = null
var input_vector: = Vector2.ZERO
var last_input_vector: = Vector2.ZERO
var health: float = 100.0
var can_shoot: bool = true
var charge_time: float = 0.0
var is_charging: bool = false

func _ready() -> void:
	add_to_group("player")
	await get_tree().process_frame
	
	shot_cooldown.timeout.connect(_on_shot_cooldown)
	
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

func _process(delta: float) -> void:
	if is_charging:
		charge_time += delta

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
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if can_shoot:
				is_charging = true
				charge_time = 0.0
			else:
				show_cooldown_feedback()
		if not event.pressed:
			if is_charging:
				var strength = calculate_strength(charge_time)
				shoot(strength)
				is_charging = false
				charge_time = 0.0

func show_cooldown_feedback() -> void:
	if weapon_sprite:
		weapon_sprite.modulate = Color.RED
		await get_tree().create_timer(0.1).timeout
		weapon_sprite.modulate = Color(0.8, 0.2, 0.2)
	print("Weapon cooling down!")

func shoot(strength: int = 1) -> void:
	if not wave_scene:
		return
	
	can_shoot = false
	charge_time = 0.0
	shot_cooldown.start()
	
	if weapon_sprite:
		weapon_sprite.modulate = Color(0.8,0.2, 0.2)
	
	if shoot_sound:
		shoot_sound.pitch_scale = randf_range(0.95, 1.05)
		shoot_sound.play()
	
	var wave = wave_scene.instantiate()
	var shoot_direction = (get_global_mouse_position() - global_position).normalized()
	wave.direction = shoot_direction
	wave.wave_strength = strength
	print('Wave Strength: ', wave.wave_strength)
	
	wave.shooter = self
	wave.team = "player"
	
	wave.add_to_group("sound_waves")
	
	get_parent().add_child(wave)
	wave.global_position = shoot_point.global_position

func _on_shot_cooldown() -> void:
	can_shoot = true
	
	if weapon_sprite:
		weapon_sprite.modulate = Color.WHITE

func calculate_strength(time: float) -> int:
	if debug_force_strength > 0:
		return debug_force_strength
	
	if time >= 2.0:
		return 3
	elif time >= 1.0:
		return 2
	else:
		return 1
