extends CanvasLayer

@onready var health_label = $MarginContainer/VBoxContainer/HealthLabel
@onready var health_bar = $MarginContainer/VBoxContainer/HealthBar

func _ready() -> void:
	add_to_group("hud")

func update_health(current: float, maximum: float) -> void:
	health_label.text = "Health: " + str(int(current)) + "/" + str(int(maximum))
	health_bar.max_value = maximum
	health_bar.value = current
