# CLAUDE.md

Ce fichier guide Claude Code (et tout contributeur) sur le projet **Project_Robbery** (nom Godot : « Rob »).

> **Règle obligatoire : tenir ce fichier à jour.** À chaque modification du projet (code, scènes, ressources, architecture, conventions, correction d'un bug listé…), mettre à jour `CLAUDE.md` en conséquence, dans le même commit : ajouter ce qui est nouveau, corriger ce qui a changé, retirer des « Points d'attention connus » les bugs corrigés. Ce fichier doit toujours refléter l'état actuel du projet.

## Le projet

Projet solo. Jeu de cartes 2D au tour par tour, de type *deckbuilder roguelike*.

### Vision
- **Pitch** : le joueur dirige une **équipe de braqueurs** et enchaîne les casses, de plus en plus difficiles (de la supérette à la banque nationale).
- **Mondes** : chaque « Monde » a pour thème un pays.
- **Casse = plateau** : chaque casse est un plateau de jeu à la *Slay the Spire*, composé de combats et d'autres activités.
- **Deck commun** à toute l'équipe ; certaines cartes nécessitent **plusieurs personnages** pour être jouées.
- Les sprites actuels (pack craftpix « desert enemy ») sont des **placeholders** hors thème, à remplacer quand la démo technique sera plus aboutie : ne pas s'appuyer dessus pour des choix de design.

### État actuel
**Démo technique d'un seul combat.** Le joueur pioche dans un deck de départ (pioche mélangée, défausse remélangée quand la pioche est vide) et contrôle 1 à 3 personnages face à des ennemis. À chaque tour, il sélectionne une carte, autant de personnages disponibles que son coût, puis un ennemi cible. **L'énergie est le nombre de personnages disponibles** : chaque personnage ne peut être mobilisé qu'une fois par tour (il passe en niveaux de gris une fois utilisé). Quand le joueur termine son tour, chaque ennemi joue son action, puis la main est complétée jusqu'à 5 cartes. En fin de combat (`VICTORY` / `LOSS`), le jeu se ferme (`get_tree().quit()`). Pas encore de plateau, ni de deck qui évolue entre les combats.

## Stack

- **Godot 4.6**, renderer Forward Plus, physique Jolt, driver D3D12 sous Windows.
- **GDScript** uniquement (pas de C#/.NET).
- Pas de tests automatisés, pas de CI, pas d'addons.
- Lancement : ouvrir `project.godot` dans l'éditeur Godot 4.6 et lancer (F5). Scène principale : `scenes/FightManager.tscn`.
  En ligne de commande (si Godot est installé) : `godot --path . ` ou vérification de parsing : `godot --headless --path . --quit`.

## Arborescence

```
project.godot            Config moteur + autoloads
scenes/                  Scènes .tscn (+ shader Character.gdshader)
scripts/                 Scripts attachés aux scènes
scripts/Autoload/        Singletons : EventBus, CardDatabase, EnemyDatabase
scripts/Ressources/      Classes Resource de données (CardData, EnemyData, ActionData et ses sous-classes)
Ressources/Cards/        Instances .tres de cartes (ex. Pistol.tres)
Ressources/Enemies/      Instances .tres d'ennemis (ex. Gobelin.tres)
sprite/                  Assets graphiques (pack craftpix « desert enemy » + UI)
```

## Architecture

### Arbre de scènes du combat
```
FightManager (Node2D, FightManager.gd)      ← scène principale, orchestre le combat
├── CombatUI (Control, CombatUI.gd)
│   ├── EndTurnButton
│   ├── HandManager (HBoxContainer, HandManager.gd)  ← contient les CardUI
│   └── EnergyLabel      ← « Énergie : disponibles / vivants », via CombatUI.update_energy()
├── Enemy_Container      ← instances de Enemy.tscn
├── Character_Container  ← instances de Character.tscn
├── Enemy_SpawnPoints (5) / Character_SpawnPoints (3)
├── Character_Selected_Pin   ← modèle caché, dupliqué pour chaque personnage sélectionné
└── End_Fight_Label
```

### Arbre de la main de jeu
```
HandManager (HBoxContainer « Hand », HandManager.gd, scenes/HandManager.tscn)
│   alignment = center ; placé dans le tiers bas de l'écran par CombatUI
│   signal sort_children → _on_sort_children() → EventBus.hand_update
│   draw_pile / discard_pile : Array[CardData] (données, pas de nœuds)
└── Card × N (Control, CardUI.gd, scenes/CardUI.tscn)  ← instanciées par draw_card()
    ├── BaseCardSprite2   (TextureRect)  fond de carte (s-l400.jpg)
    ├── CostBaseSprite    (TextureRect)  pastille de coût (mana.png)
    ├── ValueBaseSprite   (TextureRect)  pastille de valeur (mana.png)
    ├── CardImage         (TextureRect)  ← CardData.texture (Web-700.png par défaut)
    ├── CostLabel         (Label)        ← CardData.cost_value
    ├── CardLabel         (Label)        ← CardData.name
    ├── ValueLabel        (Label)        ← CardData.get_display_value()
    └── CardDescription   (Label)        ← CardData.Description
```

**`HandManager.gd`**
- `setup_deck(deck_id)` : remplit `draw_pile` avec `CardDatabase.get_deck(deck_id)`, la mélange et vide la défausse. Appelé par `FightManager._ready()` avec `"starter"`.
- `draw_card() -> bool` : prend la carte du dessus de la pioche, instancie `CardUI.tscn`, l'ajoute à la main et recalcule l'espacement. Pioche vide → la défausse est remélangée dans la pioche. Renvoie `false` si pioche et défausse sont vides.
- `_on_card_played(card_data)` (sur `EventBus.card_played`) : ajoute la carte jouée à la défausse.
- `_remove_card(card)` : détruit la carte et recalcule l'espacement (non utilisé pour l'instant : `Card.execute_card()` fait elle-même `queue_free()`).
- `_set_Separation()` : si la largeur totale des cartes dépasse 2/3 de la largeur du viewport, applique une séparation négative pour les faire se chevaucher ; sinon séparation de 4 px. La largeur d'une carte est mesurée une seule fois par `_get_card_width()` (instance temporaire aussitôt libérée), puis mise en cache.
- `_on_sort_children()` : à chaque réagencement du conteneur, émet `EventBus.hand_update` pour que chaque carte mémorise sa position de repos.

**`CardUI.gd` (classe `Card`)** : comportement d'une carte dans la main.
- `hand_update` → mémorise `x_position_base` / `y_position_base` (position de repos).
- Survol (`mouse_entered/exited`) → tween d'échelle (`hover_scale`) et de hauteur (`hover_up`), `z_index` à 10.
- Clic gauche (`gui_input`) → `EventBus.card_pressed`.
- `card_selected` → la carte sélectionnée s'agrandit, monte et passe au premier plan (`z_index` 100) ; les autres reviennent à leur position de repos.
- `execute_card(caster, target)` → exécute chaque `CardActionData` de `data.base_actions`, émet `EventBus.card_played(data)` (→ défausse), puis `queue_free()`.

### Autoloads (singletons)
- **`EventBus`** : bus de signaux global découplant UI et logique. Signaux : `card_pressed`, `card_selected`, `card_played`, `hand_update`, `character_pressed`, `enemy_pressed`, `end_turn_pressed`.
- **`CardDatabase`** : dictionnaire `id → CardData` (`cards`, via `get_card(id)`) + decks de départ (`starter_decks` : liste d'ids, une entrée par exemplaire), via `get_deck(id)`. Seul le deck `"starter"` existe (10 Pistolets).
- **`EnemyDatabase`** : dictionnaire `id → EnemyData` (`enemies`) + groupes de rencontres (`encounter_groups`), via `get_encounter(id)`. Un id de rencontre ou d'ennemi inconnu déclenche un `push_error` (visible dans le débogueur) au lieu d'être ignoré. Seul `goblin` existe : il remplit toutes les rencontres en attendant d'autres ennemis.

### Données (pattern Resource)
Le contenu du jeu est défini en **données**, pas en code :
- `CardData` : `id`, `name`, `Description`, `cost_value` (= nombre de personnages à mobiliser, 1 par défaut), `texture`, `base_actions: Array[CardActionData]` ; `get_display_value()` renvoie la `base_value` de la première action (valeur affichée sur la carte).
- `EnemyData` : `id`, `name`, `max_hp`, `texture`, `possible_actions: Array[EnemyActionData]` ; `get_next_action()` fait tourner les actions en boucle selon le numéro de tour.
- `ActionData` (classe de base) : `id`, `action_type` (`ATTACK`, `DEFEND`, `BUFF`, `DEBUFF`, `UNKNOW`), `icon`, `base_value`, et `execute(caster, target)`. `CardActionData` et `EnemyActionData` en héritent sans rien ajouter : elles servent à typer les actions des cartes et des ennemis.

**Contrat « combattant » (duck typing)** : `execute()` appelle `take_damage`, `defend`, `apply_buff`, `apply_debuff` sur le caster/la cible et lit `caster.attack_modifier`. `Character` et `Enemy` doivent tous deux exposer ces 4 méthodes et la variable `attack_modifier: int`.

**Buffs / debuffs** : chaque combattant a un `attack_modifier` propre à son instance (jamais stocké dans la ressource `EnemyData`, partagée entre ennemis du même type). `apply_buff` l'augmente, `apply_debuff` le diminue ; il reste actif tout le combat. Une action `ATTACK` inflige `max(0, base_value + caster.attack_modifier)`.

### Flux d'un tour
1. Clic sur une carte → `EventBus.card_pressed` → `FightManager` mémorise/désélectionne la carte et émet `card_selected` (les CardUI s'animent).
2. Clic sur un personnage disponible → `character_pressed` → il est ajouté à `selected_characters` (ou retiré s'il y était déjà) et un pin s'affiche au-dessus de lui. `character_pressed(null)` vide la sélection.
3. Clic sur un ennemi → `enemy_pressed` → si une carte est sélectionnée et que **exactement `cost_value`** personnages disponibles sont sélectionnés : la sélection est vidée, tous les personnages mobilisés deviennent indisponibles, l'énergie est mise à jour, puis `card.execute_card(premier_sélectionné, enemy)` (le premier sélectionné est le lanceur), test de fin de combat. Sinon, rien ne se passe.
4. Bouton fin de tour → `end_turn_pressed` → sélection vidée → `enemy_turn()` (chaque ennemi attaque un personnage vivant aléatoire, via `_get_alive_characters()`, 0,5 s entre chaque ; la boucle s'arrête si toute l'équipe est morte), main re-complétée à 5 depuis la pioche, personnages réactivés, énergie mise à jour, test de fin de combat.

### Ajouter du contenu
- **Nouvelle carte** : créer un `.tres` de type `CardData` dans `Ressources/Cards/` (avec ses `CardActionData` en sous-ressources), puis l'ajouter à `CardDatabase.cards` et aux decks de `starter_decks`.
- **Nouvel ennemi** : créer un `.tres` `EnemyData` dans `Ressources/Enemies/`, l'ajouter à `EnemyDatabase.enemies`, puis le référencer dans `encounter_groups`.
- **Nouveau type d'action** : étendre l'enum `ActionType` et le `match` dans `ActionData.gd`, puis implémenter la méthode correspondante dans `Character` et `Enemy`.

## Conventions

- Langue : commentaires et messages de commit **en français** ; identifiants de code en anglais.
- Nommage : `class_name` en PascalCase ; fonctions/variables en `snake_case` (quelques exceptions historiques : `Character_HP`, `Description`, `_set_Separation`).
- Typage statique GDScript privilégié (`var x: int`, `-> void`, `Array[CardData]`).
- Nœuds référencés par `@onready var ... = $Chemin` ; les signaux d'éditeur sont connectés dans les `.tscn` (`_on_<node>_<signal>`).
- Communication inter-systèmes via **`EventBus`** plutôt que par références directes.
- Les fichiers `.uid` et `.import` sont versionnés : toujours les committer avec leur fichier source. Ne pas éditer à la main les `uid://` dans les `.tscn`/`.tres`.
- Préférer modifier les scènes `.tscn` via l'éditeur Godot ; une édition texte doit rester minimale et préserver les `uid`/`unique_id`.
- Ne jamais versionner `.godot/` (cache de l'éditeur) ni les fichiers `*.tmp` (sauvegardes temporaires de l'éditeur) : ils sont dans `.gitignore`.

## Points d'attention connus

Criticité notée de **1 à 5** (5 = le plus critique) :
- **5** : plantage ou blocage en jeu normal.
- **4** : plantage latent (dès qu'un contenu prévu est ajouté) ou corruption de données.
- **3** : comportement faux visible par le joueur, ou fuite de ressources.
- **2** : fonctionnalité incomplète, incohérence ou dette technique sans impact immédiat.
- **1** : cosmétique, propreté du code.

Liste triée par criticité décroissante. Retirer une ligne dès que le point est corrigé.

| Crit. | Point |
|:---:|---|
| 2 | Aucun retour visuel quand on clique un ennemi sans avoir sélectionné le bon nombre de personnages : le clic est simplement ignoré. |
| 2 | Les boucliers (`current_shield`, personnages et ennemis) ne sont jamais réinitialisés entre les tours et ne sont pas affichés. |
| 2 | Les personnages n'ont pas encore de données propres (`CharacterData`) : tous ont les mêmes PV (`FightManager.character_hp`, 50 par défaut) et un sprite ennemi temporaire. |
| 1 | L'intention ennemie (`_update_intent_ui`) est écrite mais désactivée (`intent_icon`/`intent_label` non assignés). |
| 1 | `FightManager` : la variable `heal` (somme des PV des personnages) est calculée mais inutilisée. |
| 1 | Plusieurs scripts gardent un en-tête copié-collé erroné (`# EnemyData.gd` dans `CardData.gd`, `CardActionData.gd`… ; `# EnemyDatabase.gd` dans `CardDatabase.gd`). |
