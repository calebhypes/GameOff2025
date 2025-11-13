extends CharacterBody2D

@export var speed: float = 50.0
@export var health: float = 30.0
@export var max_health: float = 30.0
@export var shoot_interval: float = 2.0
@export var wave_scene: PackedScene  # Assign same sound_wave.tscn

var player: Node2D = null

@onready var shoot_timer = $ShootTimer
@onready var health_bar = $HealthBarPosition/enemy_health_bar

func _ready() -> void:
	health = max_health
	# Find the player
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	
	if health_bar and health_bar.has_method("update_health"):
		health_bar.update_health(health, max_health)
	
	if not player:
		push_error("Player not found! Add player to 'player' group")
	
	# Setup shoot timer
	shoot_timer.wait_time = shoot_interval
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	
	# Add to enemy group for projectile collision
	add_to_group("enemies")

func _physics_process(delta: float) -> void:
	if not player:
		return
	
	# Move toward player
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()

func _on_shoot_timer_timeout() -> void:
	shoot()

func shoot() -> void:
	if not wave_scene or not player:
		return
	
	# Create wave
	var wave = wave_scene.instantiate()
	
	# Aim at player
	var shoot_direction = (player.global_position - global_position).normalized()
	
	# Set properties BEFORE adding to tree
	wave.direction = shoot_direction
	wave.wave_strength = 1  # Enemy shoots weak waves
	wave.shooter = self
	wave.team = "enemy"
	
	# Add to scene
	get_parent().add_child(wave)
	wave.global_position = global_position
	
	# Add to group
	wave.add_to_group("sound_waves")
	wave.add_to_group("enemy_projectiles")  # Track whose wave it is

func take_damage(amount: float) -> void:
	health -= amount
	print("Enemy took ", amount, " damage. Health: ", health)
	
	if health_bar and health_bar.has_method("update_health"):
		health_bar.update_health(health, max_health)
	
	# Flash red (simple feedback)
	modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE
	
	if health <= 0:
		die()

func die() -> void:
	print("Enemy died!")
	queue_free()
