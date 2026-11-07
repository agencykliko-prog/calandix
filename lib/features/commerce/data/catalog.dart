import 'package:flutter/widgets.dart';

import '../../../ui/theme/app_icons.dart';
import '../../../core/models/models.dart';
import '../domain/commerce_models.dart';

/// Catalogue de démonstration — prestataires, produits et offres fictifs.
abstract final class Catalog {
  static const _v = 'assets/images/v';

  static const vendors = <Vendor>[
    // Lieux
    Vendor(
      id: 'latrille',
      name: 'Espace Latrille Events',
      category: VendorCategory.venue,
      tagline: 'Salle de réception · 500 places',
      description:
          'Grande salle climatisée au cœur de Cocody, parking 150 places, '
          'cuisine traiteur équipée et jardin pour les photos.',
      priceFrom: 2500000,
      image: '$_v/venue_2.jpg',
      zone: 'Cocody',
      rating: 4.9,
      reviews: 212,
      sponsor: Sponsor.ofTheMonth,
      responseTime: '30 min',
      packages: [
        VendorPackage(
          'Soirée',
          2500000,
          'Salle 18 h – 3 h, mobilier inclus',
          '150 invités minimum · acompte de 40 %',
        ),
        VendorPackage(
          'Journée',
          3800000,
          'Salle et jardin 10 h – 3 h',
          'Réservation au moins 60 jours avant',
        ),
        VendorPackage(
          'Week-end',
          6200000,
          'Dot + réception, 2 jours',
          'Caution de 500 000 FCFA restituée après l’état des lieux',
        ),
      ],
    ),
    Vendor(
      id: 'domaine-lagune',
      name: 'Domaine de la Lagune',
      category: VendorCategory.venue,
      tagline: 'Domaine en plein air · 300 places',
      description:
          'Pelouse face à la lagune Ébrié, idéal pour cérémonies laïques et '
          'cocktails au coucher du soleil.',
      priceFrom: 1800000,
      image: '$_v/venue_1.jpg',
      zone: 'Bingerville',
      rating: 4.7,
      reviews: 96,
      available: false,
      nextAvailable: 'Libre à partir du 14 déc.',
      packages: [
        VendorPackage('Cérémonie', 1800000, 'Pelouse et arche, 4 h'),
        VendorPackage('Journée complète', 2900000, 'Cérémonie et réception'),
      ],
    ),
    Vendor(
      id: 'villa-azur',
      name: 'Villa Azur Assinie',
      category: VendorCategory.venue,
      tagline: 'Villa avec piscine · 80 personnes',
      description:
          'Villa pieds dans l’eau à Assinie, 6 chambres, piscine à débordement. '
          'Parfaite pour EVJF, anniversaires et pool parties.',
      priceFrom: 650000,
      unit: 'nuit',
      image: '$_v/venue_3.jpg',
      zone: 'Assinie',
      rating: 4.8,
      reviews: 141,
      sponsor: Sponsor.featured,
      packages: [
        VendorPackage('Nuit', 650000, '6 chambres, piscine, ménage inclus'),
        VendorPackage('Week-end', 1200000, '2 nuits, chef sur demande'),
      ],
    ),
    // Décoration
    Vendor(
      id: 'ines-deco',
      name: 'Maison Inès Déco',
      category: VendorCategory.decor,
      tagline: 'Fleurs & scénographie',
      description:
          'Compositions florales fraîches, arches, centres de table et '
          'scénographie sur mesure. Moodboard offert.',
      priceFrom: 450000,
      image: '$_v/decor_1.jpg',
      zone: 'Riviera',
      rating: 4.8,
      reviews: 178,
      sponsor: Sponsor.recommended,
      packages: [
        VendorPackage(
          'Essentiel',
          450000,
          'Arche + 10 centres de table',
          'Installation 3 h avant · déplacement hors Abidjan en sus',
        ),
        VendorPackage('Signature', 1200000, 'Scénographie complète'),
      ],
    ),
    Vendor(
      id: 'ballon-studio',
      name: 'Ballon Studio CI',
      category: VendorCategory.decor,
      tagline: 'Arches & installations ballons',
      description:
          'Arches organiques, murs de ballons et photocalls pour anniversaires, '
          'baby showers et lancements.',
      priceFrom: 85000,
      image: '$_v/decor_2.jpg',
      zone: 'Marcory',
      rating: 4.6,
      reviews: 88,
      packages: [
        VendorPackage('Arche', 85000, 'Arche organique 3 m'),
        VendorPackage('Photocall', 160000, 'Mur + arche + néon'),
      ],
    ),
    Vendor(
      id: 'table-lumiere',
      name: 'Table & Lumière',
      category: VendorCategory.decor,
      tagline: 'Art de la table & bougies',
      description:
          'Nappage, vaisselle dorée, bougies et chemins de table pour des '
          'dîners élégants.',
      priceFrom: 180000,
      image: '$_v/decor_3.jpg',
      zone: 'Plateau',
      rating: 4.7,
      reviews: 54,
      verified: false,
    ),
    // Restauration
    Vendor(
      id: 'saveurs',
      name: 'Saveurs d’Ivoire',
      category: VendorCategory.catering,
      tagline: 'Traiteur · cuisine ivoirienne & fusion',
      description:
          'Garba revisité, kedjenou, alloco, buffets froids et chauds. '
          'Service à table possible, dégustation offerte dès 100 couverts.',
      priceFrom: 13500,
      unit: 'pers.',
      image: '$_v/food_1.jpg',
      zone: 'Marcory',
      rating: 4.8,
      reviews: 264,
      sponsor: Sponsor.recommended,
      responseTime: '45 min',
      packages: [
        VendorPackage('Buffet', 13500, 'Par personne, 3 plats + dessert'),
        VendorPackage(
          'Service à table',
          19500,
          'Par personne, serveurs inclus',
        ),
      ],
    ),
    Vendor(
      id: 'tantie-aya',
      name: 'Chez Tantie Aya',
      category: VendorCategory.catering,
      tagline: 'Traiteur familial · grands groupes',
      description:
          'Riz gras, attiéké poisson, poulet braisé : la cuisine de maison '
          'pour 50 à 800 invités, livrée chaude.',
      priceFrom: 8500,
      unit: 'pers.',
      image: '$_v/food_3.jpg',
      zone: 'Yopougon',
      rating: 4.6,
      reviews: 131,
    ),
    Vendor(
      id: 'douce-heure',
      name: 'Douce Heure',
      category: VendorCategory.catering,
      tagline: 'Pâtisserie & wedding cakes',
      description:
          'Pièces montées, layer cakes, cupcakes et bars à desserts. '
          'Dégustation sur rendez-vous.',
      priceFrom: 60000,
      image: '$_v/food_2.jpg',
      zone: 'Deux-Plateaux',
      rating: 4.9,
      reviews: 97,
    ),
    // Photo & vidéo
    Vendor(
      id: 'studio-lumiere',
      name: 'Studio Lumière',
      category: VendorCategory.photo,
      tagline: 'Photographe mariage & portrait',
      description:
          'Reportage complet de la préparation à la soirée, galerie privée '
          'en ligne sous 3 semaines, album imprimé en option.',
      priceFrom: 450000,
      image: '$_v/photo_1.jpg',
      zone: 'Cocody',
      rating: 4.9,
      reviews: 156,
      sponsor: Sponsor.recommended,
      packages: [
        VendorPackage('Reportage', 450000, '8 h, 400 photos retouchées'),
        VendorPackage('Photo + album', 650000, 'Reportage et album 30×30'),
      ],
    ),
    Vendor(
      id: 'motion-films',
      name: 'Motion Films CI',
      category: VendorCategory.photo,
      tagline: 'Vidéaste & drone',
      description:
          'Film de mariage cinématique, teaser 1 min pour les réseaux et '
          'prises de vue par drone.',
      priceFrom: 550000,
      image: '$_v/photo_2.jpg',
      zone: 'Plateau',
      rating: 4.7,
      reviews: 72,
      available: false,
      nextAvailable: 'Libre à partir du 20 nov.',
    ),
    // Animation
    Vendor(
      id: 'lagune-sound',
      name: 'Lagune Sound',
      category: VendorCategory.music,
      tagline: 'DJ & sonorisation',
      description:
          'DJ ambianceur coupé-décalé, afrobeats et classiques, sono et '
          'lumières incluses jusqu’à 400 invités.',
      priceFrom: 300000,
      image: '$_v/music_1.jpg',
      zone: 'Plateau',
      rating: 4.6,
      reviews: 119,
      sponsor: Sponsor.result,
    ),
    Vendor(
      id: 'groove-band',
      name: 'Groove Live Band',
      category: VendorCategory.music,
      tagline: 'Orchestre live · 6 musiciens',
      description:
          'Orchestre pour cocktail et première danse, répertoire highlife, '
          'zouk, rumba et variétés.',
      priceFrom: 750000,
      image: '$_v/music_2.jpg',
      zone: 'Cocody',
      rating: 4.8,
      reviews: 61,
    ),
    // Location
    Vendor(
      id: 'location-prestige',
      name: 'Abidjan Location Prestige',
      category: VendorCategory.rental,
      tagline: 'Chaises, tables & vaisselle',
      description:
          'Chaises Chiavari, tables rondes, vaisselle et nappage. Livraison et '
          'installation incluses à Abidjan.',
      priceFrom: 2500,
      unit: 'chaise',
      image: '$_v/rental_1.jpg',
      zone: 'Koumassi',
      rating: 4.5,
      reviews: 83,
    ),
    Vendor(
      id: 'tentes-co',
      name: 'Tentes & Co',
      category: VendorCategory.rental,
      tagline: 'Chapiteaux & tentes',
      description:
          'Chapiteaux de 50 à 600 places, plancher, éclairage et '
          'climatisation mobile.',
      priceFrom: 350000,
      image: '$_v/rental_2.jpg',
      zone: 'Bingerville',
      rating: 4.6,
      reviews: 47,
    ),
    // Mode & beauté
    Vendor(
      id: 'glam-fatim',
      name: 'Glam by Fatim',
      category: VendorCategory.beauty,
      tagline: 'Maquillage & coiffure',
      description:
          'Mise en beauté de la mariée et du cortège, essai inclus, '
          'déplacement à domicile.',
      priceFrom: 120000,
      image: '$_v/beauty_1.jpg',
      zone: 'Cocody',
      rating: 4.9,
      reviews: 203,
      sponsor: Sponsor.result,
    ),
    Vendor(
      id: 'pagne-royal',
      name: 'Atelier Pagne Royal',
      category: VendorCategory.beauty,
      tagline: 'Couture & pagne du cortège',
      description:
          'Tenues sur mesure, pagne commun pour la famille et le cortège, '
          'gestion des tailles et de la distribution.',
      priceFrom: 25000,
      unit: 'tenue',
      image: '$_v/beauty_2.jpg',
      zone: 'Treichville',
      rating: 4.7,
      reviews: 112,
    ),
    // Papeterie
    Vendor(
      id: 'papeterie-kente',
      name: 'Papeterie Kente',
      category: VendorCategory.paper,
      tagline: 'Faire-part & papeterie',
      description:
          'Faire-part, menus, marque-places et plans de table assortis, '
          'impression locale en 5 jours.',
      priceFrom: 1200,
      unit: 'carte',
      image: '$_v/paper_1.jpg',
      zone: 'Plateau',
      rating: 4.7,
      reviews: 66,
    ),
    Vendor(
      id: 'merci-studio',
      name: 'Merci Studio',
      category: VendorCategory.paper,
      tagline: 'Cartes de remerciement & cadeaux',
      description:
          'Cartes de remerciement, étiquettes et cadeaux invités '
          'personnalisés.',
      priceFrom: 900,
      unit: 'carte',
      image: '$_v/paper_2.jpg',
      zone: 'Riviera',
      rating: 4.6,
      reviews: 38,
      verified: false,
    ),
    // Transport
    Vendor(
      id: 'prestige-limo',
      name: 'Prestige Limousine CI',
      category: VendorCategory.transport,
      tagline: 'Voitures de mariés',
      description:
          'Limousines et berlines décorées avec chauffeur en tenue, '
          'forfait demi-journée.',
      priceFrom: 250000,
      image: '$_v/transport_1.jpg',
      zone: 'Plateau',
      rating: 4.7,
      reviews: 58,
    ),
    Vendor(
      id: 'navette-express',
      name: 'Navette Express',
      category: VendorCategory.transport,
      tagline: 'Navettes invités · 30 à 70 places',
      description:
          'Cars climatisés pour transporter vos invités entre cérémonies, '
          'hôtel et réception.',
      priceFrom: 180000,
      unit: 'car',
      image: '$_v/transport_2.jpg',
      zone: 'Port-Bouët',
      rating: 4.5,
      reviews: 44,
    ),
    // Personnel
    Vendor(
      id: 'service-elegance',
      name: 'Service Élégance',
      category: VendorCategory.staff,
      tagline: 'Serveurs & hôtesses',
      description:
          'Équipes de service formées, hôtesses d’accueil et maîtres d’hôtel '
          'pour vos réceptions.',
      priceFrom: 25000,
      unit: 'serveur',
      image: '$_v/staff_1.jpg',
      zone: 'Cocody',
      rating: 4.6,
      reviews: 77,
    ),
    Vendor(
      id: 'barmen',
      name: 'Barmen d’Abidjan',
      category: VendorCategory.staff,
      tagline: 'Bar à cocktails mobile',
      description:
          'Bar mobile, mixologues et carte de cocktails avec ou sans alcool.',
      priceFrom: 220000,
      image: '$_v/staff_2.jpg',
      zone: 'Marcory',
      rating: 4.8,
      reviews: 52,
    ),
    // Organisation
    Vendor(
      id: 'atelier-celebration',
      name: 'Atelier Célébration',
      category: VendorCategory.planner,
      tagline: 'Wedding planner',
      description:
          'Organisation complète ou partielle, coordination du jour J, '
          'gestion des familles et des prestataires.',
      priceFrom: 800000,
      image: '$_v/planner_1.jpg',
      zone: 'Cocody',
      rating: 4.9,
      reviews: 89,
    ),
    Vendor(
      id: 'jour-j',
      name: 'Jour J Conciergerie',
      category: VendorCategory.planner,
      tagline: 'Coordination du jour J',
      description:
          'Une coordinatrice dédiée le jour J pour que vous profitiez, '
          'du réveil au dernier invité.',
      priceFrom: 250000,
      image: '$_v/planner_2.jpg',
      zone: 'Plateau',
      rating: 4.7,
      reviews: 41,
    ),
    // Activités
    Vendor(
      id: 'assinie-boat',
      name: 'Assinie Boat Tours',
      category: VendorCategory.activity,
      tagline: 'Sorties en bateau',
      description:
          'Croisières privées sur la lagune, déjeuner à bord et baignade '
          'sur une île.',
      priceFrom: 35000,
      unit: 'pers.',
      image: '$_v/activity_1.jpg',
      zone: 'Assinie',
      rating: 4.8,
      reviews: 134,
    ),
    Vendor(
      id: 'spa-zen',
      name: 'Spa Ivoire Zen',
      category: VendorCategory.activity,
      tagline: 'Spa & bien-être de groupe',
      description:
          'Journées spa privatisées pour EVJF et équipes : massages, hammam, '
          'brunch.',
      priceFrom: 45000,
      unit: 'pers.',
      image: '$_v/activity_2.jpg',
      zone: 'Cocody',
      rating: 4.7,
      reviews: 69,
    ),
    // ── Prestataires ajoutés (photos Unsplash) ─────────────────────────
    Vendor(
      id: 'salle-ivoire',
      name: 'Salle Ivoire Prestige',
      category: VendorCategory.venue,
      tagline: 'Salle de gala · 700 places',
      description: 'Grande salle climatisée au Plateau, scène, régie son et parking sécurisé.',
      priceFrom: 3200000,
      image: 'https://images.unsplash.com/photo-1783314867628-220ab03cac99?w=900&q=70&auto=format&fit=crop',
      zone: 'Plateau',
      rating: 4.8,
      reviews: 154,
      packages: [
        VendorPackage('Soirée', 3200000, 'Salle 18 h – 4 h, mobilier inclus'),
        VendorPackage('Gala', 4600000, 'Salle, scène et loges'),
      ],
    ),
    Vendor(
      id: 'jardin-palmiers',
      name: 'Jardin des Palmiers',
      category: VendorCategory.venue,
      tagline: 'Jardin privatisable · 250 places',
      description: 'Jardin arboré à la Riviera, pergola et éclairage d’ambiance pour les cérémonies du soir.',
      priceFrom: 1400000,
      image: 'https://images.unsplash.com/photo-1775918427144-51f0bf53f8c4?w=900&q=70&auto=format&fit=crop',
      zone: 'Riviera 3',
      rating: 4.7,
      reviews: 88,
      packages: [
        VendorPackage('Cérémonie', 1400000, 'Jardin et pergola, 5 h'),
        VendorPackage('Journée', 2300000, 'Cérémonie et cocktail'),
      ],
    ),
    Vendor(
      id: 'rooftop-plateau',
      name: 'Rooftop Le Toit',
      category: VendorCategory.venue,
      tagline: 'Rooftop vue lagune · 120 places',
      description: 'Terrasse panoramique sur la lagune, bar intégré, idéale pour anniversaires et afterworks.',
      priceFrom: 900000,
      image: 'https://images.unsplash.com/photo-1783314863884-be035ed5ed5c?w=900&q=70&auto=format&fit=crop',
      zone: 'Plateau',
      rating: 4.9,
      reviews: 203,
      packages: [
        VendorPackage('Soirée', 900000, '19 h – 2 h, bar et DJ booth'),
        VendorPackage('Privatisation', 1500000, 'Journée complète'),
      ],
    ),
    Vendor(
      id: 'fleurs-akwaba',
      name: 'Fleurs d’Akwaba',
      category: VendorCategory.decor,
      tagline: 'Fleuriste événementiel',
      description: 'Arches florales, centres de table et bouquets de mariée, fleurs locales et importées.',
      priceFrom: 380000,
      image: 'https://images.unsplash.com/photo-1644135129271-e80c8c673511?w=900&q=70&auto=format&fit=crop',
      zone: 'Cocody',
      rating: 4.8,
      reviews: 117,
      packages: [
        VendorPackage('Essentiel', 380000, 'Arche et 10 centres de table'),
        VendorPackage('Signature', 850000, 'Scénographie florale complète'),
      ],
    ),
    Vendor(
      id: 'deco-pagne',
      name: 'Déco Pagne & Or',
      category: VendorCategory.decor,
      tagline: 'Décoration wax et dorures',
      description: 'Scénographies inspirées du pagne ivoirien, parfait pour les dots et mariages coutumiers.',
      priceFrom: 520000,
      image: 'https://images.unsplash.com/photo-1737236118342-d4c175bf0814?w=900&q=70&auto=format&fit=crop',
      zone: 'Treichville',
      rating: 4.7,
      reviews: 76,
      packages: [
        VendorPackage('Dot', 520000, 'Salon traditionnel et tentures'),
        VendorPackage('Mariage', 1100000, 'Salle complète, tables et scène'),
      ],
    ),
    Vendor(
      id: 'lumiere-events',
      name: 'Lumière & Ambiance',
      category: VendorCategory.decor,
      tagline: 'Éclairage et mise en lumière',
      description: 'Guirlandes, lustres, jeux de lumière et bougies pour sublimer chaque espace.',
      priceFrom: 250000,
      image: 'https://images.unsplash.com/photo-1613067532295-b4f1760616cd?w=900&q=70&auto=format&fit=crop',
      zone: 'Marcory',
      rating: 4.6,
      reviews: 58,
      packages: [
        VendorPackage('Ambiance', 250000, 'Guirlandes et bougies'),
        VendorPackage('Grand soir', 640000, 'Lustres, projecteurs, régie'),
      ],
    ),
    Vendor(
      id: 'chez-mamie-adjoua',
      name: 'Chez Mamie Adjoua',
      category: VendorCategory.catering,
      tagline: 'Cuisine ivoirienne traditionnelle',
      description: 'Attiéké, garba, kedjenou et alloco préparés comme à la maison, service à table inclus.',
      priceFrom: 9500,
      unit: 'pers.',
      image: 'https://images.unsplash.com/photo-1722477936580-84aa10762b0b?w=900&q=70&auto=format&fit=crop',
      zone: 'Yopougon',
      rating: 4.9,
      reviews: 268,
      packages: [
        VendorPackage('Buffet', 9500, 'Trois plats ivoiriens et boissons'),
        VendorPackage('Prestige', 16000, 'Cinq plats, dessert, service'),
      ],
    ),
    Vendor(
      id: 'grill-lagune',
      name: 'Grill de la Lagune',
      category: VendorCategory.catering,
      tagline: 'Grillades et braise',
      description: 'Poisson braisé, poulet piqué et brochettes cuits sur place devant vos invités.',
      priceFrom: 12000,
      unit: 'pers.',
      image: 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=900&q=70&auto=format&fit=crop',
      zone: 'Koumassi',
      rating: 4.7,
      reviews: 132,
      packages: [
        VendorPackage('Barbecue', 12000, 'Grillades et accompagnements'),
        VendorPackage('Festin', 18500, 'Grillades, buffet froid, dessert'),
      ],
    ),
    Vendor(
      id: 'patisserie-belle',
      name: 'Pâtisserie La Belle',
      category: VendorCategory.catering,
      tagline: 'Wedding cakes et douceurs',
      description: 'Pièces montées, wedding cakes et candy bars sur mesure, livrés et installés.',
      priceFrom: 180000,
      image: 'https://images.unsplash.com/photo-1535254973040-607b474cb50d?w=900&q=70&auto=format&fit=crop',
      zone: 'Deux-Plateaux',
      rating: 4.8,
      reviews: 97,
      packages: [
        VendorPackage('Gâteau', 180000, 'Wedding cake 3 étages, 80 parts'),
        VendorPackage('Candy bar', 420000, 'Gâteau, mignardises, présentation'),
      ],
    ),
    Vendor(
      id: 'oeil-dor',
      name: 'L’Œil d’Or Photo',
      category: VendorCategory.photo,
      tagline: 'Photographe de mariage',
      description:
          'Reportage complet du jour J, retouches soignées et album imprimé.',
      priceFrom: 450000,
      image: 'https://images.unsplash.com/photo-1758810409996-583f3bad7d51?w=900&q=70&auto=format&fit=crop',
      zone: 'Cocody',
      rating: 4.9,
      reviews: 186,
      packages: [
        VendorPackage('Reportage', 450000, '8 h, 400 photos retouchées'),
        VendorPackage('Album', 690000, 'Reportage et album 40 pages'),
      ],
    ),
    Vendor(
      id: 'cine-abidjan',
      name: 'Ciné Abidjan Studio',
      category: VendorCategory.photo,
      tagline: 'Film de mariage et drone',
      description: 'Films cinématiques, prises de vue par drone et teaser livré sous 72 h.',
      priceFrom: 600000,
      image: 'https://images.unsplash.com/photo-1629756048377-09540f52caa1?w=900&q=70&auto=format&fit=crop',
      zone: 'Angré',
      rating: 4.8,
      reviews: 91,
      packages: [
        VendorPackage('Film', 600000, 'Film de 10 min et teaser'),
        VendorPackage('Premium', 980000, 'Film, drone, photos'),
      ],
    ),
    Vendor(
      id: 'flash-souvenirs',
      name: 'Flash Souvenirs',
      category: VendorCategory.photo,
      tagline: 'Photobooth et instantanés',
      description: 'Borne photo avec impressions illimitées et accessoires, animée par notre équipe.',
      priceFrom: 220000,
      image: 'https://images.unsplash.com/photo-1600164913117-2125c1f60b01?w=900&q=70&auto=format&fit=crop',
      zone: 'Marcory',
      rating: 4.6,
      reviews: 64,
      packages: [
        VendorPackage('Borne', 220000, '4 h, impressions illimitées'),
        VendorPackage('Borne + album', 320000, 'Borne et livre d’or photo'),
      ],
    ),
    Vendor(
      id: 'dj-kader',
      name: 'DJ Kader Mix',
      category: VendorCategory.music,
      tagline: 'DJ mariage et soirées',
      description: 'Coupé-décalé, afro, zouk et classiques : le DJ qui fait danser toutes les générations.',
      priceFrom: 300000,
      image: 'https://images.unsplash.com/photo-1541126274323-dbac58d14741?w=900&q=70&auto=format&fit=crop',
      zone: 'Yopougon',
      rating: 4.8,
      reviews: 159,
      packages: [
        VendorPackage('Soirée', 300000, '6 h, son et lumière'),
        VendorPackage('Mariage', 520000, 'Cérémonie, cocktail, soirée'),
      ],
    ),
    Vendor(
      id: 'orchestre-akan',
      name: 'Orchestre Akan',
      category: VendorCategory.music,
      tagline: 'Orchestre live et tam-tams',
      description: 'Musique traditionnelle et moderne en live, idéale pour les dots et les entrées des mariés.',
      priceFrom: 650000,
      image: 'https://images.unsplash.com/photo-1762674541314-dc97fde0006c?w=900&q=70&auto=format&fit=crop',
      zone: 'Bingerville',
      rating: 4.7,
      reviews: 72,
      packages: [
        VendorPackage('Live', 650000, '3 h, 6 musiciens'),
        VendorPackage('Complet', 1100000, 'Live, tam-tams, DJ relais'),
      ],
    ),
    Vendor(
      id: 'mc-joyce',
      name: 'MC Joyce Animation',
      category: VendorCategory.music,
      tagline: 'Maître de cérémonie',
      description: 'Animation bilingue, jeux et déroulé maîtrisé pour que la fête reste fluide.',
      priceFrom: 200000,
      image: 'https://images.unsplash.com/photo-1496337589254-7e19d01cec44?w=900&q=70&auto=format&fit=crop',
      zone: 'Cocody',
      rating: 4.9,
      reviews: 110,
      packages: [
        VendorPackage('Animation', 200000, 'Soirée complète'),
        VendorPackage('Jour J', 350000, 'Cérémonie et soirée'),
      ],
    ),
    Vendor(
      id: 'mobilier-chic',
      name: 'Mobilier Chic CI',
      category: VendorCategory.rental,
      tagline: 'Location de mobilier',
      description: 'Chaises Napoléon, tables rondes, salons lounge et nappage livrés et installés.',
      priceFrom: 2500,
      unit: 'pers.',
      image: 'https://images.unsplash.com/photo-1620735692151-26a7e0748429?w=900&q=70&auto=format&fit=crop',
      zone: 'Marcory',
      rating: 4.7,
      reviews: 88,
      packages: [
        VendorPackage('Essentiel', 2500, 'Chaise, table, nappe'),
        VendorPackage('Lounge', 4500, 'Mobilier et coin salon'),
      ],
    ),
    Vendor(
      id: 'sono-pro',
      name: 'Sono Pro Location',
      category: VendorCategory.rental,
      tagline: 'Son, lumière et écrans',
      description: 'Location de sonorisation, écrans LED et scène avec technicien sur place.',
      priceFrom: 350000,
      image: 'https://images.unsplash.com/photo-1759124650342-b283fa8461fa?w=900&q=70&auto=format&fit=crop',
      zone: 'Treichville',
      rating: 4.6,
      reviews: 54,
      packages: [
        VendorPackage('Sono', 350000, 'Sonorisation et micros'),
        VendorPackage('Scène', 900000, 'Scène, écran LED, technicien'),
      ],
    ),
    Vendor(
      id: 'vaisselle-royale',
      name: 'Vaisselle Royale',
      category: VendorCategory.rental,
      tagline: 'Vaisselle et verrerie',
      description:
          'Assiettes, couverts dorés et verrerie en cristal, lavage inclus.',
      priceFrom: 1500,
      unit: 'pers.',
      image: 'https://images.unsplash.com/photo-1766719628920-854680a92c22?w=900&q=70&auto=format&fit=crop',
      zone: 'Riviera 2',
      rating: 4.8,
      reviews: 73,
      packages: [
        VendorPackage('Classique', 1500, 'Assiettes, couverts, verres'),
        VendorPackage('Dorée', 2600, 'Couverts dorés, cristal'),
      ],
    ),
    Vendor(
      id: 'makeup-awa',
      name: 'Awa Beauty Makeup',
      category: VendorCategory.beauty,
      tagline: 'Maquillage mariée',
      description: 'Maquillage longue tenue adapté aux peaux noires, essai inclus avant le jour J.',
      priceFrom: 120000,
      image: 'https://images.unsplash.com/photo-1618999114008-fbf937170cdb?w=900&q=70&auto=format&fit=crop',
      zone: 'Cocody',
      rating: 4.9,
      reviews: 201,
      packages: [
        VendorPackage('Mariée', 120000, 'Essai et maquillage du jour J'),
        VendorPackage('Cortège', 260000, 'Mariée et 4 demoiselles'),
      ],
    ),
    Vendor(
      id: 'tresses-queen',
      name: 'Tresses Queen',
      category: VendorCategory.beauty,
      tagline: 'Coiffure et tresses',
      description:
          'Coiffures de mariée, tresses et perruques posées à domicile.',
      priceFrom: 80000,
      image: 'https://images.unsplash.com/photo-1726276262267-ebb01cfa0982?w=900&q=70&auto=format&fit=crop',
      zone: 'Abobo',
      rating: 4.7,
      reviews: 98,
      packages: [
        VendorPackage('Coiffure', 80000, 'Coiffure mariée à domicile'),
        VendorPackage('Cortège', 190000, 'Mariée et 4 proches'),
      ],
    ),
    Vendor(
      id: 'atelier-bazin',
      name: 'Atelier Bazin Couture',
      category: VendorCategory.beauty,
      tagline: 'Tenues sur mesure',
      description: 'Bazin, pagne et robes de cérémonie cousus sur mesure, essayages inclus.',
      priceFrom: 150000,
      image: 'https://images.unsplash.com/photo-1786529745854-fb41cbaf5fa3?w=900&q=70&auto=format&fit=crop',
      zone: 'Adjamé',
      rating: 4.8,
      reviews: 121,
      packages: [
        VendorPackage('Tenue', 150000, 'Une tenue sur mesure'),
        VendorPackage('Couple', 320000, 'Tenues assorties des mariés'),
      ],
    ),
    Vendor(
      id: 'faire-part-chic',
      name: 'Faire-part Chic',
      category: VendorCategory.paper,
      tagline: 'Faire-part et papeterie',
      description: 'Faire-part imprimés, menus et plans de table assortis à votre thème.',
      priceFrom: 1200,
      unit: 'pièce',
      image: 'https://images.unsplash.com/photo-1633037773384-27d7ac0491e7?w=900&q=70&auto=format&fit=crop',
      zone: 'Plateau',
      rating: 4.7,
      reviews: 66,
      packages: [
        VendorPackage('Faire-part', 1200, 'Impression et enveloppe'),
        VendorPackage('Suite', 2500, 'Faire-part, menu, marque-place'),
      ],
    ),
    Vendor(
      id: 'calligraphie-ci',
      name: 'Calligraphie d’Ivoire',
      category: VendorCategory.paper,
      tagline: 'Calligraphie et signalétique',
      description: 'Panneaux de bienvenue, plans de table et noms calligraphiés à la main.',
      priceFrom: 90000,
      image: 'https://images.unsplash.com/photo-1732649124686-3bab54f79aa3?w=900&q=70&auto=format&fit=crop',
      zone: 'Cocody',
      rating: 4.9,
      reviews: 47,
      packages: [
        VendorPackage('Signalétique', 90000, 'Panneau et plan de table'),
        VendorPackage('Complète', 210000, 'Signalétique et marque-places'),
      ],
    ),
    Vendor(
      id: 'qr-invit',
      name: 'QR Invit',
      category: VendorCategory.paper,
      tagline: 'Invitations numériques',
      description: 'Faire-part animés et QR codes RSVP envoyés par WhatsApp.',
      priceFrom: 45000,
      image: 'https://images.unsplash.com/photo-1712313992209-93a2cc377ede?w=900&q=70&auto=format&fit=crop',
      zone: 'En ligne',
      rating: 4.6,
      reviews: 39,
      packages: [
        VendorPackage('Numérique', 45000, 'Faire-part animé et QR'),
        VendorPackage('Mixte', 120000, 'Numérique et imprimé'),
      ],
    ),
    Vendor(
      id: 'limo-ivoire',
      name: 'Limousines d’Ivoire',
      category: VendorCategory.transport,
      tagline: 'Voitures de mariage',
      description: 'Berlines et limousines décorées avec chauffeur en tenue.',
      priceFrom: 250000,
      image: 'https://images.unsplash.com/photo-1592514313074-794923c98162?w=900&q=70&auto=format&fit=crop',
      zone: 'Plateau',
      rating: 4.8,
      reviews: 83,
      packages: [
        VendorPackage('Berline', 250000, '4 h avec chauffeur'),
        VendorPackage('Limousine', 450000, '6 h, décoration incluse'),
      ],
    ),
    Vendor(
      id: 'vintage-cars',
      name: 'Vintage Cars CI',
      category: VendorCategory.transport,
      tagline: 'Voitures de collection',
      description: 'Cabriolets et voitures anciennes pour des entrées et photos inoubliables.',
      priceFrom: 380000,
      image: 'https://images.unsplash.com/photo-1777415923415-1792e87ae078?w=900&q=70&auto=format&fit=crop',
      zone: 'Grand-Bassam',
      rating: 4.9,
      reviews: 41,
      packages: [
        VendorPackage('Cabriolet', 380000, '4 h avec chauffeur'),
        VendorPackage('Cortège', 720000, 'Deux véhicules, 6 h'),
      ],
    ),
    Vendor(
      id: 'bus-fiesta',
      name: 'Bus Fiesta',
      category: VendorCategory.transport,
      tagline: 'Navettes invités',
      description: 'Minibus climatisés pour déplacer vos invités entre cérémonie et réception.',
      priceFrom: 150000,
      image: 'https://images.unsplash.com/photo-1655757457375-c1668c7bc0ad?w=900&q=70&auto=format&fit=crop',
      zone: 'Yopougon',
      rating: 4.6,
      reviews: 57,
      packages: [
        VendorPackage('Navette', 150000, 'Un minibus 30 places, 6 h'),
        VendorPackage('Flotte', 400000, 'Trois minibus, 8 h'),
      ],
    ),
    Vendor(
      id: 'hotesses-elite',
      name: 'Hôtesses Élite',
      category: VendorCategory.staff,
      tagline: 'Hôtesses et accueil',
      description:
          'Hôtesses bilingues pour l’accueil, le placement et le vestiaire.',
      priceFrom: 35000,
      unit: 'pers.',
      image: 'https://images.unsplash.com/photo-1719573019827-d06944a0c2be?w=900&q=70&auto=format&fit=crop',
      zone: 'Cocody',
      rating: 4.8,
      reviews: 92,
      packages: [
        VendorPackage('Accueil', 35000, 'Une hôtesse, 6 h'),
        VendorPackage('Équipe', 160000, 'Cinq hôtesses, 6 h'),
      ],
    ),
    Vendor(
      id: 'securite-plus',
      name: 'Sécurité Plus',
      category: VendorCategory.staff,
      tagline: 'Agents de sécurité',
      description: 'Agents formés pour le contrôle d’accès et la sécurité de vos invités.',
      priceFrom: 40000,
      unit: 'pers.',
      image: 'https://images.unsplash.com/photo-1786912029736-2d0862e394a6?w=900&q=70&auto=format&fit=crop',
      zone: 'Marcory',
      rating: 4.7,
      reviews: 61,
      packages: [
        VendorPackage('Agent', 40000, 'Un agent, 8 h'),
        VendorPackage('Équipe', 180000, 'Cinq agents, 8 h'),
      ],
    ),
    Vendor(
      id: 'chefs-maison',
      name: 'Chefs à la Maison',
      category: VendorCategory.staff,
      tagline: 'Chefs et serveurs',
      description: 'Chef et brigade de service pour les dîners privés et réceptions à domicile.',
      priceFrom: 60000,
      unit: 'pers.',
      image: 'https://images.unsplash.com/photo-1638704890058-841a4a376654?w=900&q=70&auto=format&fit=crop',
      zone: 'Riviera 3',
      rating: 4.9,
      reviews: 74,
      packages: [
        VendorPackage('Service', 60000, 'Un serveur, 6 h'),
        VendorPackage('Brigade', 380000, 'Chef et quatre serveurs'),
      ],
    ),
    Vendor(
      id: 'wedding-planner-ci',
      name: 'Wedding Planner CI',
      category: VendorCategory.planner,
      tagline: 'Organisation de mariage',
      description: 'Organisation complète ou coordination du jour J, de la dot au mariage civil.',
      priceFrom: 900000,
      image: 'https://images.unsplash.com/photo-1768055105012-4c53791b2877?w=900&q=70&auto=format&fit=crop',
      zone: 'Cocody',
      rating: 4.9,
      reviews: 118,
      packages: [
        VendorPackage('Jour J', 900000, 'Coordination du jour J'),
        VendorPackage('Complète', 2500000, 'Organisation de A à Z'),
      ],
    ),
    Vendor(
      id: 'kids-party',
      name: 'Kids Party Abidjan',
      category: VendorCategory.planner,
      tagline: 'Anniversaires enfants',
      description:
          'Thèmes, animateurs, structures gonflables et goûter clé en main.',
      priceFrom: 250000,
      image: 'https://images.unsplash.com/photo-1529651737248-dad5e287768e?w=900&q=70&auto=format&fit=crop',
      zone: 'Angré',
      rating: 4.8,
      reviews: 99,
      packages: [
        VendorPackage('Fête', 250000, 'Animation 3 h, 20 enfants'),
        VendorPackage('Grande fête', 480000, 'Animation, gonflable, goûter'),
      ],
    ),
    Vendor(
      id: 'corporate-events',
      name: 'Corporate Events CI',
      category: VendorCategory.planner,
      tagline: 'Événements d’entreprise',
      description: 'Séminaires, lancements de produits et soirées de fin d’année, logistique comprise.',
      priceFrom: 1500000,
      image: 'https://images.unsplash.com/photo-1544655152-4dc3bc4df059?w=900&q=70&auto=format&fit=crop',
      zone: 'Plateau',
      rating: 4.7,
      reviews: 52,
      packages: [
        VendorPackage('Séminaire', 1500000, 'Journée, salle et logistique'),
        VendorPackage('Gala', 3800000, 'Soirée d’entreprise complète'),
      ],
    ),
    Vendor(
      id: 'quad-bassam',
      name: 'Quad Grand-Bassam',
      category: VendorCategory.activity,
      tagline: 'Quad et balade plage',
      description: 'Balades en quad sur la plage de Grand-Bassam, idéales pour les EVJF et EVG.',
      priceFrom: 35000,
      unit: 'pers.',
      image: 'https://images.unsplash.com/photo-1787586997698-614cac396bee?w=900&q=70&auto=format&fit=crop',
      zone: 'Grand-Bassam',
      rating: 4.7,
      reviews: 81,
      packages: [
        VendorPackage('Balade', 35000, '1 h de quad'),
        VendorPackage('Aventure', 60000, '2 h et déjeuner'),
      ],
    ),
    Vendor(
      id: 'karaoke-club',
      name: 'Karaoké Club Zone 4',
      category: VendorCategory.activity,
      tagline: 'Karaoké privatisable',
      description: 'Salons privés de karaoké avec boissons pour anniversaires et afterworks.',
      priceFrom: 150000,
      image: 'https://images.unsplash.com/photo-1775326714947-759837c872cb?w=900&q=70&auto=format&fit=crop',
      zone: 'Zone 4',
      rating: 4.6,
      reviews: 63,
      packages: [
        VendorPackage('Salon', 150000, '3 h, 15 personnes'),
        VendorPackage('Soirée', 280000, '5 h, boissons incluses'),
      ],
    ),
    Vendor(
      id: 'atelier-cuisine',
      name: 'Atelier Cuisine Ivoire',
      category: VendorCategory.activity,
      tagline: 'Cours de cuisine en groupe',
      description:
          'Ateliers de cuisine ivoirienne en équipe, dégustation incluse.',
      priceFrom: 25000,
      unit: 'pers.',
      image: 'https://images.unsplash.com/photo-1758626219703-46bfaeaa39fa?w=900&q=70&auto=format&fit=crop',
      zone: 'Cocody',
      rating: 4.8,
      reviews: 45,
      packages: [
        VendorPackage('Atelier', 25000, '2 h 30 et dégustation'),
        VendorPackage('Team building', 40000, 'Atelier et concours'),
      ],
    ),
  ];

