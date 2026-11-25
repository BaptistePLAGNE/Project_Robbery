# EnemyDatabase.gd
extends Node

# Dictionnaire regroupant chaque EnemyData par son ID
@export var enemies: Dictionary = {
	"goblin": preload("res://Ressources/Enemies/Gobelin.tres")
}

# Groupes d'ennemis prédéfinis pour les rencontres (Encounters)
var encounter_groups: Dictionary = {
	"act1_easy_1": ["goblin"],
	"act1_easy_2": ["cultist"],
	"act1_medium_1": ["goblin", "goblin"],
	"act1_medium_2": ["cultist", "jaw_worm"],
	"act1_boss": ["boss_slime"]
}

# Fonction pour récupérer un groupe d'EnemyData
func get_encounter(group_id: String) -> Array[EnemyData]:
	var result: Array[EnemyData] = []
	if encounter_groups.has(group_id):
		for enemy_id in encounter_groups[group_id]:
			if enemies.has(enemy_id):
				result.append(enemies[enemy_id])
	return result
