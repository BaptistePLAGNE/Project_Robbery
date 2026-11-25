# EventBus.gd
extends Node

signal card_pressed(card: Card)
signal card_selected(card : Card)

signal hand_update()

signal character_pressed(character: Character)

signal enemy_pressed(enemy: Enemy)

signal end_turn_pressed()