  static Vendor vendor(String id) => vendors.firstWhere((v) => v.id == id);

  /// Formule souscrite par les prestataires de démonstration (badge
  /// d'abonnement de la fiche publique) ; absents : Découverte.
  static const vendorPlans = <String, ProPlan>{
    'latrille': ProPlan.business,
    'ines-deco': ProPlan.business,
    'location-prestige': ProPlan.business,
    'villa-azur': ProPlan.creator,
    'saveurs': ProPlan.creator,
    'studio-lumiere': ProPlan.creator,
    'ballon-studio': ProPlan.starter,
    'lagune-sound': ProPlan.starter,
    'glam-fatim': ProPlan.starter,
  };

  static ProPlan planOf(Vendor v) => vendorPlans[v.id] ?? ProPlan.decouverte;

  /// Badge de qualité visible des organisateurs : note, volume d'avis et
  /// profil vérifié.
  static bool qualityOf(Vendor v) =>
      v.verified && v.rating >= 4.5 && v.reviews >= 10;

  static const reviews = [
    Review(
      'Aminata K.',
      5,
      'Équipe réactive et très professionnelle, tout était prêt à l’heure.',
      '12 oct. 2026',
    ),
    Review(
      'Jean-Marc B.',
      5,
      'Rapport qualité-prix excellent, nos invités en parlent encore.',
      '28 sept. 2026',
    ),
    Review(
      'Mariette D.',
      4,
      'Très bon service, un petit retard au montage vite rattrapé.',
      '9 sept. 2026',
    ),
    Review(
      'Koffi A.',
      5,
      'Devis clair, aucune surprise le jour J. Je recommande.',
      '22 août 2026',
    ),
    Review(
      'Sarah T.',
      4,
      'Belle prestation, communication un peu lente avant l’événement.',
      '3 août 2026',
    ),
    Review(
      'Ibrahim S.',
      5,
      'Exactement ce que nous avions imaginé, merci !',
      '15 juil. 2026',
    ),
  ];

