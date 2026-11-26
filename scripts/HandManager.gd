extends Control

@onready var hand: HBoxContainer = $"."
@onready var card_scene: PackedScene = preload("res://scenes/CardUI.tscn")

# Largeur d'une carte, mesurée une seule fois (voir _get_card_width()).
var _card_width: float = -1.0

# Pioche et défausse du combat en cours (données uniquement, pas de nœuds).
var draw_pile: Array[CardData] = []
var discard_pile: Array[CardData] = []

func _ready() -> void:
	EventBus.card_played.connect(_on_card_played)

# Prépare la pioche à partir d'un deck de départ, mélangée.
func setup_deck(deck_id: String) -> void:
	draw_pile = CardDatabase.get_deck(deck_id)
	draw_pile.shuffle()
	discard_pile.clear()

# Pioche une carte et l'ajoute à la main. Si la pioche est vide, la défausse
# est mélangée pour former une nouvelle pioche. Renvoie false si les deux
# sont vides (aucune carte piochée).
func draw_card() -> bool:
	if draw_pile.is_empty():
		if discard_pile.is_empty():
			return false
		draw_pile.append_array(discard_pile)
		discard_pile.clear()
		draw_pile.shuffle()

	var new_card: Card = card_scene.instantiate()
	hand.add_child(new_card)
	new_card.init_card(draw_pile.pop_back())
	new_card.visible = true
	_set_Separation()
	return true

# Une carte jouée part dans la défausse.
func _on_card_played(card_data: CardData) -> void:
	discard_pile.append(card_data)


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
