# EnemyData.gd
class_name CardData
extends Resource

@export var id: String = ""
@export var name: String = ""
@export var Description: String = ""
@export var cost_value: int = 10
@export var base_value: int = 1
@export var texture: Texture2D
@export var base_actions: Array[CardActionData] = []
