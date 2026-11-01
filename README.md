# Opération Drapeaux : Simulation Navale

Projet `0SW_Projet_Godot` : développement de mon jeu pour le cours de jeux vidéos.

> Un soldat de la marine doit récupérer le drapeau de chaque niveau pour décrocher son diplôme de marin, mais attention : les insectes qui l'entourent ne sont pas ce qu'ils semblent être.

---

## 1. Présentation

**Opération Drapeaux** est un jeu d'action dans lequel le joueur incarne un **soldat de la marine**. Sa mission : traverser chaque **niveau** et **récupérer le drapeau** qui s'y trouve, véritable **prix** de l'épreuve.

Les niveaux sont infestés d'**insectes**. Ils sont dangereux en apparence, mais ils sont en réalité **des entités simulées** : tout l'environnement fait partie d'un programme d'entraînement virtuel conçu par la marine. Le joueur affronte donc une simulation dont les « bêtes » obéissent à des règles précises qu'il peut apprendre, anticiper et exploiter.

## 2. Objectifs du jeu

| Type | Objectif |
|---|---|
| **Principal** | Récupérer le **drapeau de niveau**. |
| **Secondaire** | Terminer la mission en un minimum de temps (**badge**). |
| **Secondaire** | Préserver au maximum ses **points de vie** (**badge**). |

**Condition de victoire :** récupérer le drapeau de niveau.
**Condition de défaite :** les points de vie du soldat tombent à zéro.

## 3. Concepts utilisés dans le projet

### 3.1 Le soldat (joueur)
Entité contrôlée au clavier, à la manette ou au joystick de l'arcade. Il possède :
- une **position** et une **vitesse** de déplacement ;
- des **points de vie** ;
- un **chronomètre** de mission, utilisé pour l'attribution du badge.

### 3.2 Le drapeau de niveau (objectif / récompense)
Chaque niveau contient un drapeau à atteindre. Lorsque le soldat entre en **collision** avec lui, il est récupéré : le niveau est réussi et la partie est gagnée.

### 3.3 Les insectes
Les insectes sont le cœur du concept. Ce sont des **agents autonomes** qui :
- se déplacent selon un comportement défini (patrouille, poursuite, déplacement aléatoire) ;
- réagissent à la présence du soldat (zone de détection) ;
- infligent des dégâts au contact.

> 💡 **« Tout est simulation » :** les insectes n'existent pas réellement dans l'univers du jeu. Ils sont générés par le programme d'entraînement. Cela justifie leur logique prévisible et permet des mécaniques propres à la simulation (apparition, réinitialisation, paramétrage de la difficulté).

### 3.4 Le niveau et la simulation
- **Niveau** : un espace de jeu fixe contenant le soldat, les insectes et le drapeau.
- **Boucle de jeu** : à chaque cycle, le programme (1) lit les commandes, (2) met à jour les entités, (3) détecte les collisions, (4) vérifie les conditions de victoire/défaite, (5) affiche le résultat.
- **Paramètres de simulation** : nombre d'insectes, vitesse et agressivité, ajustables pour faire varier la difficulté.

### 3.5 Le badge
Récompense secondaire : si le joueur récupère le drapeau en dessous d'un **temps cible**, il obtient le badge. Il encourage la rejouabilité et la maîtrise du niveau.

### 3.6 Principes de programmation mobilisés
- **Programmation orientée objet** : classes `Joueur`, `Drapeau`, `Insecte`, `Niveau`.
- **Héritage / polymorphisme** : différents types d'insectes partageant une base commune.
- **Détection de collisions** entre entités.
- **Gestion d'état** : points de vie, chronomètre, victoire, défaite.
- **Comportements autonomes** pour les insectes.

### 3.7 Organisation du code du joueur

- [player.gd](src/proj_session_jeu_video/scripts/player/player.gd) coordonne la physique, les composants et la machine à états.
- [arsenal_player.gd](src/proj_session_jeu_video/scripts/player/arsenal_player.gd), sur le nœud `Arsenal`, gère les armes, la cadence et les munitions.
- [vie_player.gd](src/proj_session_jeu_video/scripts/player/vie_player.gd), sur le nœud `Vie`, gère les dégâts et l'invincibilité. La vie maximale se règle sur ce nœud dans l'inspecteur.
- [visuel_player.gd](src/proj_session_jeu_video/scripts/player/visuel_player.gd) gère les animations Spriter et leurs variantes de visée.
- Sur le nœud `Visuel` de [player.tscn](src/proj_session_jeu_video/scenes/player.tscn), les références typées `entite_joueur`, `animation_player`, `sprite_arme` et `point_bouche` se configurent dans l'inspecteur. L'adaptateur les reçoit directement, sans recherche de secours. Si la structure importée change, il faut réassigner ces références ; les entités d'effets restent masquées dans la scène Spriter.
- Le marqueur `Muzzle` est enfant du sprite de l'arme directement dans la scène Spriter ; l'adaptateur vérifie ce parent sans déplacer le nœud. Sa position utilise le rectangle du sprite et la hauteur `bouche_y` de l'arme équipée : il suit les animations, le retournement du joueur et les changements de fusil. Les tirs conservent leur direction horizontale et leur dispersion.
- Les commandes de tir activent d'abord la visée ; les projectiles sont émis après le déplacement et la mise à jour de la pose, pour utiliser le canon affiché dans ce tick.
- Le test de régression du canon se lance depuis le projet avec `godot --headless --path . --script res://tests/test_player_muzzle.gd`.
- Les [états](src/proj_session_jeu_video/scripts/player/States) héritent directement de `BaseState` et conservent leurs déplacements et transitions.

Les signaux du joueur et ses méthodes `recevoir_degats`, `ajouter_munitions` et `rafraichir` restent disponibles. Les données se lisent désormais via `player.arsenal` (armes, munitions, index) et `player.sante` (vie, invincibilité).

## 4. Déroulement d'une partie

1. La simulation se lance : le niveau est chargé avec les insectes et le drapeau.
2. Le soldat avance en évitant les insectes pour préserver ses points de vie.
3. Il atteint le drapeau de niveau : **victoire** (avec badge étoile si le temps cible est respecté).
4. Si ses points de vie tombent à zéro : **défaite**.

## 5. Contrôles *(pas fini)*

| Touche | Action |
|---|---|
| `Espace` `A` `D` | Déplacer le soldat |
| `0` | Tirer
| `R` | Relancer la simulation |
| `Échap` | Quitter |
