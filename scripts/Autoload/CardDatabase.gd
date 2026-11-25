# EnemyDatabase.gd
extends Node

# Dictionnaire regroupant chaque EnemyData par son ID
@export var cards: Dictionary = {
	"pistol" : preload("res://Ressources/Cards/Pistol.tres")
}

# Groupes d'ennemis prédéfinis pour les rencontres (Encounters)
var cards_hand: Dictionary = {
	"act1_easy_1": ["pistol"],
	"act1_easy_2": ["pistol"],
	"act1_medium_1": ["pistol", "pistol"],
	"act1_medium_2": ["pistol", "pistol"],
	"act1_boss": ["pistol"]
}

# Fonction pour récupérer une carte
func get_encounter(group_id: String) -> Array[CardData]:
	var result: Array[CardData] = []
	if cards_hand.has(group_id):
		for card_id in cards_hand[group_id]:
			if cards.has(card_id):
				result.append(cards[card_id])
	return result