  // ─── Abonnements ─────────────────────────────────────────────────────

  static const planFeatures = <Plan, List<String>>{
    Plan.free: [
      'Checklist et rétroplanning',
      'Budget intelligent : prévu, engagé, payé',
      '4 événements actifs',
      '2 collaborateurs',
      'Coffre-fort numérique 1 Go',
      'Marketplace et réservations',
    ],
    Plan.azur: [
      'Invitations numériques et RSVP',
      'QR code et gestion des entrées',
      'Rappels WhatsApp et SMS (100 / mois)',
      'Jusqu’à 5 collaborateurs',
      'Graphiques et export',
      'Coffre-fort numérique 5 Go',
    ],
    Plan.signature: [
      'Tout Azur',
      'Assistant IA de votre événement',
      'Comparaison assistée des devis',
      'Collaborateurs illimités',
      'Rappels WhatsApp et SMS (300 / mois)',
      'Coffre-fort numérique 10 Go',
    ],
    Plan.privilege: [
      'Tout Signature',
      'Concierge Calandix',
      'Album privé de l’événement',
      'Assistance prioritaire',
      'Rappels WhatsApp et SMS (1 000 / mois)',
      'Coffre-fort numérique 20 Go',
    ],
  };

  /// Contenu du Pass Événement (paiement unique, un événement, 90 jours).
  static const passFeatures = <String>[
    'Toutes les fonctionnalités de Privilège',
    'Jusqu’à 2 000 invités',
    'Jusqu’à 30 collaborateurs',
    'Budget avancé et suivi des dépenses',
    'Checklist et rétroplanning',
    'Invitations numériques et RSVP',
    'QR code et gestion des entrées',
    'Assistant IA et Concierge IA',
    'Comparaison des devis',
    'Espace documentaire',
    'Album privé',
    'Assistance prioritaire',
    'Quota de notifications défini',
  ];

