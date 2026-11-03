import 'package:supabase_flutter/supabase_flutter.dart';

import '../backend/backend.dart';
import '../i18n/tr.dart';
import '../models/models.dart';
import 'profile.dart';

/// Erreur d'authentification présentable à l'utilisateur.
class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Résultat d'une inscription : connecté tout de suite, ou en attente de la
/// confirmation de l'adresse e-mail.
enum SignUpOutcome { signedIn, confirmEmail }

/// Comptes réels sur Supabase : connexion, inscription, profil.
class AuthGateway {
  const AuthGateway();

  GoTrueClient get _auth => Backend.client.auth;

  String? get currentUserId => _auth.currentUser?.id;

  Stream<AuthState> get changes => _auth.onAuthStateChange;

  Future<UserProfile> signIn(String email, String password) async {
    try {
      await _auth.signInWithPassword(email: email.trim(), password: password);
    } on AuthException catch (e) {
      throw AuthFailure(_message(e));
    }
    return loadProfile();
  }

  /// Connexion avec Google : le navigateur part chez Google et revient sur
  /// l'app, où la session est reprise (voir [changes]). Un nouveau compte
  /// créé ainsi est un compte organisateur.
  Future<void> signInWithGoogle() async {
    try {
      await _auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: Backend.redirectUrl,
        queryParams: {'prompt': 'select_account'},
      );
    } on AuthException catch (e) {
      throw AuthFailure(_message(e));
    }
  }

  Future<SignUpOutcome> signUp(UserProfile p, String password) async {
    final c = p.creator;
    try {
      final r = await _auth.signUp(
        email: p.email.trim(),
        password: password,
        emailRedirectTo: Backend.redirectUrl,
        data: {
          'role': p.role.name,
          'full_name': p.name,
          'phone': p.phone,
          'city': p.city,
          // Fiche pro créée à la première connexion (il faut une session).
          if (c != null) 'creator': _creatorJson(c),
        },
      );
      if (r.session == null) return SignUpOutcome.confirmEmail;
    } on AuthException catch (e) {
      throw AuthFailure(_message(e));
    }
    await loadProfile();
    return SignUpOutcome.signedIn;
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: Backend.redirectUrl,
      );
    } on AuthException catch (e) {
      throw AuthFailure(_message(e));
    }
  }

  Future<void> signOut() => _auth.signOut();

  /// Profil du compte connecté. Crée la fiche Creator au premier passage,
  /// à partir des informations saisies à l'inscription.
  Future<UserProfile> loadProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthFailure('Session expirée, reconnectez-vous.'.tr);
    }
    final db = Backend.client;
    final row = await db.from('profiles').select().eq('id', user.id).single();
    final role = row['role'] == 'creator'
        ? UserRole.creator
        : UserRole.organizer;
    Map<String, dynamic>? pro;
    if (role == UserRole.creator) {
      pro = await db
          .from('creator_profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      final draft = user.userMetadata?['creator'];
      if (pro == null && draft is Map) {
        pro = await db
            .from('creator_profiles')
            .insert({'id': user.id, ...Map<String, dynamic>.from(draft)})
            .select()
            .single();
      }
    }
    return UserProfile(
      role: role,
      name: (row['full_name'] as String?) ?? '',
      email: user.email ?? '',
      phone: (row['phone'] as String?) ?? '',
      city: (row['city'] as String?) ?? '',
      creator: pro == null ? null : _creatorFrom(pro),
    );
  }

  /// Enregistre les modifications du profil (et de la fiche Creator).
  Future<void> saveProfile(UserProfile p) async {
    final id = currentUserId;
    if (id == null) return;
    final db = Backend.client;
    await db
        .from('profiles')
        .update({'full_name': p.name, 'phone': p.phone, 'city': p.city})
        .eq('id', id);
    final c = p.creator;
    if (c != null) {
      await db.from('creator_profiles').update(_creatorJson(c)).eq('id', id);
    }
  }

  static Map<String, dynamic> _creatorJson(CreatorInfo c) => {
    'kind': c.kind.name,
    'business_name': c.businessName,
    'display_name': c.displayName,
    'category': c.category.name,
    'zone': c.zone,
    'rccm': c.rccm,
    'description': c.description,
    'price_from': c.priceFrom,
    'address': c.address,
    'website': c.website,
    'portfolio_url': c.portfolio,
  };

  static CreatorInfo _creatorFrom(Map<String, dynamic> r) => CreatorInfo(
    kind: CreatorKind.values.firstWhere(
      (k) => k.name == r['kind'],
      orElse: () => CreatorKind.freelancer,
    ),
    businessName: r['business_name'] as String,
    displayName: r['display_name'] as String,
    category: VendorCategory.values.firstWhere(
      (v) => v.name == r['category'],
      orElse: () => VendorCategory.planner,
    ),
    zone: r['zone'] as String,
    rccm: r['rccm'] as String?,
    description: (r['description'] as String?) ?? '',
    priceFrom: (r['price_from'] as num?)?.toInt() ?? 0,
    address: (r['address'] as String?) ?? '',
    website: r['website'] as String?,
    portfolio: r['portfolio_url'] as String?,
  );

  static String _message(AuthException e) => switch (e.code) {
    'invalid_credentials' => 'E-mail ou mot de passe incorrect.'.tr,
    'email_not_confirmed' =>
      'Confirmez d’abord votre adresse : ouvrez le lien reçu par e-mail.'.tr,
    'user_already_exists' || 'email_exists' =>
      'Un compte existe déjà avec cette adresse. Connectez-vous.'.tr,
    'weak_password' =>
      'Mot de passe trop faible : 8 caractères avec minuscules, majuscules et chiffres.'
          .tr,
    'over_email_send_rate_limit' || 'over_request_rate_limit' =>
      'Trop de tentatives. Réessayez dans quelques minutes.'.tr,
    'validation_failed' => 'Adresse e-mail invalide.'.tr,
    _ =>
      'Connexion impossible pour le moment. Vérifiez votre connexion puis réessayez.'
          .tr,
  };
}
