class_name PlayerMelee
extends BaseState

## Coup de couteau : debout, accroupi ou en l'air selon la posture au moment de l'appui.
## L'animation Spriter boucle : la durée du coup est donc chronométrée ici.

@export var player: Player

var _temps := 0.0
var _a_frappe := false

func enter() -> void:
	_temps = 0.0
	_a_frappe = false
	player.temps_depuis_melee = 0.0
	Audio.jouer("couteau", Vector2.INF, -3.0)
	var nom := "Melee"
	if player.accroupi:
		nom = "Crouch_Melee"
	elif not player.is_on_floor():
		nom = "Jump_Melee"
	player.visuel.jouer(nom, true)

func handle_inputs(_input_event: InputEvent) -> void:
	pass

func physics_update(delta: float) -> void:
	_temps += delta
	if player.is_on_floor():
		player.freiner_horizontalement(delta)
	else:
		player.deplacer_horizontalement(delta)
	if not _a_frappe and _temps >= player.moment_impact:
		_a_frappe = true
		player.frapper()

func update(_delta: float) -> void:
	if _temps < player.duree_melee:
		return
	var rester_accroupi := player.accroupi and player.is_on_floor() \
		and (Input.get_action_strength("bas") >= player.seuil_accroupi or not player.peut_se_relever())
	if rester_accroupi:
		Transitioned.emit(self, &"PlayerCrouch")
		return
	player.se_relever(not player.is_on_floor())
	if player.is_on_floor():
		Transitioned.emit(self, player.etat_au_sol())
	else:
		Transitioned.emit(self, player.etat_en_l_air())

func exit() -> void:
	pass
