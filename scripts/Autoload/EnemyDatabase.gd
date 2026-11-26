# EnemyDatabase.gd
extends Node

# Dictionnaire regroupant chaque EnemyData par son ID
@export var enemies: Dictionary = {
	"goblin": preload("res://Ressources/Enemies/Gobelin.tres")
}

# Groupes d'ennemis prédéfinis pour les rencontres (Encounters).
# Seul le Gobelin existe pour l'instant : il sert de remplaçant partout.
var encounter_groups: Dictionary = {
	"act1_easy_1": ["goblin"],
	"act1_easy_2": ["goblin"],
	"act1_medium_1": ["goblin", "goblin"],
	"act1_medium_2": ["goblin", "goblin", "goblin"],
	"act1_boss": ["goblin"]
}

# Fonction pour récupérer un groupe d'EnemyData
func get_encounter(group_id: String) -> Array[EnemyData]:
	var result: Array[EnemyData] = []
	if not encounter_groups.has(group_id):
		push_error("EnemyDatabase : rencontre inconnue '%s'" % group_id)
		return result
	for enemy_id in encounter_groups[group_id]:
		if enemies.has(enemy_id):
			result.append(enemies[enemy_id])
		else:
			push_error("EnemyDatabase : ennemi inconnu '%s' dans la rencontre '%s'" % [enemy_id, group_id])
	return result
