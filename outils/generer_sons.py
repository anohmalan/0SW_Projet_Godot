"""Génère les effets sonores et les musiques du jeu, style militaire réaliste, sans dépendance.

Usage : python outils/generer_sons.py
Écrit des .wav (mono, 16 bits, 32 kHz) dans
src/proj_session_jeu_video/assets/audio/effets et .../assets/audio/musique.
Le hasard est initialisé : relancer le script redonne exactement les mêmes fichiers.

Les sons sont synthétisés (bruit filtré, saturation, réverbération) pour imiter des
détonations, impacts et une musique d'action percussive. Pour un rendu parfait, chaque
fichier peut être remplacé par un enregistrement réel portant le même nom.
"""

import math
import random
import struct
import wave
from pathlib import Path

FREQ = 32000
RACINE = Path(__file__).resolve().parent.parent / "src" / "proj_session_jeu_video" / "assets" / "audio"
random.seed(1944)


# --- Générateurs -------------------------------------------------------------

def n_ech(duree):
    return int(duree * FREQ)


def silence(duree):
    return [0.0] * n_ech(duree)


def bruit(duree):
    return [random.uniform(-1.0, 1.0) for _ in range(n_ech(duree))]


def sinus(freq_debut, freq_fin, duree, volume=1.0):
    n, phase, sortie = n_ech(duree), 0.0, []
    for i in range(n):
        t = i / max(n - 1, 1)
        f = freq_debut * (freq_fin / freq_debut) ** t
        phase += 2 * math.pi * f / FREQ
        sortie.append(math.sin(phase) * volume)
    return sortie


def scie(freq, duree, volume=1.0, desaccord=0.0):
    """Dent de scie (deux voix légèrement désaccordées pour un son de cordes/cuivres)."""
    n, sortie = n_ech(duree), []
    p1 = p2 = 0.0
    for _ in range(n):
        p1 = (p1 + freq / FREQ) % 1.0
        p2 = (p2 + freq * (1 + desaccord) / FREQ) % 1.0
        sortie.append(((2 * p1 - 1) + (2 * p2 - 1)) * 0.5 * volume)
    return sortie


# --- Traitements -------------------------------------------------------------

def passe_bas(son, coupure):
    a = 1.0 - math.exp(-2 * math.pi * coupure / FREQ)
    sortie, y = [], 0.0
    for x in son:
        y += a * (x - y)
        sortie.append(y)
    return sortie


def passe_haut(son, coupure):
    bas = passe_bas(son, coupure)
    return [x - b for x, b in zip(son, bas)]


def passe_bande(son, basse, haute):
    return passe_bas(passe_haut(son, basse), haute)


def passe_bas_glissant(son, coupure_debut, coupure_fin):
    """Filtre dont la coupure descend (ou monte) au fil du son : souffle qui s'assourdit."""
    n, sortie, y = len(son), [], 0.0
    for i, x in enumerate(son):
        t = i / max(n - 1, 1)
        c = coupure_debut * (coupure_fin / coupure_debut) ** t
        y += (1.0 - math.exp(-2 * math.pi * c / FREQ)) * (x - y)
        sortie.append(y)
    return sortie


def enveloppe(son, attaque=0.001, decroissance=0.1, maintien=0.0):
    """Attaque linéaire, maintien, puis décroissance exponentielle (constante de temps en s)."""
    a, m = max(1, n_ech(attaque)), n_ech(maintien)
    sortie = []
    for i, x in enumerate(son):
        if i < a:
            g = i / a
        elif i < a + m:
            g = 1.0
        else:
            g = math.exp(-(i - a - m) / (decroissance * FREQ))
        sortie.append(x * g)
    return sortie


def saturer(son, force=2.0):
    return [math.tanh(x * force) / math.tanh(force) for x in son]


def normaliser(son, crete=1.0):
    m = max(1e-9, max(abs(x) for x in son))
    return [x / m * crete for x in son]


def gain(son, g):
    return [x * g for x in son]


def melanger(*sons):
    n = max(len(s) for s in sons)
    sortie = [0.0] * n
    for s in sons:
        for i, x in enumerate(s):
            sortie[i] += x
    return sortie


def decaler(son, delai):
    return silence(delai) + son


