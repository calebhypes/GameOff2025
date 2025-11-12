extends Area2D

@export var speed: float = 500.0
@export var wave_strength: int = 1
@export var lifetime: float = 3.0

var direction: Vector2 = Vector2.RIGHT

@onready var sprite = $ColorRect

func _ready() -> void:
	# Flip sprite based on direction (left/right)
	if direction.x < 0:
		sprite.flip_h = true
	
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	
	# Optional: Slight vertical bob for "sound wave" feel
	sprite.position.y = sin(position.x * 0.1) * 2  # Wavy motion
