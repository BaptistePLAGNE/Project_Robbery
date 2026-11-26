extends Control
@onready var node_2d: Control = $"."
@onready var card_scene: PackedScene = preload("res://scenes/CardUI.tscn")
@onready var HandManager: Control = $HandManager
@onready var enemy_scene: PackedScene = preload("res://scenes/Enemy.tscn")
@onready var end_turn_button: Button = $EndTurnButton
@onready var energy_label: Label = $EnergyLabel

# Énergie = nombre de personnages encore disponibles ce tour.
func update_energy(available: int, total: int) -> void:
	energy_label.set_text("Énergie : %d / %d" % [available, total])


func _on_end_turn_button_pressed() -> void:
	EventBus.end_turn_pressed.emit()
	EventBus.card_selected.emit(null)