def reverb(son, piece=1.0, amortissement=0.4, humide=0.3, queue=1.0):
    """Réverbération de Schroeder : 4 filtres en peigne amortis + 2 passe-tout.
    piece agrandit les délais (pièce plus grande), queue allonge le son pour laisser l'écho."""
    entree = son + silence(queue)
    delais_peigne = [int(d * piece * FREQ / 44100) for d in (1557, 1617, 1491, 1422)]
    retour = 0.82
    somme = [0.0] * len(entree)
    for d in delais_peigne:
        tampon, filtre, idx = [0.0] * d, 0.0, 0
        for i, x in enumerate(entree):
            y = tampon[idx]
            filtre = y * (1 - amortissement) + filtre * amortissement
            tampon[idx] = x + filtre * retour
            idx = (idx + 1) % d
            somme[i] += y
    sortie = [s * 0.25 for s in somme]
    for d in (int(225 * piece * FREQ / 44100), int(556 * piece * FREQ / 44100)):
        tampon, idx, resultat = [0.0] * d, 0, []
        for x in sortie:
            b = tampon[idx]
            y = -x + b
            tampon[idx] = x + b * 0.5
            idx = (idx + 1) % d
            resultat.append(y)
        sortie = resultat
    return [x * (1 - humide) + w * humide for x, w in zip(entree, sortie)]


def ecrire(chemin, son, crete=0.9):
    chemin.parent.mkdir(parents=True, exist_ok=True)
    son = normaliser(son, crete)
    # Petit fondu de sortie pour éviter un clic final.
    f = min(len(son), n_ech(0.01))
    for i in range(f):
        son[-1 - i] *= i / f
    with wave.open(str(chemin), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(FREQ)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, x)) * 32767)) for x in son))
    print(f"  {chemin.name:24s} {len(son) / FREQ:5.2f} s")


# --- Briques militaires ------------------------------------------------------

def claquement(duree=0.012, coupure=2500):
    """Onde de choc : bruit très bref, aigu."""
    return enveloppe(passe_haut(bruit(duree), coupure), 0.0005, duree / 3)


def detonation(corps=1200, duree_corps=0.12, grave=(90, 40), duree_grave=0.1, saturation=2.5):
    """Coup de feu : claquement + corps de bruit filtré + coup grave, le tout saturé."""
    c = claquement()
    b = enveloppe(passe_bas(bruit(duree_corps * 3), corps), 0.001, duree_corps)
    g = enveloppe(sinus(grave[0], grave[1], duree_grave * 2, 1.0), 0.002, duree_grave)
    return saturer(melanger(gain(c, 0.9), gain(b, 1.0), gain(g, 0.9)), saturation)


def clic_metallique(freq=2400, duree=0.03, volume=1.0):
    bruit_bref = enveloppe(passe_bande(bruit(duree), freq * 0.6, freq * 1.6), 0.0005, duree / 4)
    tintement = enveloppe(sinus(freq * 1.7, freq * 1.7, duree * 3, 0.25), 0.0005, duree)
    return gain(melanger(bruit_bref, tintement), volume)


def coup_sourd(freq=110, duree=0.12, coupure=350):
    corps = enveloppe(passe_bas(bruit(duree * 3), coupure), 0.002, duree)
    grave = enveloppe(sinus(freq, freq * 0.5, duree * 2), 0.002, duree)
    return saturer(melanger(corps, grave), 1.5)


def souffle(duree, f_debut, f_fin, attaque=0.03):
    return enveloppe(passe_bas_glissant(passe_haut(bruit(duree), 300), f_debut, f_fin), attaque, duree / 3)


# --- Effets ------------------------------------------------------------------

