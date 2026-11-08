extends Control

@export var title_text := "OPÉRATION DRAPEAUX"
@export_range(32, 96, 1) var font_size := 66
@export_range(0, 40, 1) var curve_height := 20
@export var fill_color := Color("#F9FFF3")
@export var outline_color := Color("#072F25")
@export var glow_color := Color(0.0, 0.98, 0.58, 0.72)

func _ready() -> void:
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var font := get_theme_default_font()
	if font == null or title_text.is_empty():
		return

	var text_width := 0.0
	for index in range(title_text.length()):
		text_width += font.get_string_size(
			title_text.substr(index, 1), HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size
		).x
	var cursor_x := (size.x - text_width) * 0.5
	var half_width := maxf(text_width * 0.5, 1.0)
	var base_y := size.y - 20.0

	for index in range(title_text.length()):
		var character := title_text.substr(index, 1)
		var character_width := font.get_string_size(
			character, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size
		).x
		var center_x := cursor_x + character_width * 0.5
		cursor_x += character_width
		if character == " ":
			continue

		var offset_x := center_x - size.x * 0.5
		var courbure := offset_x / half_width
		var baseline_y := base_y - curve_height * (1.0 - courbure * courbure)
		var angle := atan(2.0 * curve_height * offset_x / (half_width * half_width))
		draw_set_transform(Vector2(center_x, baseline_y), angle)
		var position_lettre := Vector2(-character_width * 0.5, 0.0)

		draw_string_outline(
			font, position_lettre + Vector2(0.0, 5.0), character,
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, 12, glow_color
		)
		draw_string_outline(
			font, position_lettre, character,
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, 8, outline_color
		)
		draw_string(
			font, position_lettre, character,
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, fill_color
		)

	draw_set_transform(Vector2.ZERO)
