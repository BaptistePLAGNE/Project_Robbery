# EnemyData.gd
class_name EnemyData
extends Resource

@export var id: String = ""
@export var name: String = ""
@export var max_hp: int = 100
@export var texture: Texture2D
@export var possible_actions: Array[EnemyActionData] = [] # ex: ["attack_10", "defend_5"]

func get_next_action(turn_number: int, last_action: EnemyActionData) -> EnemyActionData:
	if possible_actions.is_empty():
		return null
	
	var index = turn_number%possible_actions.size()
	return possible_actions[index]
