
extends Node2D

# ==================================================
# OPERATION DRAPEAUX - CHAMP DE BATAILLE PROCEDURAL
# Resolution de reference : 1152 x 648
# Aucun fichier image necessaire
# ==================================================

const W := 1152.0
const H := 648.0

var temps := 0.0

# Couleurs principales
const NOIR := Color("#061817")
const SOMBRE := Color("#082B28")
const VERT := Color("#08765A")
const LUMIERE := Color("#00E99A")
const BRUME := Color("#4BCBA0")

func _ready() -> void:
    queue_redraw()


func _process(delta: float) -> void:
    temps += delta
    queue_redraw()


func _draw() -> void:

    # Adaptation a la taille de la fenetre
    var taille = get_viewport_rect().size

    draw_set_transform(
        Vector2.ZERO,
        0.0,
        Vector2(taille.x / W, taille.y / H)
    )

    dessiner_ciel()
    dessiner_nuages()
    dessiner_rayons()
    dessiner_montagnes()
    dessiner_brouillard()
    dessiner_ville()
    dessiner_tour(65, 290, 1.0)
    dessiner_tour(940, 395, 0.8)
    dessiner_char()
    dessiner_drapeau(380, 275, 1.0)
    dessiner_drapeau(900, 335, 0.75)
    dessiner_obstacles()
    dessiner_barbeles()
    dessiner_terrain()
    dessiner_fumee()
    dessiner_braises()


# ==================================================
# 1. CIEL
# ==================================================

func dessiner_ciel() -> void:

    # Degrade vertical
    for i in range(100):

        var p = float(i) / 100.0

        var couleur = Color(
            0.005 + p * 0.005,
            0.035 + p * 0.20,
            0.045 + p * 0.12
        )

        draw_rect(
            Rect2(0, i * 6.5, W, 7),
            couleur
        )

    # Lumiere a l'horizon
    for i in range(30):

        var alpha = 0.025 * (1.0 - float(i) / 30.0)

        draw_rect(
            Rect2(0, 310 + i * 4, W, 5),
            Color(0.0, 0.9, 0.48, alpha)
        )


# ==================================================
# 2. NUAGES
# ==================================================

func dessiner_nuages() -> void:

    var positions = [
        Vector2(40, 130),
        Vector2(150, 180),
        Vector2(290, 125),
        Vector2(470, 155),
        Vector2(700, 120),
        Vector2(900, 155),
        Vector2(1080, 110)
    ]

    for i in range(positions.size()):

        var pos = positions[i]

        # Nuages principaux
        for j in range(5):

            var decalage = Vector2(
                j * 27.0 - 45,
                sin(float(j) * 1.7 + i) * 20
            )

            var rayon = 65.0 + sin(i + j) * 18.0

            draw_circle(
                pos + decalage,
                rayon,
                Color("#064538")
            )

        # Reflets verts
        draw_circle(
            pos + Vector2(-10, -15),
            45,
            Color(0.0, 0.48, 0.29, 0.35)
        )

        draw_circle(
            pos + Vector2(25, 5),
            35,
            Color(0.02, 0.34, 0.22, 0.4)
        )


# ==================================================
# 3. RAYONS LUMINEUX
# ==================================================

func dessiner_rayons() -> void:

    for i in range(13):

        var x = 420.0 + i * 38.0

        var variation = sin(temps * 0.8 + i) * 7.0

        var alpha = 0.055 + sin(temps * 1.5 + i) * 0.015

        var points = PackedVector2Array([
            Vector2(x, 170),
            Vector2(x + 25, 170),
            Vector2(x + 230 + variation, 560),
            Vector2(x + 140 + variation, 560)
        ])

        draw_colored_polygon(
            points,
            Color(0.0, 1.0, 0.45, alpha)
        )


# ==================================================
# 4. MONTAGNES
# ==================================================

func dessiner_montagnes() -> void:

    # Montagnes lointaines
    draw_colored_polygon(
        PackedVector2Array([
            Vector2(0, 440),
            Vector2(100, 390),
            Vector2(220, 420),
            Vector2(390, 350),
            Vector2(510, 400),
            Vector2(690, 300),
            Vector2(850, 390),
            Vector2(990, 340),
            Vector2(1152, 420),
            Vector2(1152, 600),
            Vector2(0, 600)
        ]),
        Color("#075D4D")
    )

    # Deuxieme relief
    draw_colored_polygon(
        PackedVector2Array([
            Vector2(0, 480),
            Vector2(170, 430),
            Vector2(310, 470),
            Vector2(500, 380),
            Vector2(650, 440),
            Vector2(810, 370),
            Vector2(1000, 460),
            Vector2(1152, 410),
            Vector2(1152, 610),
            Vector2(0, 610)
        ]),
        Color("#064638")
    )

    # Montagnes proches
    draw_colored_polygon(
        PackedVector2Array([
            Vector2(0, 525),
            Vector2(160, 475),
            Vector2(330, 530),
            Vector2(520, 450),
            Vector2(720, 510),
            Vector2(920, 455),
            Vector2(1152, 530),
            Vector2(1152, 648),
            Vector2(0, 648)
        ]),
        Color("#052F2C")
    )

    # Quelques cretes lumineuses
    draw_line(
        Vector2(390, 475),
        Vector2(520, 450),
        Color(0.0, 0.8, 0.45, 0.35),
        2.0
    )

    draw_line(
        Vector2(720, 510),
        Vector2(920, 455),
        Color(0.0, 0.7, 0.4, 0.25),
        2.0
    )


