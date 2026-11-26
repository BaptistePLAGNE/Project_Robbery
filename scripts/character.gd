class_name Character extends Node2D

@export var Character_HP = 1
@export var CharacterImage: Node2D

@onready var Id: int

@onready var character_image: Sprite2D = $CharacterImage

@onready var hp_label: Label = $HP/HPLabel

@onready var available: bool = true

# Bonus/malus d'attaque propre à ce personnage, actif tout le combat.
var attack_modifier: int = 0
# Bouclier : absorbe les dégâts avant les PV (même règle que Enemy).
var current_shield: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_values(Character_HP, 0)
	visible = false

func set_values(_HP: int, _Id: int):
	Character_HP = _HP
	Id = _Id
	hp_label.set_text(str(Character_HP))

func take_damage(base_value: int) -> void:
	current_shield = current_shield - base_value
	if current_shield < 0:
		Character_HP = Character_HP + current_shield
		current_shield = 0
	if Character_HP <= 0:
		queue_free()
	hp_label.set_text(str(Character_HP))
	
func defend(base_value: int) -> void:
	current_shield = current_shield + base_value
	
func apply_buff(base_value: int) -> void:
	attack_modifier += base_value

func apply_debuff(base_value: int) -> void:
	attack_modifier -= base_value

func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if available:
					EventBus.character_pressed.emit(self)
