"""Génère le fond en parallaxe du niveau 1 : jungle industrielle, de jour, en pixel art.

Usage : python outils/generer_fond.py
Écrit 4 calques PNG (480 × 270, transparents sauf le ciel) dans
src/proj_session_jeu_video/assets/fonds/niveau_1/ :
  1_ciel.png, 2_lointain.png, 3_industriel.png, 4_jungle.png
Chaque calque se répète sans couture à l'horizontale (tout est calculé modulo la largeur).
Perspective atmosphérique : plus un calque est lointain, plus il est clair, bleuté et désaturé,
pour que les tuiles claires du niveau se détachent devant. Sans dépendance.
"""

import math
import random
import struct
import zlib
from pathlib import Path

L, H = 480, 270
DOSSIER = Path(__file__).resolve().parent.parent / "src" / "proj_session_jeu_video" / "assets" / "fonds" / "niveau_1"

CYAN = (63, 224, 208)
VERT_NEON = (90, 230, 130)
ROUGE = (255, 70, 70)


class Calque:
    def __init__(self, opaque=False):
        self.px = [[(0, 0, 0, 255 if opaque else 0) for _ in range(L)] for _ in range(H)]

    def poser(self, x, y, couleur, alpha=255):
        x %= L  # répétition horizontale sans couture
        if 0 <= y < H:
            if alpha >= 255:
                self.px[y][x] = (*couleur, 255)
            else:
                r, g, b, a = self.px[y][x]
                t = alpha / 255
                self.px[y][x] = (int(r + (couleur[0] - r) * t), int(g + (couleur[1] - g) * t),
                                 int(b + (couleur[2] - b) * t), max(a, alpha))

    def rect(self, x, y, l, h, couleur):
        for j in range(y, y + h):
            for i in range(x, x + l):
                self.poser(i, j, couleur)

    def colonne(self, x, y_haut, couleur):
        for y in range(max(0, y_haut), H):
            self.poser(x, y, couleur)

    def enregistrer(self, nom):
        DOSSIER.mkdir(parents=True, exist_ok=True)
        brut = b"".join(b"\x00" + bytes(c for p in ligne for c in p) for ligne in self.px)

        def bloc(type_, donnees):
            return struct.pack(">I", len(donnees)) + type_ + donnees + struct.pack(">I", zlib.crc32(type_ + donnees))

        png = b"\x89PNG\r\n\x1a\n" + bloc(b"IHDR", struct.pack(">IIBBBBB", L, H, 8, 6, 0, 0, 0))
        png += bloc(b"IDAT", zlib.compress(brut, 9)) + bloc(b"IEND", b"")
        (DOSSIER / nom).write_bytes(png)
        print(f"  {nom}")


def relief(graine, amplitude, frequences=(1, 2, 3, 5, 8, 13)):
    """Profil périodique (fréquences entières : se raccorde parfaitement d'un bord à l'autre)."""
    r = random.Random(graine)
    composantes = [(f, amplitude / (1 + i * 0.9), r.uniform(0, math.tau)) for i, f in enumerate(frequences)]
    return [sum(a * math.sin(math.tau * f * x / L + p) for f, a, p in composantes) for x in range(L)]


