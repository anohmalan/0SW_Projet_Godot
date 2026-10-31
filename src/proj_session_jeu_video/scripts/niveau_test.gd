extends Node2D

@onready var player: Player = $Player
@onready var pool: PoolBalles = $PoolBalles

func _ready() -> void:
	player.tir_demande.connect(
		func(pos, dir, arme): pool.tirer(pos, dir, arme, true))
	player.vie_changee.connect(func(v, m): print("Vie : ", v, " / ", m))
	player.arme_changee.connect(func(a, m):
		print("Arme : ", a.nom, " (munitions : ",
			"illimitées" if m < 0 else str(m), ")"))
	player.munitions_changees.connect(func(m): print("Munitions : ", m))
	player.est_mort.connect(func(): print("Le player est mort"))
	player.rafraichir()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_H:
				player.recevoir_degats(20)
			KEY_G:
				for i in player.arsenal.armes.size():
					player.ajouter_munitions(i, 99)
			KEY_R:
				get_tree().reload_current_scene()
