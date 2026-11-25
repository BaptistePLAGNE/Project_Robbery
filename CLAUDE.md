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
**Démo technique d'un seul combat.** Le joueur contrôle 1 à 3 personnages face à des ennemis. À chaque tour, il sélectionne une carte, un personnage disponible, puis un ennemi cible. Chaque personnage ne peut agir qu'une fois par tour (il passe en niveaux de gris une fois utilisé). Quand le joueur termine son tour, chaque ennemi joue son action, puis la main est complétée jusqu'à 5 cartes. En fin de combat (`VICTORY` / `LOSS`), le jeu se ferme (`get_tree().quit()`). Pas encore de plateau, de deck, de pioche/défausse ni d'énergie.

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
scripts/Ressources/      Classes Resource de données (CardData, EnemyData, *ActionData)
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
│   └── EnergyLabel                                    (pas encore branché)
├── Enemy_Container      ← instances de Enemy.tscn
├── Character_Container  ← instances de Character.tscn
├── Enemy_SpawnPoints (5) / Character_SpawnPoints (3)
├── Character_Selected_Pin
└── End_Fight_Label
```

### Autoloads (singletons)
- **`EventBus`** : bus de signaux global découplant UI et logique. Signaux : `card_pressed`, `card_selected`, `hand_update`, `character_pressed`, `enemy_pressed`, `end_turn_pressed`.
- **`CardDatabase`** : dictionnaire `id → CardData` (`cards`) + listes de cartes prédéfinies (`cards_hand`), récupérées via `get_encounter(id)`.
- **`EnemyDatabase`** : dictionnaire `id → EnemyData` (`enemies`) + groupes de rencontres (`encounter_groups`), via `get_encounter(id)`.

### Données (pattern Resource)
Le contenu du jeu est défini en **données**, pas en code :
- `CardData` : `id`, `name`, `Description`, `cost_value`, `base_value`, `texture`, `base_actions: Array[CardActionData]`.
- `EnemyData` : `id`, `name`, `max_hp`, `texture`, `possible_actions: Array[EnemyActionData]` ; `get_next_action()` fait tourner les actions en boucle selon le numéro de tour.
- `CardActionData` / `EnemyActionData` : `action_type` (`ATTACK`, `DEFEND`, `BUFF`, `DEBUFF`, `UNKNOW`) + `base_value`, et `execute(caster, target)`.

**Contrat « combattant » (duck typing)** : `execute()` appelle `take_damage`, `defend`, `apply_buff`, `apply_debuff` sur le caster/la cible. `Character` et `Enemy` doivent tous deux exposer ces 4 méthodes.

### Flux d'un tour
1. Clic sur une carte → `EventBus.card_pressed` → `FightManager` mémorise/désélectionne la carte et émet `card_selected` (les CardUI s'animent).
2. Clic sur un personnage disponible → `character_pressed` → le pin de sélection s'affiche.
3. Clic sur un ennemi → `enemy_pressed` → si carte + personnage disponibles : `card.execute_card(character, enemy)`, la carte est détruite, le personnage devient indisponible, test de fin de combat.
4. Bouton fin de tour → `end_turn_pressed` → `enemy_turn()` (chaque ennemi attaque un personnage aléatoire, 0,5 s entre chaque), main re-complétée à 5, personnages réactivés, test de fin de combat.

### Ajouter du contenu
- **Nouvelle carte** : créer un `.tres` de type `CardData` dans `Ressources/Cards/` (avec ses `CardActionData` en sous-ressources), puis l'ajouter à `CardDatabase.cards` et aux listes de `cards_hand`.
- **Nouvel ennemi** : créer un `.tres` `EnemyData` dans `Ressources/Enemies/`, l'ajouter à `EnemyDatabase.enemies`, puis le référencer dans `encounter_groups`.
- **Nouveau type d'action** : étendre l'enum `ActionType` et le `match` dans **les deux** fichiers `*ActionData.gd` (ils sont dupliqués), puis implémenter la méthode correspondante dans `Character` et `Enemy`.

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

- `Enemy.apply_buff/apply_debuff` modifient `data.attack`, mais `EnemyData` ne déclare pas de champ `attack` (pourtant présent dans `Gobelin.tres`) → erreur à l'exécution si un buff/debuff ennemi est joué. De plus, modifier `data` altère la ressource partagée par tous les ennemis du même type.
- `EnemyDatabase.encounter_groups` référence des ennemis inexistants (`cultist`, `jaw_worm`, `boss_slime`) : ils sont silencieusement ignorés.
- `CardDatabase.cards_hand` / `get_encounter` reprennent la structure des rencontres ennemies ; `HandManager._add_card()` pioche toujours la première carte de `act1_easy_1` (pas encore de vrai deck/pioche/défausse).
- `cost_value` et `EnergyLabel` ne sont pas encore utilisés (pas de système d'énergie).
- Le label de valeur de la carte affiche `CardData.base_value`, alors que les dégâts réels viennent de `CardActionData.base_value`.
- `Character.defend/apply_buff/apply_debuff` sont des stubs ; les personnages ont des PV aléatoires (1–100) et un sprite ennemi temporaire.
- L'intention ennemie (`_update_intent_ui`) est écrite mais désactivée (`intent_icon`/`intent_label` non assignés).
- `CardActionData` et `EnemyActionData` sont des copies quasi identiques (même enum, même `execute`) : toute modification doit être faite dans les deux.
- Plusieurs scripts gardent un en-tête copié-collé erroné (`# EnemyData.gd` dans `CardData.gd`, `CardActionData.gd`… ; `# EnemyDatabase.gd` dans `CardDatabase.gd`).
- `FightManager` : la variable `heal` (somme des PV des personnages) est calculée mais inutilisée ; le spawn des ennemis utilise `enemy_spawn_point_array[i].position` (position locale) alors que les personnages utilisent `global_position`.
- `enemy_turn()` ne vérifie pas qu'il reste des personnages : si l'équipe meurt avant le dernier ennemi, `character_container.get_child(...)` renvoie `null` et l'appel à `execute` plante (le test de fin de combat n'a lieu qu'après la boucle).
