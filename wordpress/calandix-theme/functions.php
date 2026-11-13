<?php
/**
 * Thème Calandix.
 *
 * L'accueil est une page Elementor (éléments atomiques) qui reprend la landing
 * balise pour balise : styles.css et app.js de landing/ s'y appliquent tels
 * quels. La landing statique (landing/index.html) reste le repli quand aucune
 * page d'accueil n'est définie, et sert la page 404.
 */

defined( 'ABSPATH' ) || exit;

const CALANDIX_LANDING_VERSION = '67';

add_action( 'after_setup_theme', function () {
	remove_action( 'wp_head', 'print_emoji_detection_script', 7 );
	remove_action( 'wp_print_styles', 'print_emoji_styles' );
	remove_action( 'wp_head', 'wp_generator' );
} );

function calandix_landing_dir(): string {
	return get_template_directory() . '/landing/';
}

function calandix_landing_uri(): string {
	return get_template_directory_uri() . '/landing/';
}

/** Chemins des fichiers vers le thème, adresse du site à la place de l'ancien domaine. */
function calandix_rewrite( string $html ): string {
	$uri  = calandix_landing_uri();
	$html = preg_replace( '#(src|href)="/?(img|fonts)/#', '$1="' . $uri . '$2/', $html );
	$html = preg_replace( '#(src|href)="/?(styles\.css|app\.js|boot\.js|phone3d\.js)#', '$1="' . $uri . '$2', $html );
	$html = str_replace( 'https://eventa.ci/img/', $uri . 'img/', $html );
	return str_replace( 'https://eventa.ci/', home_url( '/' ), $html );
}

/** Page construite avec Elementor à partir de la landing. */
function calandix_is_landing_page(): bool {
	return is_singular( 'page' ) && get_post_meta( get_queried_object_id(), '_calandix_landing', true );
}

function calandix_is_editor_preview(): bool {
	return class_exists( '\Elementor\Plugin' )
		&& ( \Elementor\Plugin::$instance->preview->is_preview_mode() || isset( $_GET['elementor-preview'] ) ); // phpcs:ignore
}

/** Morceaux de landing/index.html : <head> et scripts de fin de page. */
function calandix_landing_parts(): array {
	static $parts = null;
	if ( null !== $parts ) {
		return $parts;
	}
	$html = calandix_rewrite( (string) file_get_contents( calandix_landing_dir() . 'index.html' ) );
	preg_match( '#<head>(.*?)</head>#s', $html, $h );
	$head = $h[1] ?? '';
	// Déjà posés par le gabarit Elementor ou chargés par wp_enqueue.
	$head = preg_replace( '#<meta charset[^>]*>|<meta name="viewport"[^>]*>|<link rel="stylesheet"[^>]*>#', '', $head );
	// Avec Yoast SEO, le titre, la description, l'adresse canonique et les
	// aperçus de partage se règlent dans Yoast (page « Accueil »).
	if ( defined( 'WPSEO_VERSION' ) ) {
		$head = preg_replace( '#<title>.*?</title>|<meta name="description"[^>]*>|<link rel="canonical"[^>]*>|<meta (?:property="og:|name="twitter:)[^>]*>#s', '', $head );
	}
	preg_match( '#(?:.*</canvas>.*?</button>)(.*?)</body>#s', $html, $f );
	$scripts = '';
	if ( preg_match_all( '#<script\b[^>]*>.*?</script>|<!--.*?-->#s', $f[1] ?? '', $m ) ) {
		$scripts = implode( "\n", $m[0] );
	}
	return $parts = [ 'head' => $head, 'scripts' => $scripts ];
}

add_action( 'wp_head', function () {
	if ( ! calandix_is_landing_page() ) {
		return;
	}
	$uri = esc_js( calandix_landing_uri() );
	// Les scripts de la landing lisent ce préfixe (mascottes, FAQ, 3D).
	echo "<script>document.documentElement.dataset.assets='{$uri}';</script>\n";
	$head = calandix_landing_parts()['head'];
	if ( calandix_is_editor_preview() ) {
		// Dans l'éditeur : pas d'animation d'ouverture ni de script de page.
		$head = preg_replace( '#<script\b[^>]*boot\.js[^>]*></script>#', '', $head );
	}
	echo $head; // phpcs:ignore WordPress.Security.EscapeOutput -- fichier du thème.
}, 1 );

add_action( 'wp_enqueue_scripts', function () {
	if ( ! calandix_is_landing_page() ) {
		return;
	}
	// Après les styles d'Elementor : la landing garde la main à égalité.
	$deps = wp_style_is( 'elementor-frontend', 'registered' ) ? [ 'elementor-frontend' ] : [];
	wp_enqueue_style( 'calandix-landing', calandix_landing_uri() . 'styles.css', $deps, CALANDIX_LANDING_VERSION );
	if ( calandix_is_editor_preview() ) {
		// Éditeur : contenu visible sans les animations, widgets HTML sans
		// enveloppe dans la mise en page.
		wp_add_inline_style(
			'calandix-landing',
			'.reveal{opacity:1!important;transform:none!important}.split .w>span{transform:none!important}'
			. '.elementor-widget-html{display:contents}'
		);
		$theme = wp_get_theme()->get( 'Version' );
		wp_enqueue_script( 'calandix-editor-preview', get_template_directory_uri() . '/assets/editor-preview.js', [], $theme, false );
		wp_add_inline_script(
			'calandix-editor-preview',
			'window.CX_ATTRS=' . wp_json_encode( (array) get_post_meta( get_queried_object_id(), '_cx_attrs', true ) ) . ';',
			'before'
		);
	}
}, 100 );

