shader_type canvas_item;

// Couleur vers laquelle le sprite est poussé quand il est touché.
uniform vec4 couleur_flash : source_color = vec4(1.0, 1.0, 1.0, 1.0);
// 0 = sprite normal, 1 = entièrement recouvert par couleur_flash.
uniform float intensite : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	// En Godot 4, COLOR contient déjà texture × modulate : ne pas reéchantillonner TEXTURE.
	// L'alpha est conservé : la silhouette et le clignotement d'invincibilité restent intacts.
	COLOR.rgb = mix(COLOR.rgb, couleur_flash.rgb, intensite * couleur_flash.a);
}
