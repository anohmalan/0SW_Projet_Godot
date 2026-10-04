extends Node2D

@onready var joueur: Joueur = $Joueur

func _ready() -> void:
	joueur.vie_changee.connect(func(v, m): print("Vie : ", v, " / ", m))
	joueur.tir_demande.connect(func(pos, dir): print("Tir de ", pos, " vers ", dir))
	joueur.est_mort.connect(func(): print("Le joueur est mort"))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_H:
				joueur.recevoir_degats(20)
			KEY_R:
				get_tree().reload_current_scene()