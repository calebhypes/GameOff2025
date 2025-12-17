extends CharacterBody2D

@export var speed: float = 300.00
@export var wave_scene: PackedScene
@export var max_health: float = 100.0
@export var debug_force_strength: int = 0
@export var cooldown_tier1: float = 0.65
@export var cooldown_tier2: float = 1.2
@export var cooldown_tier3: float = 2.0

@onready var shoot_point = $AimPivot/ShootPoint
@onready var body_sprite = $BodySprite
@onready var aim_pivot = $AimPivot
@onready var shot_cooldown = $ShotCooldown
@onready var shoot_sound = $ShootSound
@onready var charging_sound = $ChargingSound
@onready var weapon_sprite = $AimPivot/WeaponSprite
@onready var charge_particles = $AimPivot/ChargeParticles

var hud: CanvasLayer = null
var input_vector: = Vector2.ZERO
var last_input_vector: = Vector2.ZERO
var health: float = 100.0
var can_shoot: bool = true
var charge_time: float = 0.0
var is_charging: bool = false
var charging_past_intro: bool = false

func _ready() -> void:
	add_to_group("player")
	await get_tree().process_frame
	
	if charge_particles:
		charge_particles.emitting = false
	
	if charging_sound:
		charging_sound.finished.connect(_on_charging_sound_finished)
	
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
		update_charge_visuals()
	
	if charging_sound and charging_sound.playing:
		var playback_pos = charging_sound.get_playback_position()
		
		if not charging_past_intro and playback_pos >= 1.0:
			charging_past_intro = true
	
	if not can_shoot and hud and hud.has_method("update_cooldown"):
		var time_remaining = shot_cooldown.time_left
		var total_time = shot_cooldown.wait_time
		hud.update_cooldown(time_remaining, total_time)

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
				
				if charge_particles:
					charge_particles.emitting = true
				start_charging_audio()
			else:
				show_cooldown_feedback()
		if not event.pressed:
			if is_charging:
				var strength = calculate_strength(charge_time)
				shoot(strength)
				is_charging = false
				charge_time = 0.0
				
				if charge_particles:
					charge_particles.emitting = false
				stop_charging_audio()

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
	
	match strength:
		1:
			shot_cooldown.wait_time = cooldown_tier1
		2:
			shot_cooldown.wait_time = cooldown_tier2
		3:
			shot_cooldown.wait_time = cooldown_tier3
	
	#charge_time = 0.0 
	shot_cooldown.start()
	
	if weapon_sprite:
		weapon_sprite.modulate = Color(0.8, 0.2, 0.2)
		weapon_sprite.scale = Vector2(1.0, 1.0)
	
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

func update_charge_visuals() -> void:
	if not weapon_sprite:
		return
	
	var current_strength = calculate_strength(charge_time)
	
	var target_scale: Vector2
	var target_modulate: Color
	
	match current_strength:
		1:
			target_modulate = Color(1.0, 1.0, 1.0)
			target_scale = Vector2(1.0, 1.0)
			
			if charge_particles:
				charge_particles.amount = 10
				charge_particles.initial_velocity_min = 20
				charge_particles.initial_velocity_max = 30
				charge_particles.scale_amount_min = 1
				charge_particles.scale_amount_max = 1
		2:
			target_modulate = Color(1.5, 1.5, 2.0)
			target_scale = Vector2(1.1, 1.1)
			
			if charge_particles:
				charge_particles.amount = 20
				charge_particles.initial_velocity_min = 30
				charge_particles.initial_velocity_max = 50
		3:
			target_modulate = Color(2.0, 2.0, 2.5)
			target_scale = Vector2(1.2, 1.2)
			
			if charge_particles:
				charge_particles.amount = 40
				charge_particles.initial_velocity_min = 50
				charge_particles.initial_velocity_max = 80
				charge_particles.scale_amount_min = 1.5
				charge_particles.scale_amount_max = 2.0
	
	var lerp_speed = 10.0 * get_process_delta_time()
	weapon_sprite.scale = weapon_sprite.scale.lerp(target_scale, lerp_speed)
	weapon_sprite.modulate = weapon_sprite.modulate.lerp(target_modulate, lerp_speed)

func start_charging_audio() -> void:
	if charging_sound:
		charging_sound.play()
		charging_past_intro = false

func stop_charging_audio() -> void:
	if charging_sound:
		charging_sound.stop()
		charging_past_intro = false

func _on_charging_sound_finished() -> void:
	if is_charging:
		charging_sound.play(1.0)
		charging_past_intro = true