add_action( 'wp_footer', function () {
	if ( calandix_is_landing_page() && ! calandix_is_editor_preview() ) {
		echo calandix_landing_parts()['scripts']; // phpcs:ignore WordPress.Security.EscapeOutput
	}
}, 99 );

/**
 * Rendu de la page Elementor : retrouve le balisage exact de la landing.
 *
 * - widgets HTML : leur contenu sans l'enveloppe d'Elementor ;
 * - attributs data-*, style, hidden… (non gérés par Elementor gratuit) remis
 *   d'après leur élément ;
 * - classes des <em> et <span> en ligne qu'Elementor efface ;
 * - classes et attributs techniques d'Elementor retirés.
 */
function calandix_restore_markup( string $html ): string {
	$id = get_queried_object_id();
	if ( ! $id || ! get_post_meta( $id, '_calandix_landing', true ) || calandix_is_editor_preview() ) {
		return $html;
	}
	$attrs = (array) get_post_meta( $id, '_cx_attrs', true );
	$fixes = (array) get_post_meta( $id, '_cx_fixes', true );

	$html = preg_replace(
		'#<div class="elementor-element[^"]*elementor-widget-html"[^>]*>\s*<!--cx:raw-->(.*?)<!--/cx:raw-->\s*</div>#s',
		'$1',
		$html
	);

	foreach ( $fixes as $el => $pairs ) {
		$html = preg_replace_callback(
			'#(<(\w+)\b[^>]*data-interaction-id="' . preg_quote( $el, '#' ) . '"[^>]*>)(.*?)(</\2>)#s',
			function ( $m ) use ( $pairs ) {
				foreach ( $pairs as [ $from, $to ] ) {
					$m[3] = str_replace( $from, $to, $m[3] );
				}
				return $m[1] . $m[3] . $m[4];
			},
			$html,
			1
		);
	}

	foreach ( $attrs as $el => $list ) {
		$extra = '';
		foreach ( (array) $list as $name => $value ) {
			$extra .= ' ' . preg_replace( '/[^a-zA-Z0-9_:.-]/', '', $name )
				. ( '' === $value ? '' : '="' . esc_attr( $value ) . '"' );
		}
		$html = preg_replace(
			'#(<\w+\b[^>]*data-(?:id|interaction-id)="' . preg_quote( $el, '#' ) . '"[^>]*?)(\s*/?>)#',
			'$1' . str_replace( [ '\\', '$' ], [ '\\\\', '\$' ], $extra ) . '$2',
			$html,
			1
		);
	}

	// Classes et attributs propres à Elementor sur les éléments atomiques.
	$html = preg_replace_callback(
		'#\sclass="([^"]*\be-(?:con|[a-z-]+-base|default-[a-z0-9]+)\b[^"]*)"#',
		function ( $m ) {
			$keep = array_filter(
				preg_split( '/\s+/', trim( $m[1] ) ),
				fn( $c ) => ! preg_match( '/^(elementor-element(-[a-z0-9]+)?|e-con|e-atomic-element|e-[a-z-]+-base|e-default-[a-z0-9]+)$/', $c )
			);
			return $keep ? ' class="' . implode( ' ', $keep ) . '"' : '';
		},
		$html
	);
	$html = preg_replace( '#\s(?:data-id|data-element_type|data-e-type|data-interaction-id)="[^"]*"#', '', $html );
	return preg_replace( '#(<a\b[^>]*?)\starget="_self"#', '$1', $html );
}
add_filter( 'elementor/frontend/the_content', 'calandix_restore_markup', 20 );

/** Affiche un fichier HTML de landing/ avec les hooks WordPress (repli et 404). */
function calandix_render( string $file ): void {
	$html = calandix_rewrite( (string) file_get_contents( calandix_landing_dir() . $file ) );
	$uri  = calandix_landing_uri();
	$html = preg_replace( '#<html([^>]*)>#', '<html$1 data-assets="' . esc_attr( $uri ) . '">', $html, 1 );

	ob_start();
	wp_head();
	$head = ob_get_clean();
	ob_start();
	wp_footer();
	$foot = ob_get_clean();

	$html = str_replace( '</head>', $head . "\n</head>", $html );
	$html = str_replace( '</body>', $foot . "\n</body>", $html );

	echo $html; // phpcs:ignore WordPress.Security.EscapeOutput -- fichier du thème.
}
