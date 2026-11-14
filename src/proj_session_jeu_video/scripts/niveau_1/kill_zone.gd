extends Area2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	print("[KILLZONE] active position globale=", global_position,
		" masque de collision=", collision_mask)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		print("[KILLZONE] Player entré dans la zone")
		body.mourir()
