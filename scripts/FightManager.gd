extends Node2D

@onready var node_2d: Node2D = $"."

@onready var enemy_spawn_point: Node2D = $Enemy_SpawnPoints/Enemy_SpawnPoint
@onready var enemy_spawn_point_2: Node2D = $Enemy_SpawnPoints/Enemy_SpawnPoint2
@onready var enemy_spawn_point_3: Node2D = $Enemy_SpawnPoints/Enemy_SpawnPoint3
@onready var enemy_spawn_point_4: Node2D = $Enemy_SpawnPoints/Enemy_SpawnPoint4
@onready var enemy_spawn_point_5: Node2D = $Enemy_SpawnPoints/Enemy_SpawnPoint5

@onready var enemy_spawn_point_array: Array[Node2D] = [enemy_spawn_point,enemy_spawn_point_2,enemy_spawn_point_3,enemy_spawn_point_4,enemy_spawn_point_5]

@onready var charcter_spawn_point: Node2D = $Character_SpawnPoints/Charcter_SpawnPoint
@onready var charcter_spawn_point_2: Node2D = $Character_SpawnPoints/Charcter_SpawnPoint2
@onready var charcter_spawn_point_3: Node2D = $Character_SpawnPoints/Charcter_SpawnPoint3
@onready var character_spawn_point_array: Array[Node2D] = [charcter_spawn_point,charcter_spawn_point_2,charcter_spawn_point_3]

@onready var end_fight_label: Label = $End_Fight_Label
@onready var CombatUI: Control = $CombatUI
@onready var character_selected_pin: Sprite2D = $Character_Selected_Pin

@onready var enemy_scene: PackedScene = preload("res://scenes/Enemy.tscn")
@onready var character_scene: PackedScene = preload("res://scenes/Character.tscn")
@onready var enemy_container: Node2D = $Enemy_Container
@onready var character_container: Node2D = $Character_Container

var rng = RandomNumberGenerator.new()

@onready var heal: int


signal fight_end(int)

var character_selected: Character
var card_selected : Card
var enemy_selected : Enemy

func _on_card_selected(card: Card):
	if card != card_selected:
		card_selected = card
	else:
		card_selected = null
	EventBus.card_selected.emit(card_selected)
	
	
func _on_character_selected(character: Character):
	if character == null:
		character_selected_pin.visible = false
		character_selected = null
	elif character != character_selected:
		character_selected = character
		character_selected_pin.position = Vector2(character.position.x, character.position.y-100)
		character_selected_pin.visible = true
		
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventBus.card_pressed.connect(_on_card_selected)
	EventBus.character_pressed.connect(_on_character_selected)
	EventBus.enemy_pressed.connect(_on_enemy_pressed)
	EventBus.end_turn_pressed.connect(_on_end_round_pressed)
	
	character_selected_pin.visible = false
	
	setup_battle("act1_easy_1")

	for i in range(5):
		CombatUI.HandManager._add_card()
		
	for i in range(rng.randi_range(1,3)):
		var new_character: Character = character_scene.instantiate()
		character_container.add_child(new_character)
		
		var id: int
		id = character_container.get_child_count() - 1
		
		new_character.set_values(rng.randi_range(1,100), id)
		new_character.visible = true
		
		new_character.position = character_spawn_point_array[id].global_position
		
		heal = heal + new_character.Character_HP


func setup_battle(encounter_id) -> void:
	var enemy_datas: Array[EnemyData] = EnemyDatabase.get_encounter(encounter_id)
	
	for i in range(enemy_datas.size()):
		var new_enemy = enemy_scene.instantiate()
		enemy_container.add_child(new_enemy)
		new_enemy.init_enemy(enemy_datas[i])
		new_enemy.global_position = enemy_spawn_point_array[i].position
	
func enemy_turn() -> bool:
	for enemy in enemy_container.get_children():
		# On ne cible que les personnages encore en vie : si l'équipe est
		# entièrement morte, les ennemis restants ne jouent pas.
		var alive_characters: Array[Character] = _get_alive_characters()
		if alive_characters.is_empty():
			break
		var character: Character = alive_characters[randi_range(0, alive_characters.size() - 1)]
		enemy.execute_turn(character)
		await get_tree().create_timer(0.5).timeout
	return true

# Personnages encore présents et non marqués pour destruction (queue_free).
func _get_alive_characters() -> Array[Character]:
	var alive: Array[Character] = []
	for _character in character_container.get_children():
		if not _character.is_queued_for_deletion():
			alive.append(_character)
	return alive

func _on_enemy_pressed(_Enemy: Enemy):
	if card_selected != null:
			if character_selected != null:
				if character_selected.available:
					card_selected.execute_card(character_selected, _Enemy)
					await get_tree().create_timer(0.1).timeout
					print('Test Fin de Jeu')
					_test_end_fight()
					character_selected.available = false
					character_selected.character_image.material.set_shader_parameter("active", true)
					EventBus.character_pressed.emit(null)
	
#func somme(accum: int, nombre: Character):
#	return accum + nombre.Character_HP
#
#
#func _enemy_turn() -> void:
#	for i in range(enemy_array.size()):
#		if character_array.size() > 0:
#			enemy_array[i].position = Vector2(enemy_array[i].position.x,enemy_array[i].position.y+50)
#			await get_tree().create_timer(0.2).timeout
#			
#			var id_attacked : int = rng.randi_range(0,character_array.size()-1)
#			character_array[id_attacked].deal_dmg(enemy_array[i].Enemy_Attack)
#			
#			if character_array[id_attacked].Character_HP < 0:
#				character_array[id_attacked].queue_free()
#				character_array.remove_at(id_attacked)
#			
#			heal = character_array.reduce(somme,0)
#			heal_label.set_text("Health = "+str(heal))
#			enemy_array[i].position = Vector2(enemy_array[i].position.x,enemy_array[i].position.y-50)
#			await get_tree().create_timer(0.3).timeout
#	_test_end_fight()
#
#
func _on_end_round_pressed() -> void:
	#Enemy Turn
	await enemy_turn()
	
	var range: int = 5-CombatUI.HandManager.get_child_count()
	for i in range(range):
		CombatUI.HandManager._add_card()
	for _character in character_container.get_children():
		_character.available = true
		_character.character_image.material.set_shader_parameter("active", false)
		#reset character_available
	_test_end_fight()

func _test_end_fight() -> void:
	print(str(character_container.get_child_count()))
	print(str(enemy_container.get_child_count()))
	if character_container.get_child_count() == 0:
		end_fight_label.set_text('LOSS')
		await get_tree().create_timer(1).timeout
		fight_end.emit(0)
		get_tree().quit()
	if enemy_container.get_child_count() == 0:
		end_fight_label.set_text('VICTORY')
		await get_tree().create_timer(1).timeout
		fight_end.emit(1)
		get_tree().quit()
#		
#
