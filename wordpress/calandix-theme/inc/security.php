<?php
/**
 * Calandix · durcissement de calandix.com (audit OWASP du 18 nov. 2026).
 *
 * - En-têtes HTTP de sécurité (A05) ;
 * - versions de WordPress et de PHP masquées (A05) ;
 * - pas d'énumération des comptes : ?author=, archives d'auteur, liste des
 *   utilisateurs de l'API REST pour les visiteurs (A01 / A07) ;
 * - XML-RPC désactivé : surface d'attaque par force brute (A07) ;
 * - messages d'échec de connexion identiques, quel que soit le champ faux (A07).
 */

defined( 'ABSPATH' ) || exit;

// ─── En-têtes HTTP ──────────────────────────────────────────────────────
add_action(
	'send_headers',
	function () {
		if ( headers_sent() ) {
			return;
		}
		header_remove( 'X-Powered-By' );
		header( 'X-Content-Type-Options: nosniff' );
		// SAMEORIGIN : l'éditeur Elementor affiche la page dans un cadre du même site.
		header( 'X-Frame-Options: SAMEORIGIN' );
		header( 'Referrer-Policy: strict-origin-when-cross-origin' );
		header( 'Permissions-Policy: camera=(), microphone=(), geolocation=(), payment=(), usb=(), interest-cohort=()' );
		if ( is_ssl() ) {
			header( 'Strict-Transport-Security: max-age=31536000; includeSubDomains' );
		}
	}
);

// Les pages de connexion et d'administration n'ont pas de send_headers.
foreach ( array( 'login_init', 'admin_init' ) as $calandix_hook ) {
	add_action(
		$calandix_hook,
		function () {
			if ( headers_sent() ) {
				return;
			}
			header_remove( 'X-Powered-By' );
			header( 'X-Content-Type-Options: nosniff' );
			header( 'X-Frame-Options: SAMEORIGIN' );
			header( 'Referrer-Policy: strict-origin-when-cross-origin' );
		}
	);
}

// ─── Versions masquées ──────────────────────────────────────────────────
remove_action( 'wp_head', 'wp_generator' );
add_filter( 'the_generator', '__return_empty_string' );

// ─── Pas d'énumération des comptes ──────────────────────────────────────
add_action(
	'template_redirect',
	function () {
		if ( is_user_logged_in() ) {
			return;
		}
		// phpcs:ignore WordPress.Security.NonceVerification.Recommended
		if ( isset( $_GET['author'] ) || is_author() ) {
			wp_safe_redirect( home_url( '/' ), 301 );
			exit;
		}
	},
	0
);

add_filter(
	'rest_endpoints',
	function ( $endpoints ) {
		if ( is_user_logged_in() ) {
			return $endpoints;
		}
		foreach ( array_keys( $endpoints ) as $route ) {
			if ( str_starts_with( $route, '/wp/v2/users' ) ) {
				unset( $endpoints[ $route ] );
			}
		}
		return $endpoints;
	}
);

// Noms d'auteur absents des sitemaps WordPress.
add_filter(
	'wp_sitemaps_add_provider',
	fn( $provider, $name ) => 'users' === $name ? false : $provider,
	10,
	2
);

// ─── Connexion ──────────────────────────────────────────────────────────
add_filter( 'xmlrpc_enabled', '__return_false' );
add_filter(
	'xmlrpc_methods',
	function ( $methods ) {
		unset( $methods['pingback.ping'], $methods['pingback.extensions.getPingbacks'] );
		return $methods;
	}
);

// Même message que l'identifiant ou le mot de passe soit faux : on ne
// confirme pas l'existence d'un compte.
add_filter(
	'login_errors',
	fn() => __( 'Identifiant ou mot de passe incorrect.', 'calandix' )
);
