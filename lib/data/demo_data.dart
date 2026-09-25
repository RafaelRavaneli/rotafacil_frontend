import '../models/guide.dart';
import '../models/trail.dart';

const waterfall =
    'https://images.unsplash.com/photo-1432405972618-c60b0225b8f9?auto=format&fit=crop&w=1400&q=85';
const mountain =
    'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=1400&q=85';
const valley =
    'https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?auto=format&fit=crop&w=1400&q=85';
const forest =
    'https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=1400&q=85';

const avatar1 =
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=400&q=80';
const avatar2 =
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=400&q=80';
const avatar3 =
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80';
const avatar4 =
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80';

const trails = <Trail>[
  Trail(
    id: 'cachoeira',
    name: 'Trilha da Cachoeira do Véu',
    city: 'Ilhabela',
    state: 'SP',
    difficulty: 'Moderada',
    distanceKm: 8.6,
    duration: '3h 30m',
    elevation: 340,
    bestSeason: 'Mar - Out',
    rating: 4.8,
    reviews: 124,
    description:
        'Caminhada leve a moderada com um lindo destino: uma cachoeira de águas cristalinas cercada pela mata nativa.',
    imageUrl: waterfall,
    guideName: 'Rafael Souza',
    date: '24/05/2026',
    price: 189,
    latitude: -23.7785,
    longitude: -45.3588,
  ),
  Trail(
    id: 'mirante',
    name: 'Trilha do Mirante',
    city: 'Londrina',
    state: 'PR',
    difficulty: 'Fácil',
    distanceKm: 5.1,
    duration: '2h 10m',
    elevation: 180,
    bestSeason: 'Abr - Nov',
    rating: 4.6,
    reviews: 87,
    description:
        'Uma trilha acessível com vista panorâmica, ótima para iniciantes e para quem quer curtir o pôr do sol.',
    imageUrl: mountain,
    guideName: 'Fernanda Melo',
    date: '02/09/2026',
    price: 129,
    latitude: -23.3103,
    longitude: -51.1628,
  ),
  Trail(
    id: 'vale',
    name: 'Trilha do Vale Verde',
    city: 'Apucarana',
    state: 'PR',
    difficulty: 'Difícil',
    distanceKm: 12.2,
    duration: '5h',
    elevation: 620,
    bestSeason: 'Mai - Set',
    rating: 4.9,
    reviews: 76,
    description:
        'Percurso intenso por vales e serras, com trechos técnicos e paisagens amplas.',
    imageUrl: valley,
    guideName: 'Lucas Andrade',
    date: '15/09/2026',
    price: 239,
    latitude: -23.5505,
    longitude: -51.4608,
  ),
  Trail(
    id: 'marumbi',
    name: 'Pico do Marumbi',
    city: 'Morretes',
    state: 'PR',
    difficulty: 'Difícil',
    distanceKm: 8.0,
    duration: '5h 40m',
    elevation: 850,
    bestSeason: 'Abr - Ago',
    rating: 4.8,
    reviews: 128,
    description: 'Trilha desafiadora com vistas incríveis da Serra do Mar.',
    imageUrl: forest,
    guideName: 'Rafael Souza',
    date: '30/09/2026',
    price: 219,
    status: 'Em revisão',
    latitude: -25.4434,
    longitude: -48.9119,
  ),
];

const guides = <GuideProfile>[
  GuideProfile(
    id: 'lucas-andrade',
    name: 'Lucas Andrade',
    rating: 4.9,
    reviews: 126,
    imageUrl: avatar1,
    bio:
        'Condutor focado em montanhismo e percursos de maior dificuldade, com experiência em orientação e segurança em ambientes naturais.',
    specialties: ['Montanhismo', 'Trekking', 'Travessias'],
    experienceYears: 6,
    completedTrails: 148,
    totalKm: 1184,
    city: 'Apucarana',
    state: 'PR',
  ),
  GuideProfile(
    id: 'fernanda-melo',
    name: 'Fernanda Melo',
    rating: 4.8,
    reviews: 94,
    imageUrl: avatar2,
    bio:
        'Guia de ecoturismo com atendimento acolhedor, ideal para iniciantes, famílias e experiências em cachoeiras e mirantes.',
    specialties: ['Ecoturismo', 'Cachoeiras', 'Famílias'],
    experienceYears: 4,
    completedTrails: 103,
    totalKm: 742,
    city: 'Londrina',
    state: 'PR',
  ),
  GuideProfile(
    id: 'rafael-souza',
    name: 'Rafael Souza',
    rating: 4.9,
    reviews: 137,
    imageUrl: avatar3,
    bio:
        'Especialista em trekking e trilhas de serra, com foco em planejamento de rota, ritmo do grupo e experiências seguras.',
    specialties: ['Trekking', 'Serras', 'Cachoeiras'],
    experienceYears: 5,
    completedTrails: 124,
    totalKm: 986,
    city: 'Morretes',
    state: 'PR',
    status: 'Aprovado',
  ),
  GuideProfile(
    id: 'juliana-t',
    name: 'Juliana T.',
    rating: 4.7,
    reviews: 71,
    imageUrl: avatar4,
    bio:
        'Condutora de caminhadas leves e experiências de contemplação, com foco em grupos pequenos e turismo responsável.',
    specialties: ['Caminhada', 'Mirantes', 'Natureza'],
    experienceYears: 3,
    completedTrails: 82,
    totalKm: 514,
    city: 'Maringá',
    state: 'PR',
  ),
];

GuideProfile? guideByName(String name) {
  for (final guide in guides) {
    if (guide.name.toLowerCase() == name.toLowerCase()) {
      return guide;
    }
  }
  return null;
}
