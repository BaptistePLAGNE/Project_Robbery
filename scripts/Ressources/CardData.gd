# CardData.gd
class_name CardData
extends Resource

@export var id: String = ""
@export var name: String = ""
@export var Description: String = ""
# Coût = nombre de personnages à mobiliser pour jouer la carte.
@export var cost_value: int = 1
@export var texture: Texture2D
@export var base_actions: Array[CardActionData] = []

# Valeur affichée sur la carte : celle de sa première action (0 si aucune).
# Calculée à partir des actions pour ne jamais diverger de l'effet réel.
func get_display_value() -> int:
	if base_actions.is_empty():
		return 0
	return base_actions[0].base_value