# ==================================================
# 5. BROUILLARD
# ==================================================

func dessiner_brouillard() -> void:

    for i in range(16):

        var x = i * 85.0 - 50.0

        var mouvement = sin(temps * 0.3 + i) * 12.0

        var alpha = 0.045 + sin(temps + i) * 0.012

        draw_circle(
            Vector2(x + mouvement, 495 + i % 3 * 18),
            75,
            Color(0.1, 0.8, 0.55, alpha)
        )


# ==================================================
# 6. VILLE ET RUINES
# ==================================================

func dessiner_ville() -> void:

    var couleur = Color("#071F1D")

    # Batiments a gauche
    draw_rect(Rect2(0, 390, 70, 120), couleur)
    draw_rect(Rect2(75, 420, 55, 90), couleur)
    draw_rect(Rect2(140, 400, 90, 110), couleur)

    # Ruines centrales
    draw_rect(Rect2(470, 445, 55, 75), couleur)
    draw_rect(Rect2(540, 420, 65, 100), couleur)
    draw_rect(Rect2(620, 455, 55, 65), couleur)

    # Forteresse a droite
    draw_rect(Rect2(930, 385, 135, 130), couleur)

    draw_rect(Rect2(950, 365, 30, 20), couleur)
    draw_rect(Rect2(1015, 350, 30, 35), couleur)

    # Creneaux
    for i in range(5):

        draw_rect(
            Rect2(940 + i * 25, 375, 12, 12),
            couleur
        )

    # Fenetres
    for i in range(3):

        for j in range(2):

            draw_rect(
                Rect2(
                    950 + i * 35,
                    410 + j * 40,
                    10,
                    18
                ),
                Color("#020D0D")
            )


# ==================================================
# 7. TOUR DE SURVEILLANCE
# ==================================================

func dessiner_tour(x: float, y: float, echelle: float) -> void:

    var c = Color("#061B1A")

    # Pieds
    draw_line(
        Vector2(x, y),
        Vector2(x - 20 * echelle, y + 190 * echelle),
        c,
        8 * echelle
    )

    draw_line(
        Vector2(x + 65 * echelle, y),
        Vector2(x + 85 * echelle, y + 190 * echelle),
        c,
        8 * echelle
    )

    # Renforts
    for i in range(3):

        var yy = y + 45 * echelle + i * 45 * echelle

        draw_line(
            Vector2(x - 10 * echelle, yy),
            Vector2(x + 75 * echelle, yy + 45 * echelle),
            c,
            4 * echelle
        )

        draw_line(
            Vector2(x + 75 * echelle, yy),
            Vector2(x - 10 * echelle, yy + 45 * echelle),
            c,
            4 * echelle
        )

    # Plateforme
    draw_rect(
        Rect2(
            x - 25 * echelle,
            y - 10 * echelle,
            115 * echelle,
            15 * echelle
        ),
        c
    )

    # Cabine
    draw_rect(
        Rect2(
            x - 15 * echelle,
            y - 55 * echelle,
            95 * echelle,
            45 * echelle
        ),
        c
    )

    # Toit
    draw_colored_polygon(
        PackedVector2Array([
            Vector2(x - 25 * echelle, y - 55 * echelle),
            Vector2(x + 25 * echelle, y - 85 * echelle),
            Vector2(x + 100 * echelle, y - 55 * echelle)
        ]),
        c
    )


# ==================================================
# 8. CHAR MILITAIRE
# ==================================================

func dessiner_char() -> void:

    var c = Color("#061C1A")

    # Chenilles
    draw_rect(
        Rect2(145, 480, 205, 45),
        c
    )

    draw_rect(
        Rect2(160, 488, 175, 28),
        Color("#102C28")
    )

    # Roues
    for i in range(6):

        draw_circle(
            Vector2(165 + i * 31, 502),
            12,
            Color("#020C0B")
        )

    # Corps
    draw_colored_polygon(
        PackedVector2Array([
            Vector2(160, 480),
            Vector2(180, 440),
            Vector2(315, 440),
            Vector2(350, 480)
        ]),
        Color("#0A302A")
    )

    # Tourelle
    draw_colored_polygon(
        PackedVector2Array([
            Vector2(205, 440),
            Vector2(225, 412),
            Vector2(290, 412),
            Vector2(310, 440)
        ]),
        c
    )

    # Canon
    draw_line(
        Vector2(285, 420),
        Vector2(405, 397),
        c,
        12
    )

    draw_line(
        Vector2(285, 420),
        Vector2(405, 397),
        Color("#102F29"),
        6
    )


