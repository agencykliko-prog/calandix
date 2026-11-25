# SPEC — Calandix, « La fête d'Awa » (30 s, 4:5)

GOAL:    à la fin, le spectateur a vu une vraie fête s'organiser de bout en bout dans Calandix
         (budget → invités → prestataires → devis → signature → paiement Wave) et veut rejoindre
         l'accès anticipé sur calandix.com.
OUTPUT:  HyperFrames, 1080 x 1350, rendu 60 fps ; livraison 1080x1350 et 2160x2700.
TIME:    30 s x 60 = 1800 images. Musique ~120-125 BPM : un temps ≈ 0,48 s, une mesure ≈ 1,92 s.
         Chaque plan dure une mesure (1,92 s) ou une mesure et quart (2,40 s) ; coupes sur le temps.

LOOK:    deux mondes et une scène de clôture.
         - Monde « produit » : fond crème #F7F5F2 avec un grand halo lavande #EAE7F3 (dégradé radial,
           72 % de la largeur, centré à 62 % de la hauteur) ; ink #1A0637.
         - Monde « marque » : aplat violet #4D39E2 (accroche, paiement, fin), texte blanc,
           mots manuscrits en mangue #FFC233.
         - Accent corail #E01928 : uniquement sur « Paiement confirmé » et le bouton final.
         - Titres : Red Hat Display 800, 72 px, interligne 1,02, approche -2,5 % ; mot accent en
           Satisfy 400 à 1,16 em. Sous-titres Red Hat Display 700, 32 px. Une ligne ≤ 6 mots.
         - Matière : le vrai téléphone (assets/img/frame.webp, 560 px de large) qui porte le vrai
           écran ; à côté, une plaque de verre (blanc 62 %, flou d'arrière-plan 22 px, bord 1,5 px
           blanc 80 %, rayon 34 px) qui porte la découpe réelle de l'élément en action à 1,5–1,9×.
           Reflet : une bande blanche à 10 % qui balaie la plaque en diagonale à son arrivée.
         - Ombre : 0 40px 80px -28px rgba(26,6,55,.38) sur téléphone et plaques ; contact 0 8 16 -8 .25.
OBJECTS: le téléphone (cadre réel, encoche, écran réel), la plaque de verre (découpe réelle de l'UI),
         l'ordinateur portable (écran réel 70-desk-home, châssis gris anthracite, charnière),
         les bulles de discussion de groupe de l'accroche (anonymes, sans marque), le curseur-doigt
         (cercle blanc 44 px, bord ink 3 px) qui touche ce qui déclenche le plan suivant.
MOTION:  entrée = expo.out 0,55 s ; déplacement = power3.inOut 0,5 s ; sortie = power2.in 0,3 s ;
         caméra = sine.inOut, push de 1,00 → 1,06 sur la durée du plan ; plaque = ressort
         (back.out(1.4)) 0,5 s, décalée de 0,12 s après le téléphone ; titres : mots qui montent
         derrière un masque (yPercent 105 → 0, 0,5 s, décalage 0,06 s), puis immobiles.
         Transitions (4 sortes) : l'élément touché devient le plan suivant (zoom à travers),
         balayage latéral du téléphone (le téléphone glisse et l'écran change), coupe sèche sur
         le temps, montée d'aplat violet (paiement et fin).

SHOTS:
 01 0,00–2,40  Accroche (violet) : 9 bulles de groupe s'empilent vite sur un téléphone flou ;
               « 247 messages » / « Zéro *décision* ». Lit : titre 0,3–2,3. Son : pings serrés.
               → les bulles s'aspirent dans une carte blanche.
 02 2,40–4,32  Création (60-new) : la carte devient l'écran « Que célébrez-vous ? » ; plaque
               « Mariages & unions » ; le doigt la touche. Titre « Tout *commence* ici ». Son : tap.
 03 4,32–6,24  Événement (61-event) : « Mariage Awa & Kouassi », plaque J-42 / 71 %.
               Titre « Votre fête, à un *seul* endroit ». Son : whoosh doux.
 04 6,24–8,64  Budget (62-budget) : plaque 12 500 000 FCFA, la barre se remplit.
               Titre « Chaque franc a *sa place* ». Son : tic de compteur.
 05 8,64–10,56 Invités (63-invites) : plaque « 162 confirmés sur 250 ».
               Titre « Les invités répondent *en ligne* ». Son : 3 petites notifications.
 06 10,56–12,48 Planning (64-taches) : plaque « 24 sur 37 terminées · J-42 ».
               Titre « Chaque étape *planifiée* ». Son : coche.
 07 12,48–14,40 Marketplace (66-explorer) : plaque « Espace Latrille Events ».
               Titre « Les bons *prestataires* ». Son : swipe.
 08 14,40–16,80 Devis (32-compare) : plaque « Analyse Calandix ».
               Titre « Comparez les *devis* ». Son : tap.
 09 16,80–18,72 Signature (41b-signed) : plaque signature + case cochée.
               Titre « Signez, la date est *bloquée* ». Son : stylo.
 10 18,72–21,12 Paiement (46-paid, monde violet) : plaque « Paiement confirmé · Wave », logos
               Wave, Orange Money, MoMo, Moov. Titre « Payez en *Mobile Money* ». Son : ding.
               C'est le moment fort (payoff).
 11 21,12–23,04 Messagerie (69-thread) : plaque des bulles avec le traiteur.
               Titre « Vos prestataires, en *direct* ». Son : envoi de message.
 12 23,04–24,96 Réservation (47-booking-paid) : plaque « Réservation confirmée ».
               Titre « Tout est prêt pour le *jour J* ». Son : accord.
 13 24,96–27,36 Multi-écrans : ordinateur (70-desk-home) + téléphone (01-home), même compte.
               Titre « Sur mobile et *ordinateur* » ; sous-titre « Bientôt sur iOS et Android ·
               déjà sur le web ». Son : swoosh stéréo.
 14 27,36–30,00 Fin (violet) : la marque arrive, le mot-symbole s'écrit, « calandix.com »,
               bouton corail « Rejoindre l'accès anticipé » tenu 1,5 s. Son : impact final.

BANNED:  vide sombre avec petits éléments flottants ; lueurs, particules, halos néon ; logo en coin ;
         trois cartes en ligne ; UI inclinée en 3D ; texte qui bouge pendant la lecture ;
         tableau de bord inventé ; « disponible sur iOS/Android » ; badges App Store / Google Play ;
         « en quelques secondes », « révolutionner », « sans effort ».
         (Le verre et le violet sont permis : ce sont la demande et la couleur de la marque.)
QA:      1,2 s (titre accroche lisible) · 3,4 · 5,2 · 7,5 · 9,6 · 11,5 · 13,4 · 15,6 · 17,8 ·
         19,9 (payoff, corail) · 22,0 · 24,0 · 26,2 (mention « Bientôt sur iOS et Android ») ·
         29,0 (fin complète, bouton lisible). Texte ≥ 28 px, rien hors de la zone 90 %.
