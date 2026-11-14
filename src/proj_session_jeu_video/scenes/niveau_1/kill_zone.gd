extends Area2D

func _ready() -> void:
	# print("[KILLZONE] active position globale=", global_position,
	# 	" masque de collision=", collision_mask)
	pass


func _on_body_entered(body: Node2D) -> void:
	print("Player entered killzone")
	var player := body as Player
	if player != null:
		print("[KILLZONE] Player entré dans la zone")
		player.mourir()