# CardDatabase.gd
extends Node

# Dictionnaire regroupant chaque CardData par son ID
@export var cards: Dictionary = {
	"pistol" : preload("res://Ressources/Cards/Pistol.tres")
}

# Decks de départ : liste d'IDs de cartes (une entrée = un exemplaire).
# Seul le Pistolet existe pour l'instant.
var starter_decks: Dictionary = {
	"starter": ["pistol", "pistol", "pistol", "pistol", "pistol",
		"pistol", "pistol", "pistol", "pistol", "pistol"]
}

# Renvoie une carte par son ID (null si inconnue).
func get_card(card_id: String) -> CardData:
	if not cards.has(card_id):
		push_error("CardDatabase : carte inconnue '%s'" % card_id)
		return null
	return cards[card_id]

# Renvoie le contenu d'un deck de départ (une entrée par exemplaire).
func get_deck(deck_id: String) -> Array[CardData]:
	var result: Array[CardData] = []
	if not starter_decks.has(deck_id):
		push_error("CardDatabase : deck inconnu '%s'" % deck_id)
		return result
	for card_id in starter_decks[deck_id]:
		var card: CardData = get_card(card_id)
		if card != null:
			result.append(card)
	return result