  // ─── Agents IA ───────────────────────────────────────────────────────

  static AgentProfile agent(EventCategory c) => switch (c) {
    EventCategory.wedding => const AgentProfile(
      'Wedding Planner IA',
      'Votre organisatrice de mariage, disponible jour et nuit.',
      [
        AgentSkill('Créer le budget', AppIcons.wallet, AgentAction.budget),
        AgentSkill(
          'Négocier un devis',
          AppIcons.handshake,
          AgentAction.negotiate,
        ),
        AgentSkill(
          'Trouver des économies',
          AppIcons.piggy,
          AgentAction.savings,
        ),
        AgentSkill(
          'Générer le planning',
          AppIcons.calendarCheck,
          AgentAction.planning,
        ),
        AgentSkill('Plan de table', AppIcons.table, AgentAction.seating),
        AgentSkill('Invitations', AppIcons.mail, AgentAction.invitations),
        AgentSkill(
          'Messages aux invités',
          AppIcons.message,
          AgentAction.guestMessage,
        ),
        AgentSkill(
          'Dépenses restantes',
          AppIcons.calculator,
          AgentAction.remaining,
        ),
      ],
    ),
    EventCategory.birthday => const AgentProfile(
      'Party Planner IA',
      'Thème, surprise et quantités : la fête calculée au plus juste.',
      [
        AgentSkill(
          'Orchestrer la surprise',
          AppIcons.eyeOff,
          AgentAction.planning,
        ),
        AgentSkill(
          'Quantités gâteau & boissons',
          AppIcons.calculator,
          AgentAction.remaining,
        ),
        AgentSkill(
          'Trouver des économies',
          AppIcons.piggy,
          AgentAction.savings,
        ),
        AgentSkill('Invitations', AppIcons.mail, AgentAction.invitations),
      ],
    ),
    EventCategory.baby => const AgentProfile(
      'Baby Planner IA',
      'Tout organiser sans fatiguer les futurs parents.',
      [
        AgentSkill('Liste de naissance', AppIcons.gift, AgentAction.savings),
        AgentSkill(
          'Planning doux',
          AppIcons.calendarCheck,
          AgentAction.planning,
        ),
        AgentSkill('Faire-part', AppIcons.mail, AgentAction.invitations),
        AgentSkill(
          'Budget restant',
          AppIcons.calculator,
          AgentAction.remaining,
        ),
      ],
    ),
    EventCategory.friends => const AgentProfile(
      'Squad Planner IA',
      'Qui doit quoi, qui vient, qui dort où.',
      [
        AgentSkill(
          'Partager les frais',
          AppIcons.handCoins,
          AgentAction.remaining,
        ),
        AgentSkill('Sondage express', AppIcons.chart, AgentAction.planning),
        AgentSkill(
          'Relancer le groupe',
          AppIcons.message,
          AgentAction.guestMessage,
        ),
        AgentSkill(
          'Trouver des économies',
          AppIcons.piggy,
          AgentAction.savings,
        ),
      ],
    ),
    EventCategory.outing => const AgentProfile(
      'Trip Planner IA',
      'Météo, matériel et trajets pour une sortie sans oubli.',
      [
        AgentSkill('Météo & plan B', AppIcons.sun, AgentAction.planning),
        AgentSkill('Liste du matériel', AppIcons.tasks, AgentAction.seating),
        AgentSkill(
          'Courses par personne',
          AppIcons.calculator,
          AgentAction.remaining,
        ),
        AgentSkill(
          'Message au groupe',
          AppIcons.message,
          AgentAction.guestMessage,
        ),
      ],
    ),
    EventCategory.pro => const AgentProfile(
      'Event Ops IA',
      'Budget validé, programme tenu, ROI mesuré.',
      [
        AgentSkill('Budget & validation', AppIcons.wallet, AgentAction.budget),
        AgentSkill('Programme', AppIcons.calendarCheck, AgentAction.planning),
        AgentSkill(
          'Négocier un devis',
          AppIcons.handshake,
          AgentAction.negotiate,
        ),
        AgentSkill('Rapport ROI', AppIcons.chartUp, AgentAction.remaining),
      ],
    ),
    EventCategory.milestone => const AgentProfile(
      'Hommage IA',
      'Un pot réussi en 48 h, des mots justes.',
      [
        AgentSkill(
          'Organisation express',
          AppIcons.lightning,
          AgentAction.planning,
        ),
        AgentSkill(
          'Écrire le discours',
          AppIcons.mic,
          AgentAction.guestMessage,
        ),
        AgentSkill('Cagnotte', AppIcons.handCoins, AgentAction.remaining),
      ],
    ),
    EventCategory.family => const AgentProfile(
      'Family Coordinator IA',
      'Cotisations, branches et commissions coordonnées.',
      [
        AgentSkill(
          'Suivi des cotisations',
          AppIcons.handCoins,
          AgentAction.remaining,
        ),
        AgentSkill('Programme', AppIcons.calendarCheck, AgentAction.planning),
        AgentSkill(
          'Message aux familles',
          AppIcons.message,
          AgentAction.guestMessage,
        ),
      ],
    ),
    EventCategory.charity => const AgentProfile(
      'Impact Planner IA',
      'Collecte, bénévoles et transparence.',
      [
        AgentSkill(
          'Objectif de collecte',
          AppIcons.chartUp,
          AgentAction.remaining,
        ),
        AgentSkill(
          'Remercier les donateurs',
          AppIcons.message,
          AgentAction.guestMessage,
        ),
        AgentSkill(
          'Trouver des économies',
          AppIcons.piggy,
          AgentAction.savings,
        ),
      ],
    ),
    EventCategory.seasonal => const AgentProfile(
      'Season Planner IA',
      'Réservez avant la hausse des prix, offrez sans oublier personne.',
      [
        AgentSkill(
          'Alertes prix de saison',
          AppIcons.reminder,
          AgentAction.savings,
        ),
        AgentSkill('Secret Santa', AppIcons.gift, AgentAction.seating),
        AgentSkill('Menu & courses', AppIcons.food, AgentAction.planning),
      ],
    ),
  };

