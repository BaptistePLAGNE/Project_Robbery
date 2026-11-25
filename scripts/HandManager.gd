extends Control

@onready var hand: HBoxContainer = $"."
@onready var card_scene: PackedScene = preload("res://scenes/CardUI.tscn")

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
	
	var exemple_new_card: Card = card_scene.instantiate()
	
	var over_lenght: int = nb_cards * exemple_new_card.size.x - (get_viewport_rect().size.x / 1.5)
	if over_lenght > 0:
		hand.add_theme_constant_override("separation",-over_lenght/nb_cards)
	else:
		hand.add_theme_constant_override("separation",4)


func _on_sort_children() -> void:
	EventBus.hand_update.emit()
