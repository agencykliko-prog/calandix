/// Adresse publique de l'application web (calandix.com/app, routes en #).
/// Tous les liens partagés (RSVP, site de l'événement, équipe) en partent.
const appBaseUrl = 'https://calandix.com/app/#';

/// Lien complet vers une route de l'application.
String appLink(String path) => '$appBaseUrl$path';
