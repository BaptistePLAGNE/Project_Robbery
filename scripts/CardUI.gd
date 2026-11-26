#class_name Card extends Node2D
class_name Card
extends Control

@onready var card_node: Card = $"."

@export var follow_speed: float = 25.0

@onready var card_image: TextureRect = $CardImage
@onready var value_label: Label = $ValueLabel
@onready var cost_label: Label = $CostLabel
@onready var card_label: Label = $CardLabel
@onready var card_description: Label = $CardDescription

@export var hover_scale: float = 1.03
@export var hover_up: float = -10
@export var scale_duration: float = 0.3

var data: CardData
var tween: Tween

var x_position_base: float
var y_position_base: float

var is_selected: bool = false

func _ready():
	EventBus.card_selected.connect(_on_card_selected)
	EventBus.hand_update.connect(_on_hand_update)

func _on_card_selected(card: Card):
	if card == self:
		is_selected = true
		z_index = 100
		_animate_scale(Vector2.ONE * hover_scale*hover_scale, hover_up*20, 350)		
	else:
		if is_selected:
			z_index = 0
			_animate_scale(Vector2.ONE, y_position_base, x_position_base)
			is_selected = false

func _on_hand_update():
	x_position_base = position.x
	y_position_base = position.y
	pivot_offset = position

func init_card(card_data: CardData) -> void:
	data = card_data
	cost_label.set_text(str(card_data.cost_value))
	value_label.set_text(str(card_data.get_display_value()))
	card_label.set_text(card_data.name)
	card_description.set_text(card_data.Description)
	# L'illustration de la scène sert de placeholder tant que la carte n'a pas de texture.
	if card_data.texture != null:
		card_image.texture = card_data.texture
	set_pivot_offset_ratio(Vector2(0.5, 0.5))
	##pivot_offset = size / 2

func _animate_scale(target_scale: Vector2, target_y: float, target_x: float) -> void:
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "scale", target_scale, scale_duration)
	tween.parallel().tween_property(self, "position:y", target_y, scale_duration)
	tween.parallel().tween_property(self, "position:x", target_x, scale_duration)

func _on_mouse_entered() -> void:
	if is_selected:
		return
	z_index = 10
	_animate_scale(Vector2.ONE * hover_scale, y_position_base + hover_up, x_position_base)

func _on_mouse_exited() -> void:
	if is_selected:
		return
	_animate_scale(Vector2.ONE, y_position_base, x_position_base)
	z_index = 0

func _on_gui_input(event: InputEvent) -> void:
	##print(event.as_text())
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				EventBus.card_pressed.emit(self)

func execute_card(caster: Node2D, target: Node2D):
	for action in data.base_actions:
		action.execute(caster, target)
	queue_free()