def melange(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


# --- 1. Ciel -----------------------------------------------------------------

def ciel():
    c = Calque(opaque=True)
    haut, milieu, horizon = (92, 158, 196), (150, 200, 214), (206, 232, 214)
    r = random.Random(1)
    for y in range(H):
        t = y / (H - 1)
        base = melange(haut, milieu, t / 0.55) if t < 0.55 else melange(milieu, horizon, (t - 0.55) / 0.45)
        for x in range(L):
            col = base
            # Tramage léger (style pixel art) pour adoucir le dégradé.
            if (x + y) % 2 == 0 and r.random() < 0.12:
                col = melange(col, (255, 255, 255), 0.06)
            c.poser(x, y, col)
    # Soleil et son halo.
    sx, sy, rayon = 372, 48, 13
    for y in range(sy - 40, sy + 41):
        for x in range(sx - 40, sx + 41):
            d = math.hypot(x - sx, y - sy)
            if d <= rayon:
                c.poser(x, y, (255, 250, 222) if d < rayon - 1 else (255, 236, 180))
            elif d < 40:
                c.poser(x, y, (255, 245, 210), int(110 * (1 - (d - rayon) / (40 - rayon)) ** 2))
    # Nuages : amas de disques, ombrés par le bas (dessinés modulo la largeur).
    for _ in range(9):
        cx, cy = r.randrange(L), r.randint(25, int(H * 0.42))
        bulles = [(cx + r.randint(-22, 22), cy + r.randint(-5, 4), r.randint(6, 13)) for _ in range(r.randint(5, 9))]
        for bx, by, br in bulles:
            for y in range(by - br, by + br + 1):
                for x in range(bx - br, bx + br + 1):
                    if math.hypot(x - bx, y - by) <= br:
                        ombre = y > cy + 2
                        c.poser(x, y, (214, 230, 236) if ombre else (246, 250, 250))
    return c


# --- 2. Montagnes et jungle lointaines ---------------------------------------

def lointain():
    c = Calque()
    sommets = relief(2, 18)
    canopee = relief(3, 4, (7, 11, 17, 23, 29))
    corps, arete = (122, 170, 170), (150, 196, 188)
    for x in range(L):
        haut = int(H * 0.56 + sommets[x] + canopee[x])
        c.colonne(x, haut, corps)
        c.poser(x, haut, arete)
        c.poser(x, haut + 1, melange(corps, arete, 0.4))
    # Brume à la base des montagnes.
    for y in range(int(H * 0.7), H):
        for x in range(L):
            c.poser(x, y, (225, 240, 236), int(110 * (y - H * 0.7) / (H * 0.3)))
    return c


# --- 3. Complexe industriel --------------------------------------------------

def industriel():
    c = Calque()
    r = random.Random(4)
    sol = int(H * 0.8)
    corps, contour = (88, 118, 122), (114, 148, 150)

    def fenetres(x, y, l, h):
        for j in range(y + 3, y + h - 2, 4):
            for i in range(x + 2, x + l - 2, 3):
                if r.random() < 0.22:
                    c.poser(i, j, (58, 84, 90) if r.random() < 0.75 else CYAN)

    def balise(x, y):
        c.poser(x, y, ROUGE)
        for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            c.poser(x + dx, y + dy, ROUGE, 90)

    x = 0
    while x < L:
        genre = r.choice(("tour", "tour", "cheminee", "cuve", "grue", "bloc"))
        if genre == "tour":
            l, h = r.randint(14, 24), r.randint(60, 115)
            c.rect(x, sol - h, l, h, corps)
            c.rect(x, sol - h, l, 1, contour)
            fenetres(x, sol - h, l, h)
            if r.random() < 0.6:  # bande néon horizontale
                yb = sol - h + r.randint(6, h // 2)
                for i in range(x, x + l):
                    c.poser(i, yb, CYAN)
            ant = r.randint(8, 20)
            for j in range(ant):
                c.poser(x + l // 2, sol - h - 1 - j, contour)
            balise(x + l // 2, sol - h - ant - 1)
        elif genre == "cheminee":
            l, h = r.randint(6, 9), r.randint(95, 140)
            c.rect(x, sol - h, l, h, corps)
            for k in range(3):  # anneaux
                c.rect(x - 1, sol - h + 10 + k * 25, l + 2, 2, contour)
            balise(x + l // 2, sol - h - 2)
            l += 4
        elif genre == "cuve":
            l = r.randint(22, 32)
            rayon = l // 2
            cx, cy = x + rayon, sol - r.randint(14, 30)
            for j in range(cy - rayon, sol):
                for i in range(x, x + l):
                    if j >= cy or math.hypot(i - cx, j - cy) <= rayon:
                        c.poser(i, j, corps)
            for i in range(x + 2, x + l - 2):
                c.poser(i, cy + 4, VERT_NEON)
        elif genre == "grue":
            l, h = r.randint(26, 40), r.randint(90, 125)
            for j in range(sol - h, sol):  # mât en treillis
                c.poser(x + 2, j, corps)
                c.poser(x + 5, j, corps)
                if (j // 4) % 2 == 0:
                    c.poser(x + 3 + (j % 2), j, contour)
            for i in range(x, x + l):  # flèche
                c.poser(i, sol - h, corps)
                c.poser(i, sol - h + 1, contour if i % 3 == 0 else corps)
            for j in range(r.randint(10, 30)):  # câble
                c.poser(x + l - 3, sol - h + 2 + j, contour)
            balise(x + 3, sol - h - 2)
        else:  # bloc bas avec néons
            l, h = r.randint(26, 44), r.randint(24, 45)
            c.rect(x, sol - h, l, h, corps)
            c.rect(x, sol - h, l, 1, contour)
            fenetres(x, sol - h, l, h)
        x += l + r.randint(2, 14)

    # Tronçons de tuyaux entre les structures, avec leurs supports.
    for _ in range(6):
        x0, longueur, y = r.randrange(L), r.randint(30, 90), sol - r.randint(10, 45)
        for i in range(x0, x0 + longueur):
            c.poser(i, y, contour)
            c.poser(i, y + 1, corps)
            c.poser(i, y + 2, corps)
        for i in range(x0 + 4, x0 + longueur, r.randint(14, 22)):
            for j in range(y + 3, sol):
                c.poser(i, j, corps)
    # Sol et lueur néon au pied du complexe.
    c.rect(0, sol, L, H - sol, (80, 108, 110))
    for i in range(L):
        c.poser(i, sol, contour)
    return c


# --- 4. Jungle proche --------------------------------------------------------

def jungle():
    c = Calque()
    r = random.Random(5)
    sombre, feuille, reflet = (44, 92, 62), (64, 132, 74), (128, 196, 104)
    masse = relief(6, 10, (2, 3, 5, 9, 14))
    base = int(H * 0.82)
    for x in range(L):
        c.colonne(x, int(base + masse[x]), sombre)

    def palme(cx, cy, taille):
        """Bouquet de feuilles pointues partant d'un même point, en éventail."""
        for k in range(r.randint(6, 9)):
            angle = math.pi + (k + 0.5) / 8 * math.pi + r.uniform(-0.15, 0.15)
            longueur = taille * r.uniform(0.7, 1.1)
            for s in range(int(longueur)):
                t = s / longueur
                x = cx + math.cos(angle) * s
                y = cy + math.sin(angle) * s + (t ** 2) * longueur * 0.45  # les feuilles retombent
                epaisseur = max(1, int(3 * (1 - t)))
                for e in range(-epaisseur, epaisseur + 1):
                    c.poser(int(x), int(y) + e, feuille)
                c.poser(int(x), int(y) - epaisseur, reflet)
        for j in range(cy, H):  # tronc
            c.poser(cx, j, sombre)
            c.poser(cx + 1, j, sombre)

    # Fourrés : touffes de feuilles pointues sur toute la masse, avec reflets sur le dessus.
    for _ in range(70):
        cx = r.randrange(L)
        haut = int(base + masse[cx])
        for k in range(r.randint(4, 8)):
            dx = r.randint(-8, 8)
            hauteur_feuille = r.randint(6, 16)
            penche = r.choice((-1, 1)) * r.uniform(0.1, 0.5)
            for s in range(hauteur_feuille):
                x = cx + dx + int(penche * s)
                for e in range(-1 if s < hauteur_feuille - 3 else 0, 1):
                    c.poser(x + e, haut - s, feuille)
            c.poser(cx + dx + int(penche * hauteur_feuille), haut - hauteur_feuille, reflet)
    # Palmiers, plus grands au premier plan.
    for _ in range(8):
        cx = r.randrange(L)
        palme(cx, int(base + masse[cx]) - r.randint(35, 75), r.randint(30, 48))
    # Lianes épaisses qui pendent du haut, avec des feuilles.
    for _ in range(5):
        x0, longueur = r.randrange(L), r.randint(22, 60)
        phase = r.uniform(0, math.tau)
        for y in range(longueur):
            x = x0 + int(3 * math.sin(y / 11 + phase))
            c.poser(x, y, feuille)
            c.poser(x + 1, y, sombre)
            if y % 6 == 0:
                cote = 1 if (y // 6) % 2 else -1
                for k in range(1, 5):
                    c.poser(x + cote * k, y + k // 2, feuille)
                c.poser(x + cote * 4, y + 2, reflet)
    return c


if __name__ == "__main__":
    print("Calques du fond (niveau 1) :")
    ciel().enregistrer("1_ciel.png")
    lointain().enregistrer("2_lointain.png")
    industriel().enregistrer("3_industriel.png")
    jungle().enregistrer("4_jungle.png")