# ==================================================
# 9. DRAPEAUX
# ==================================================

func dessiner_drapeau(
    x: float,
    y: float,
    echelle: float
) -> void:

    var mouvement = sin(temps * 2.0 + x) * 8.0

    # Mât
    draw_line(
        Vector2(x, y),
        Vector2(x, y + 190 * echelle),
        Color("#071B19"),
        5 * echelle
    )

    # Tissu
    draw_colored_polygon(
        PackedVector2Array([
            Vector2(x, y),
            Vector2(x + 35 * echelle, y + 10 * echelle + mouvement),
            Vector2(x + 85 * echelle, y + 32 * echelle),
            Vector2(x + 115 * echelle, y + 20 * echelle + mouvement),
            Vector2(x + 90 * echelle, y + 65 * echelle),
            Vector2(x + 50 * echelle, y + 55 * echelle + mouvement),
            Vector2(x, y + 75 * echelle)
        ]),
        Color("#071F1D")
    )


# ==================================================
# 10. OBSTACLES ANTICHARS
# ==================================================

func dessiner_obstacle(x: float, y: float, taille: float) -> void:

    var c = Color("#061715")

    draw_line(
        Vector2(x - taille, y - taille),
        Vector2(x + taille, y + taille),
        c,
        12
    )

    draw_line(
        Vector2(x + taille, y - taille),
        Vector2(x - taille, y + taille),
        c,
        12
    )

    draw_line(
        Vector2(x - taille * 0.6, y),
        Vector2(x + taille * 0.6, y),
        c,
        7
    )


func dessiner_obstacles() -> void:

    dessiner_obstacle(65, 560, 30)
    dessiner_obstacle(1080, 550, 35)
    dessiner_obstacle(900, 570, 22)


# ==================================================
# 11. BARBELES
# ==================================================

func dessiner_barbeles() -> void:

    var points = PackedVector2Array()

    for i in range(15):

        var x = 0.0 + i * 85.0
        var y = 535.0 + sin(i * 1.8) * 15.0

        points.append(Vector2(x, y))

    draw_polyline(
        points,
        Color("#071816"),
        3.0
    )

    for p in points:

        draw_line(
            p + Vector2(-6, -8),
            p + Vector2(6, 8),
            Color("#071816"),
            2
        )


# ==================================================
# 12. TERRAIN ROCHEUX
# ==================================================

func dessiner_terrain() -> void:

    # Grande masse rocheuse
    draw_colored_polygon(
        PackedVector2Array([
            Vector2(0, 580),
            Vector2(120, 550),
            Vector2(270, 565),
            Vector2(420, 535),
            Vector2(600, 555),
            Vector2(780, 525),
            Vector2(960, 555),
            Vector2(1152, 535),
            Vector2(1152, 648),
            Vector2(0, 648)
        ]),
        Color("#071A19")
    )

    # Rochers du premier plan
    draw_colored_polygon(
        PackedVector2Array([
            Vector2(0, 625),
            Vector2(90, 585),
            Vector2(180, 625),
            Vector2(260, 590),
            Vector2(360, 648),
            Vector2(0, 648)
        ]),
        Color("#0A2925")
    )

    draw_colored_polygon(
        PackedVector2Array([
            Vector2(850, 648),
            Vector2(930, 590),
            Vector2(1020, 615),
            Vector2(1100, 575),
            Vector2(1152, 610),
            Vector2(1152, 648)
        ]),
        Color("#0A2925")
    )

    # Craquelures
    for i in range(12):

        var x = 80 + i * 90
        var y = 590 + (i % 3) * 12

        draw_line(
            Vector2(x, y),
            Vector2(x + 25, y + 12),
            Color("#020D0D"),
            3
        )

    # Reflet vert du sol
    draw_line(
        Vector2(250, 555),
        Vector2(900, 550),
        Color(0.0, 0.9, 0.48, 0.4),
        3
    )


# ==================================================
# 13. FUMEE ANIMEE
# ==================================================

func dessiner_fumee() -> void:

    for i in range(8):

        var mouvement = sin(temps * 0.5 + i) * 18.0

        var hauteur = fmod(temps * 18.0 + i * 27.0, 100.0)

        var alpha = 0.12 * (1.0 - hauteur / 120.0)

        draw_circle(
            Vector2(
                800 + mouvement,
                500 - hauteur
            ),
            25 + hauteur * 0.2,
            Color(0.12, 0.25, 0.22, alpha)
        )


# ==================================================
# 14. BRAISES ANIMEES
# ==================================================

func dessiner_braises() -> void:

    for i in range(35):

        var x = fposmod(
            i * 137.0 + temps * (12.0 + i % 5),
            W
        )

        var y = 450.0 + fposmod(i * 53.0, 190.0)

        var alpha = 0.4 + sin(temps * 3.0 + i) * 0.35

        draw_circle(
            Vector2(x, y),
            1.5 + float(i % 3),
            Color(1.0, 0.48, 0.12, alpha)
        )

