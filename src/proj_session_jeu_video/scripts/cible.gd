extends StaticBody2D

@export var vie := 100

func recevoir_degats(quantite: int, _origine_x: float = 0.0) -> void:
	vie -= quantite
	print("Cible touchée : -", quantite, " (reste ", maxi(vie, 0), ")")
	modulate = Color(1.0, 0.4, 0.4)
	await get_tree().create_timer(0.08).timeout
	if not is_instance_valid(self):
		return
	modulate = Color.WHITE
	if vie <= 0:
		queue_free()