extends Area2D

@export var speed: float = 500.0
@export var wave_strength: int = 1	# 1 = weakest, 2 = medium, 3 = strongest
@export var lifetime: float = 3.0
@export var damage: float = 10.0 	# Base damage

var direction: Vector2 = Vector2.RIGHT
var shooter: Node2D = null # Track who fired this projectile
var team: String = "" # "player" or "enemy"

@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D

func _ready() -> void:
	# Rotate sprite to face the direction it was fired
	rotation = direction.angle() + PI
	
	update_size_by_strength()
	
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	# despawn
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	
	# Optional: Slight vertical bob for "sound wave" feel
	sprite.position.y = sin(position.x * 0.1) * 2  # Wavy motion
	
	# Despawn if too far
	if position.length() > 2000:
		queue_free()

# TODO: Replace this with different sprite based on weapon type and strength
func update_size_by_strength() -> void:
	# Scale projectile size based on strength
	var size_multiplier = 1.0 + (wave_strength - 1) * 0.5  # 1.0, 1.5, 2.0 for strength 1,2,3
	print('Size X: ', size_multiplier)
	
	if sprite:
		sprite.scale = Vector2(size_multiplier, size_multiplier)
	
	if collision_shape and collision_shape.shape:
		# Scale collision shape (works for CircleShape2D, CapsuleShape2D)
		collision_shape.scale = Vector2(size_multiplier, size_multiplier)
	
	# Optional: Adjust color brightness by strength
	if sprite:
		var brightness = 0.7 + (wave_strength * 0.15)  # Stronger = brighter
		sprite.modulate = Color(brightness, brightness, 1.0)  # More color for stronger

func _on_area_entered(other_area: Area2D) -> void:
	if other_area.is_in_group("sound_waves"):
		handle_wave_collision(other_area)

func _on_body_entered(body: Node2D) -> void:
	if body == shooter:
		return
	
	# hit a wall or enemy
	if body.is_in_group("walls"):
		queue_free()
	elif body.is_in_group("enemies") and team == "player":
		# Deal damage based on strength
		if body.has_method("take_damage"):
			body.take_damage(damage * wave_strength)
		queue_free()
	elif body.is_in_group("player") and team == "enemy":
		if body.has_method("take_damage"):
			body.take_damage(damage * wave_strength)
		queue_free()

func handle_wave_collision(other_wave: Area2D) -> void:
	var other_strength = other_wave.wave_strength
	if other_wave.team == team:
		return
	elif wave_strength == other_strength:
		spawn_cancel_effect()
		other_wave.queue_free()
		queue_free()
	elif wave_strength > other_strength:
		wave_strength -= other_strength
		update_size_by_strength()
		other_wave.spawn_cancel_effect()
		other_wave.queue_free()
	else:
		spawn_cancel_effect()
		queue_free()

func spawn_cancel_effect() -> void:
	# TODO: Add visual animation for destruction
	print("Wave cancelled at: ", global_position)