  // ─── Business / Creator ──────────────────────────────────────────────

  static const businessAudience = [
    'Wedding planners',
    'Event planners',
    'Agences événementielles',
    'Hôtels',
    'Salles de réception',
    'Entreprises',
    'Associations',
    'Freelances',
  ];

  static const businessFeatures = <(IconData, String)>[
    (AppIcons.confetti, 'Événements illimités'),
    (AppIcons.crm, 'CRM clients'),
    (AppIcons.file, 'Devis'),
    (AppIcons.contract, 'Contrats'),
    (AppIcons.invoice, 'Facturation'),
    (AppIcons.team, 'Équipe multi-utilisateurs'),
    (AppIcons.palette, 'Marque blanche'),
    (AppIcons.chartUp, 'Tableau de bord financier'),
    (AppIcons.lightning, 'Automatisations'),
    (AppIcons.code, 'API'),
    (AppIcons.plugs, 'Intégrations'),
    (AppIcons.chart, 'Statistiques avancées'),
  ];

  static const adFormats = <(Sponsor, String)>[
    (
      Sponsor.recommended,
      'Badge « Recommandé » sur votre fiche et dans les sélections.',
    ),
    (
      Sponsor.ofTheMonth,
      'La bannière en tête de la marketplace pendant un mois.',
    ),
    (Sponsor.featured, 'Votre fiche en grand format dans « Mises en avant ».'),
    (
      Sponsor.result,
      'Première position sur les recherches de votre catégorie.',
    ),
  ];
}

enum AgentAction {
  budget,
  negotiate,
  savings,
  planning,
  seating,
  invitations,
  guestMessage,
  remaining,
}

@immutable
class AgentSkill {
  const AgentSkill(this.label, this.icon, this.action);
  final String label;
  final IconData icon;
  final AgentAction action;
}

@immutable
class AgentProfile {
  const AgentProfile(this.name, this.pitch, this.skills);
  final String name;
  final String pitch;
  final List<AgentSkill> skills;
}
