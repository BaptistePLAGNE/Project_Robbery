# EnemyData.gd
class_name EnemyActionData
extends Resource

enum ActionType {ATTACK, DEFEND, BUFF, DEBUFF, UNKNOW}

@export var id: String = ""
@export var action_type: ActionType = ActionType.ATTACK
@export var icon: Texture2D
@export var base_value: int

func execute(caster: Node2D, target: Node2D) -> void:
	match action_type:
		ActionType.ATTACK:
			target.take_damage(base_value)
		ActionType.DEFEND:
			caster.defend(base_value)
		ActionType.BUFF:
			caster.apply_buff(base_value)
		ActionType.DEBUFF:
			target.apply_debuff(base_value)
