shader_type canvas_item;

// Coupe tout ce qui est dessiné hors d'un disque (mini-carte ronde).
uniform vec2 centre = vec2(90.0, 90.0);
uniform float rayon = 88.0;

varying vec2 position_locale;

void vertex() {
	// VERTEX est en coordonnées locales du Control : on le transmet au fragment.
	position_locale = VERTEX;
}

void fragment() {
	float distance_centre = length(position_locale - centre);
	if (distance_centre > rayon) {
		discard;
	}
	// Bord légèrement adouci pour éviter l'effet d'escalier.
	COLOR.a *= 1.0 - smoothstep(rayon - 1.5, rayon, distance_centre);
}