def effets():
    e = {}
    e["tir_fusil"] = reverb(detonation(1400, 0.07, (110, 50), 0.06, 3.0), piece=0.8, humide=0.22, queue=0.25)
    pompe = melanger(clic_metallique(1800, 0.04), decaler(clic_metallique(1300, 0.05), 0.12))
    e["tir_pompe"] = melanger(
        reverb(detonation(800, 0.16, (75, 32), 0.14, 3.5), piece=1.0, humide=0.25, queue=0.3),
        decaler(gain(pompe, 0.5), 0.38))
    e["tir_sniper"] = reverb(
        melanger(gain(claquement(0.008, 4000), 1.4), detonation(1000, 0.1, (90, 38), 0.12, 4.0)),
        piece=1.8, amortissement=0.3, humide=0.45, queue=1.1)
    # Tir des monstres-yeux : décharge organique, grave et visqueuse.
    e["tir_ennemi"] = reverb(melanger(
        enveloppe(passe_bas_glissant(bruit(0.3), 3000, 400), 0.005, 0.08),
        enveloppe(sinus(220, 70, 0.3, 0.8), 0.005, 0.09)), piece=0.6, humide=0.2, queue=0.15)
    e["impact"] = melanger(coup_sourd(160, 0.05, 600), gain(claquement(0.006, 3000), 0.4))
    e["joueur_touche"] = melanger(coup_sourd(120, 0.09, 450), decaler(gain(souffle(0.12, 1200, 300), 0.4), 0.02))
    e["chute"] = melanger(coup_sourd(80, 0.14, 250),
                          *[decaler(clic_metallique(random.uniform(1500, 3000), 0.02, 0.25), random.uniform(0.02, 0.12))
                            for _ in range(5)])
    growl = enveloppe(passe_bas(scie(70, 0.6, 1.0, 0.03), 500), 0.01, 0.25)
    e["ennemi_mort"] = reverb(melanger(
        coup_sourd(130, 0.1, 500),
        gain(growl, 0.6),
        gain(enveloppe(passe_bas_glissant(bruit(0.6), 2500, 200), 0.01, 0.2), 0.5)), piece=0.8, humide=0.25, queue=0.3)
    e["explosion"] = reverb(saturer(melanger(
        gain(claquement(0.02, 1500), 1.2),
        enveloppe(passe_bas_glissant(bruit(2.0), 3000, 120), 0.003, 0.45),
        enveloppe(sinus(65, 25, 1.5, 1.2), 0.005, 0.4)), 3.0), piece=1.6, amortissement=0.5, humide=0.35, queue=1.2)
    e["saut"] = gain(melanger(souffle(0.15, 1500, 600, 0.02), coup_sourd(200, 0.03, 900)), 0.7)
    e["couteau"] = melanger(
        enveloppe(passe_bande(bruit(0.22), 2500, 7000), 0.04, 0.05, 0.03),
        decaler(enveloppe(sinus(3800, 3600, 0.3, 0.12), 0.001, 0.08), 0.06))
    zip_ = enveloppe([x * (0.5 + 0.5 * math.sin(i / FREQ * 2 * math.pi * 45)) for i, x in
                      enumerate(passe_bande(bruit(0.25), 1500, 6000))], 0.01, 0.12, 0.08)
    e["soin"] = melanger(gain(zip_, 0.7), decaler(clic_metallique(1100, 0.04, 0.6), 0.27))
    e["munitions"] = melanger(clic_metallique(2000, 0.035), decaler(clic_metallique(2600, 0.03, 0.9), 0.09),
                              decaler(coup_sourd(220, 0.03, 1200), 0.09))
    battement = melanger(coup_sourd(55, 0.07, 160), decaler(gain(coup_sourd(50, 0.08, 140), 0.8), 0.16))
    e["coeur_perdu"] = reverb(melanger(battement, decaler(gain(battement, 0.6), 0.55)), piece=0.7, humide=0.3, queue=0.4)
    e["reapparition"] = reverb(melanger(
        enveloppe(passe_bas_glissant(bruit(0.7), 300, 4000), 0.5, 0.08),
        enveloppe(sinus(80, 160, 0.7, 0.5), 0.4, 0.1)), piece=1.2, humide=0.35, queue=0.4)
    e["victoire"] = fanfare([(62, 0.0, 0.18), (62, 0.2, 0.18), (62, 0.4, 0.18), (67, 0.6, 1.1)], roulement=True)
    e["game_over"] = fanfare([(55, 0.0, 0.5), (53, 0.55, 0.5), (50, 1.1, 1.3)], roulement=False, grave=True)
    e["menu_navigation"] = gain(clic_metallique(3000, 0.012), 0.5)
    e["menu_validation"] = melanger(clic_metallique(1800, 0.02), coup_sourd(260, 0.03, 1500))
    papier = [x * random.choice((0.2, 1.0, 0.5)) for x in passe_bande(bruit(0.25), 800, 5000)]
    e["carte"] = gain(enveloppe(papier, 0.01, 0.07, 0.05), 0.8)
    e["mort_joueur"] = mort_joueur()
    return e


def mort_joueur():
    """Mort du joueur : impact lourd, corps et équipement qui tombent, sifflement d'oreilles.
    Tirage aléatoire isolé : ajouter ce son ne modifie pas les autres fichiers."""
    etat = random.getstate()
    random.seed(1918)
    impact = melanger(coup_sourd(95, 0.16, 400), gain(claquement(0.01, 2000), 0.5))
    chute_corps = melanger(coup_sourd(60, 0.2, 220),
                           *[decaler(clic_metallique(random.uniform(1200, 2800), 0.025, 0.3), random.uniform(0.0, 0.15))
                             for _ in range(6)])
    acouphene = enveloppe(sinus(3900, 3700, 2.2, 0.12), 0.25, 0.7)
    son = reverb(melanger(impact, decaler(chute_corps, 0.35), decaler(acouphene, 0.1)),
                 piece=0.9, humide=0.25, queue=0.5)
    random.setstate(etat)
    return son


def note(midi):
    return 440.0 * 2 ** ((midi - 69) / 12)


def cuivre(midi, duree, volume=1.0):
    """Cuivre : deux dents de scie désaccordées, filtrées, avec attaque douce."""
    s = scie(note(midi), duree, volume, 0.004)
    s = melanger(s, scie(note(midi - 12), duree, volume * 0.5, 0.003))
    return enveloppe(passe_bas(s, 1600), 0.04, duree * 0.6, duree * 0.4)


