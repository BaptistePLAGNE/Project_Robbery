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

### Arbre de la main de jeu
```
HandManager (HBoxContainer « Hand », HandManager.gd, scenes/HandManager.tscn)
│   alignment = center ; placé dans le tiers bas de l'écran par CombatUI
│   signal sort_children → _on_sort_children() → EventBus.hand_update
└── Card × N (Control, CardUI.gd, scenes/CardUI.tscn)  ← instanciées par _add_card()
    ├── BaseCardSprite2   (TextureRect)  fond de carte (s-l400.jpg)
    ├── CostBaseSprite    (TextureRect)  pastille de coût (mana.png)
    ├── ValueBaseSprite   (TextureRect)  pastille de valeur (mana.png)
    ├── CardImage         (TextureRect)  illustration (Web-700.png, placeholder)
    ├── CostLabel         (Label)        ← CardData.cost_value
    ├── CardLabel         (Label)        nom de la carte (texte placeholder)
    ├── ValueLabel        (Label)        ← CardData.base_value
    └── CardDescription   (Label)        description (texte placeholder)
```

**`HandManager.gd`**
- `_add_card()` : instancie `CardUI.tscn`, l'ajoute à la main, l'initialise avec la première carte de `CardDatabase.get_encounter("act1_easy_1")`, puis recalcule l'espacement.
- `_remove_card(card)` : détruit la carte et recalcule l'espacement (non utilisé pour l'instant : `Card.execute_card()` fait elle-même `queue_free()`).
- `_set_Separation()` : si la largeur totale des cartes dépasse 2/3 de la largeur du viewport, applique une séparation négative pour les faire se chevaucher ; sinon séparation de 4 px. (Instancie une carte temporaire pour lire sa taille, sans la libérer.)
- `_on_sort_children()` : à chaque réagencement du conteneur, émet `EventBus.hand_update` pour que chaque carte mémorise sa position de repos.

**`CardUI.gd` (classe `Card`)** : comportement d'une carte dans la main.
- `hand_update` → mémorise `x_position_base` / `y_position_base` (position de repos).
- Survol (`mouse_entered/exited`) → tween d'échelle (`hover_scale`) et de hauteur (`hover_up`), `z_index` à 10.
- Clic gauche (`gui_input`) → `EventBus.card_pressed`.
- `card_selected` → la carte sélectionnée s'agrandit, monte et passe au premier plan (`z_index` 100) ; les autres reviennent à leur position de repos.
- `execute_card(caster, target)` → exécute chaque `CardActionData` de `data.base_actions`, puis `queue_free()`.

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
4. Bouton fin de tour → `end_turn_pressed` → `enemy_turn()` (chaque ennemi attaque un personnage vivant aléatoire, via `_get_alive_characters()`, 0,5 s entre chaque ; la boucle s'arrête si toute l'équipe est morte), main re-complétée à 5, personnages réactivés, test de fin de combat.

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

Criticité notée de **1 à 5** (5 = le plus critique) :
- **5** : plantage ou blocage en jeu normal.
- **4** : plantage latent (dès qu'un contenu prévu est ajouté) ou corruption de données.
- **3** : comportement faux visible par le joueur, ou fuite de ressources.
- **2** : fonctionnalité incomplète, incohérence ou dette technique sans impact immédiat.
- **1** : cosmétique, propreté du code.

Liste triée par criticité décroissante. Retirer une ligne dès que le point est corrigé.

| Crit. | Point |
|:---:|---|
| 4 | `Enemy.apply_buff/apply_debuff` modifient `data.attack`, mais `EnemyData` ne déclare pas de champ `attack` (pourtant présent dans `Gobelin.tres`) → erreur à l'exécution si un buff/debuff ennemi est joué. De plus, modifier `data` altère la ressource partagée par tous les ennemis du même type. |
| 3 | Le label de valeur de la carte affiche `CardData.base_value`, alors que les dégâts réels viennent de `CardActionData.base_value` (le Pistolet affiche 1 mais inflige 15). |
| 3 | `HandManager._set_Separation()` instancie une carte à chaque appel sans jamais la libérer (fuite mémoire). |
| 2 | `CardUI.init_card()` ne renseigne ni `CardLabel` ni `CardDescription` (ils gardent leur texte placeholder de la scène) ni `CardImage` (ligne commentée). |
| 2 | `EnemyDatabase.encounter_groups` référence des ennemis inexistants (`cultist`, `jaw_worm`, `boss_slime`) : ils sont silencieusement ignorés (une rencontre peut se retrouver vide). |
| 2 | `CardDatabase.cards_hand` / `get_encounter` reprennent la structure des rencontres ennemies ; `HandManager._add_card()` pioche toujours la première carte de `act1_easy_1` (pas encore de vrai deck/pioche/défausse). |
| 2 | `cost_value` et `EnergyLabel` ne sont pas encore utilisés (pas de système d'énergie). |
| 2 | `Character.defend/apply_buff/apply_debuff` sont des stubs ; les personnages ont des PV aléatoires (1–100) et un sprite ennemi temporaire. |
| 2 | `CardActionData` et `EnemyActionData` sont des copies quasi identiques (même enum, même `execute`) : toute modification doit être faite dans les deux. |
| 2 | `FightManager` : le spawn des ennemis utilise `enemy_spawn_point_array[i].position` (position locale) alors que les personnages utilisent `global_position` (sans effet tant que `Enemy_SpawnPoints` est à l'origine). |
| 1 | L'intention ennemie (`_update_intent_ui`) est écrite mais désactivée (`intent_icon`/`intent_label` non assignés). |
| 1 | `FightManager` : la variable `heal` (somme des PV des personnages) est calculée mais inutilisée. |
| 1 | Plusieurs scripts gardent un en-tête copié-collé erroné (`# EnemyData.gd` dans `CardData.gd`, `CardActionData.gd`… ; `# EnemyDatabase.gd` dans `CardDatabase.gd`). |
