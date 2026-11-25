extends Control
@onready var node_2d: Control = $"."
@onready var card_scene: PackedScene = preload("res://scenes/CardUI.tscn")
@onready var HandManager: Control = $HandManager
@onready var enemy_scene: PackedScene = preload("res://scenes/Enemy.tscn")
@onready var end_turn_button: Button = $EndTurnButton


func _on_end_turn_button_pressed() -> void:
	EventBus.end_turn_pressed.emit()
	EventBus.card_selected.emit(null)
