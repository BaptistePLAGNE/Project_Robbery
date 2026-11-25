class_name Enemy extends Node2D

@onready var enemy_image: Sprite2D = $EnemyImage
@onready var hp_label: Label = $HP/HPLabel

var current_hp: int
var current_shield : int
var data: EnemyData

var current_action : EnemyActionData = null
var turn_count = 0

@onready var intent_icon: Sprite2D
@onready var intent_label: Label

func init_enemy(enemy_data: EnemyData) -> void:
	data = enemy_data
	current_hp = data.max_hp
	current_shield = 0
	#enemy_image.texture = data.texture
	hp_label.set_text("Health = "+str(current_hp))
	plan_next_turn()

func plan_next_turn() -> void:
	turn_count += 1
	current_action = data.get_next_action(turn_count, current_action)
	
	#_update_intent_ui()
	pass

func _update_intent_ui() -> void:
	if not current_action:
		intent_icon.visible = false
		return
	
	intent_icon.visible = true
	intent_icon.texture = current_action.icon
	
	if current_action.action_type == EnemyActionData.ActionType.ATTACK:
		intent_label.set_text(str(current_action.base_value))
	elif current_action.action_type == EnemyActionData.ActionType.DEFEND:
		intent_label.set_text(str(current_action.base_value))
	else:
		intent_label.set_text("")

func execute_turn(player_node: Node2D):
	if current_action:
		current_action.execute(self, player_node)
	
	plan_next_turn()

func take_damage(base_value: int) -> void:
	current_shield = current_shield - base_value
	if current_shield < 0:
		current_hp = current_hp + current_shield
		current_shield = 0
	
	if current_hp <= 0:
		queue_free()
	hp_label.set_text("Health = "+str(current_hp))
	
func defend(base_value: int) -> void:
	current_shield = current_shield + base_value
	
func apply_buff(base_value: int) -> void:
	data.attack += base_value
		
func apply_debuff(base_value: int) -> void:
	data.attack -= base_value


func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				EventBus.enemy_pressed.emit(self)
