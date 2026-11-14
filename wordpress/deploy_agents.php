<?php
/**
 * calandix.com prêt pour les agents. À exécuter sur le site (Novamira
 * « execute-php ») après extraction du thème, avec build/pages.json
 * (python wordpress/app_pages.py) déposé dans wp-content/cx-tmp/pages.json.
 *
 * - llms.txt et index.md copiés à la racine (fichiers statiques) ;
 * - .htaccess : Markdown servi sur Accept: text/markdown, avant le cache ;
 * - pages À propos, Contact, Conditions, Confidentialité (créées ou mises à
 *   jour) ; l'article d'exemple « Hello world! » repasse en brouillon ;
 * - accueil Elementor : liens du pied de page vers ces pages, lien Contact et
 *   téléphone, formulaire d'accès anticipé annoté pour WebMCP.
 */

$out   = [];
$theme = get_template_directory() . '/agents/';

// ─── Fichiers statiques ─────────────────────────────────────────────────
foreach ( [ 'llms.txt', 'index.md' ] as $f ) {
	$out[ $f ] = copy( $theme . $f, ABSPATH . $f ) ? 'ok' : 'échec';
}

// ─── .htaccess ──────────────────────────────────────────────────────────
$ht    = ABSPATH . '.htaccess';
$rules = implode( "\n", [
	'# BEGIN Calandix agents',
	'<IfModule mod_rewrite.c>',
	'RewriteEngine On',
	'RewriteCond %{HTTP:Accept} text/markdown [NC]',
	'RewriteRule ^$ /index.md [L]',
	'</IfModule>',
	'<IfModule mod_mime.c>',
	'AddType "text/markdown; charset=UTF-8" .md',
	'</IfModule>',
	'<IfModule mod_headers.c>',
	'<Files "index.md">',
	'Header set Link "<' . home_url( '/llms.txt' ) . '>; rel=\"describedby\"; type=\"text/plain\""',
	'Header set Vary "Accept"',
	'</Files>',
	'</IfModule>',
	'# END Calandix agents',
] );
$cur = (string) file_get_contents( $ht );
if ( ! file_exists( $ht . '.bak-calandix' ) ) {
	copy( $ht, $ht . '.bak-calandix' );
}
$cur = preg_replace( '/# BEGIN Calandix agents.*?# END Calandix agents\n*/s', '', $cur );
// En tête de fichier : avant la lecture du cache LiteSpeed.
$out['htaccess'] = false !== file_put_contents( $ht, $rules . "\n\n" . $cur ) ? 'ok' : 'échec';

// ─── Pages publiques ────────────────────────────────────────────────────
$pages = json_decode( (string) file_get_contents( WP_CONTENT_DIR . '/cx-tmp/pages.json' ), true ) ?: [];
foreach ( $pages as $slug => $p ) {
	$existing = get_page_by_path( $slug );
	$args     = [
		'post_type'    => 'page',
		'post_status'  => 'publish',
		'post_title'   => $p['title'],
		'post_name'    => $slug,
		'post_content' => $p['content'],
	];
	if ( $existing ) {
		$args['ID'] = $existing->ID;
	}
	$id                       = wp_insert_post( wp_slash( $args ), true );
	$out[ 'page_' . $slug ] = is_wp_error( $id ) ? $id->get_error_message() : $id;
}
@unlink( WP_CONTENT_DIR . '/cx-tmp/pages.json' );
$hello = get_page_by_path( 'hello-world', OBJECT, 'post' );
if ( $hello && 'publish' === $hello->post_status ) {
	wp_update_post( [ 'ID' => $hello->ID, 'post_status' => 'draft' ] );
	$out['hello_world'] = 'brouillon';
}
if ( get_page_by_path( 'confidentialite' ) ) {
	update_option( 'wp_page_for_privacy_policy', get_page_by_path( 'confidentialite' )->ID );
}

