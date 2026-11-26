extends Control

@onready var hand: HBoxContainer = $"."
@onready var card_scene: PackedScene = preload("res://scenes/CardUI.tscn")

# Largeur d'une carte, mesurée une seule fois (voir _get_card_width()).
var _card_width: float = -1.0

func _add_card():
	var cards_array = CardDatabase.get_encounter("act1_easy_1")
	var new_card: Card = card_scene.instantiate()
	hand.add_child(new_card)
	new_card.init_card(cards_array[0])
	new_card.visible = true
	
	
	_set_Separation()
	
	

func _remove_card(card: Card):
	card.queue_free()
	_set_Separation()


func _set_Separation():
	var nb_cards: int = hand.get_child_count()
	
	var over_lenght: int = nb_cards * _get_card_width() - (get_viewport_rect().size.x / 1.5)
	if over_lenght > 0:
		hand.add_theme_constant_override("separation",-over_lenght/nb_cards)
	else:
		hand.add_theme_constant_override("separation",4)


# Mesure la largeur d'une carte sur une instance temporaire, libérée aussitôt,
# puis la garde en cache pour les appels suivants.
func _get_card_width() -> float:
	if _card_width < 0.0:
		var sample_card: Card = card_scene.instantiate()
		_card_width = sample_card.size.x
		sample_card.free()
	return _card_width


func _on_sort_children() -> void:
	EventBus.hand_update.emit()
