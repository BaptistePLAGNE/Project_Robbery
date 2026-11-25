class_name Character extends Node2D

@export var Character_HP = 1
@export var CharacterImage: Node2D

@onready var Id: int

@onready var character_image: Sprite2D = $CharacterImage
@onready var strenght_label: Label = $Strenght/Strenght_Label

@onready var button: Button = $Button

@onready var hp_label: Label = $HP/HPLabel

@onready var available: bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_values(Character_HP, 0)
	visible = false

func set_values(_HP: int, _Id: int):
	Character_HP = _HP
	Id = _Id
	hp_label.set_text(str(Character_HP))

func take_damage(base_value: int) -> void:
	Character_HP = Character_HP - base_value
	if Character_HP <= 0:
		queue_free()
	hp_label.set_text(str(Character_HP))
	
func defend(base_value: int) -> void:
	null
	
func apply_buff(base_value: int) -> void:
	null;
		
func apply_debuff(base_value: int) -> void:
	null;

func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if available:
					EventBus.character_pressed.emit(self)