// ─── Accueil Elementor : pied de page et formulaire ─────────────────────
$page  = (int) get_option( 'page_on_front' );
$data  = json_decode( (string) get_post_meta( $page, '_elementor_data', true ), true );
$attrs = (array) get_post_meta( $page, '_cx_attrs', true );
$map   = [ '/a-propos' => '/a-propos/', '/conditions' => '/conditions/', '/confidentialite' => '/confidentialite/' ];
$taken = [];
$ids   = function ( array $els ) use ( &$ids, &$taken ) {
	foreach ( $els as $el ) {
		$taken[ $el['id'] ] = true;
		$ids( $el['elements'] ?? [] );
	}
};
$ids( $data );
$new_id = function () use ( &$taken ) {
	do {
		$id = substr( md5( wp_rand() . microtime() ), 0, 7 );
	} while ( isset( $taken[ $id ] ) );
	$taken[ $id ] = true;
	return $id;
};
$button = function ( array $model, string $text, string $url ) use ( $new_id ) {
	$b                                         = $model;
	$b['id']                                   = $new_id();
	$b['settings']['text']['value']            = $text;
	$b['settings']['link']['value']['destination']['value'] = $url;
	return $b;
};
$links = 0;
$walk  = function ( array $els ) use ( &$walk, &$attrs, $map, $button, &$links ) {
	foreach ( $els as $i => $el ) {
		// Bloc « Calandix » du pied de page : ses liens vers l'application.
		$kids = $el['elements'] ?? [];
		$hit  = false;
		foreach ( $kids as $k => $kid ) {
			$app = $attrs[ $kid['id'] ]['data-app-link'] ?? null;
			if ( $app && isset( $map[ $app ] ) ) {
				$kids[ $k ]['settings']['link']['value']['destination']['value'] = $map[ $app ];
				unset( $attrs[ $kid['id'] ]['data-app-link'] );
				if ( ! $attrs[ $kid['id'] ] ) {
					unset( $attrs[ $kid['id'] ] );
				}
				$hit = true;
				++$links;
			}
		}
		if ( $hit ) {
			$texts = array_map( fn( $k ) => $k['settings']['text']['value'] ?? '', $kids );
			$model = null;
			foreach ( $kids as $k ) {
				if ( 'e-button' === ( $k['widgetType'] ?? '' ) ) {
					$model = $k;
				}
			}
			if ( $model && ! in_array( 'Contact', $texts, true ) ) {
				$pos = array_search( 'À propos', $texts, true );
				array_splice( $kids, false === $pos ? count( $kids ) : $pos + 1, 0, [ $button( $model, 'Contact', '/contact/' ) ] );
			}
			if ( $model && ! in_array( '+225 07 57 63 37 65', $texts, true ) ) {
				$kids[] = $button( $model, '+225 07 57 63 37 65', 'tel:+2250757633765' );
			}
		}
		$els[ $i ]['elements'] = $walk( $kids );
	}
	return $els;
};
$data = $walk( $data );

$form = 0;
array_walk_recursive( $data, function ( &$v, $k ) use ( &$form ) {
	if ( 'html' !== $k || ! is_string( $v ) || ! str_contains( $v, 'name="acces-anticipe"' ) || str_contains( $v, 'toolname=' ) ) {
		return;
	}
	$v = str_replace(
		'name="acces-anticipe"',
		'name="acces-anticipe" toolname="calandix_acces_anticipe" tooldescription="Inscrire une personne sur la liste d’accès anticipé de Calandix (nom, e-mail, numéro WhatsApp, profil organisateur ou prestataire, consentement). La personne vérifie et envoie elle-même le formulaire."',
		$v
	);
	++$form;
} );

update_post_meta( $page, '_elementor_data', wp_slash( wp_json_encode( $data ) ) );
update_post_meta( $page, '_cx_attrs', $attrs );
$out['liens_pied_de_page'] = $links;
$out['formulaire_annote']  = $form;

\Elementor\Plugin::$instance->files_manager->clear_cache();
do_action( 'litespeed_purge_all' );
return $out;