def caisse_claire(duree=0.12, volume=1.0):
    return gain(melanger(enveloppe(passe_bande(bruit(duree * 2), 1200, 7000), 0.001, duree / 3),
                         enveloppe(sinus(220, 160, duree, 0.5), 0.001, duree / 4)), volume)


def timbale(freq=70, duree=0.6, volume=1.0):
    return gain(melanger(enveloppe(sinus(freq * 1.3, freq, duree, 1.0), 0.003, duree / 3),
                         enveloppe(passe_bas(bruit(duree), 300), 0.002, 0.05)), volume)


def fanfare(notes, roulement=True, grave=False):
    total = max(d + t for _, d, t in notes) + 0.3
    pistes = [silence(total)]
    for midi, debut, duree in notes:
        accord = melanger(cuivre(midi, duree), gain(cuivre(midi + (3 if grave else 7), duree), 0.6))
        pistes.append(decaler(accord, debut))
    if roulement:
        roul = melanger(*[decaler(caisse_claire(0.06, 0.25 + 0.4 * k / 12), k * 0.045) for k in range(13)])
        pistes.append(roul)
    else:
        pistes.extend(decaler(timbale(55, 0.9, 0.9), d) for _, d, _t in notes)
    return reverb(melanger(*pistes), piece=1.4, humide=0.3, queue=0.8)


# --- Musiques ----------------------------------------------------------------

def musique_action(tempo, mesures, accords, intensite=1.0, avec_percussions=True):
    """Piste d'action : percussions graves (toms/timbales), caisse claire militaire,
    ostinato de cordes en croches et cuivres sur les changements d'accord."""
    temps = 60.0 / tempo
    total = n_ech(mesures * 4 * temps)
    sortie = [0.0] * total

    def poser(son, debut):
        i0 = n_ech(debut)
        for i, x in enumerate(son):
            if i0 + i < total:
                sortie[i0 + i] += x

    # Les sons répétés sont synthétisés une fois, puis posés.
    tom_grave = timbale(55, 0.5, 0.9)
    tom_medium = timbale(80, 0.35, 0.6)
    caisse = caisse_claire(0.1, 0.35)
    cache_cordes = {}

    for m in range(mesures):
        fond = accords[m % len(accords)]
        debut = m * 4 * temps
        if avec_percussions:
            # Rythme « marche » : grave sur 1 et 3, medium en syncope, caisse claire sur 2 et 4.
            for pos in (0, 2, 2.5):
                poser(tom_grave, debut + pos * temps)
            for pos in (1.5, 3.5):
                poser(tom_medium, debut + pos * temps)
            for pos in (1, 3):
                poser(caisse, debut + pos * temps)
            if m % 4 == 3:  # roulement de fin de phrase
                for k in range(8):
                    poser(gain(caisse_claire(0.06, 0.25), 0.4 + 0.08 * k), debut + 3 * temps + k * temps / 8)
        # Ostinato de cordes graves : croches sur la fondamentale et la quinte.
        for k in range(8):
            h = fond - 12 + (7 if k % 4 == 3 else 0)
            if h not in cache_cordes:
                corde = melanger(scie(note(h), temps * 0.5, 0.35, 0.006), scie(note(h + 12), temps * 0.5, 0.15, 0.004))
                cache_cordes[h] = enveloppe(passe_bas(corde, 900), 0.008, temps * 0.25)
            poser(gain(cache_cordes[h], intensite), debut + k * temps / 2)
        # Cuivres : accord tenu au début de chaque mesure paire.
        if m % 2 == 0:
            accord = melanger(cuivre(fond, temps * 3.5, 0.22), cuivre(fond + 3, temps * 3.5, 0.16),
                              cuivre(fond + 7, temps * 3.5, 0.16))
            poser(gain(accord, intensite), debut)
    return reverb(sortie, piece=1.5, amortissement=0.45, humide=0.22, queue=0.0)


def musiques():
    m = {}
    # Niveau : action tendue, ré mineur (Rém - Si♭ - Fa - Do).
    m["niveau_1"] = musique_action(104, 16, [62, 58, 65, 60], intensite=1.0)
    # Menu : même couleur, plus lent et retenu, sans caisse claire appuyée.
    m["menu"] = musique_action(76, 8, [62, 58, 57, 62], intensite=0.7, avec_percussions=True)
    return m


if __name__ == "__main__":
    print("Effets :")
    for nom, son in effets().items():
        ecrire(RACINE / "effets" / f"{nom}.wav", son)
    print("Musiques :")
    for nom, son in musiques().items():
        ecrire(RACINE / "musique" / f"{nom}.wav", son, crete=0.8)
