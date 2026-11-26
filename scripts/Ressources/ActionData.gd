# ActionData.gd
# Classe de base commune aux actions des cartes (CardActionData) et des
# ennemis (EnemyActionData). Toute la logique d'exécution est ici.
class_name ActionData
extends Resource

enum ActionType {ATTACK, DEFEND, BUFF, DEBUFF, UNKNOW}

@export var id: String = ""
@export var action_type: ActionType = ActionType.ATTACK
@export var icon: Texture2D
@export var base_value: int

func execute(caster: Node2D, target: Node2D) -> void:
	match action_type:
		ActionType.ATTACK:
			# Dégâts = valeur de l'action + modificateur d'attaque du lanceur, jamais négatifs.
			target.take_damage(max(0, base_value + caster.attack_modifier))
		ActionType.DEFEND:
			caster.defend(base_value)
		ActionType.BUFF:
			caster.apply_buff(base_value)
		ActionType.DEBUFF:
			target.apply_debuff(base_value)
