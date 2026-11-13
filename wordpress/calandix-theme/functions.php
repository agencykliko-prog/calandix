<?php
/**
 * Thème Calandix : sert la landing statique (dossier landing/) comme pages
 * WordPress, en gardant wp_head() et wp_footer() pour les extensions (SEO,
 * statistiques, cache).
 */

defined( 'ABSPATH' ) || exit;

add_action( 'after_setup_theme', function () {
	// La landing porte déjà son <title> et ses métadonnées.
	remove_action( 'wp_head', 'print_emoji_detection_script', 7 );
	remove_action( 'wp_print_styles', 'print_emoji_styles' );
	remove_action( 'wp_head', 'wp_generator' );
} );

// Pas de styles de blocs inutiles sur une page entièrement sur mesure.
add_action( 'wp_enqueue_scripts', function () {
	wp_dequeue_style( 'wp-block-library' );
	wp_dequeue_style( 'global-styles' );
	wp_dequeue_style( 'classic-theme-styles' );
}, 100 );

/**
 * Affiche un fichier HTML de landing/ : chemins des fichiers vers le thème,
 * adresse du site à la place de l'ancien domaine, hooks WordPress injectés.
 */
function calandix_render( string $file ): void {
	$dir  = get_template_directory() . '/landing/';
	$uri  = get_template_directory_uri() . '/landing/';
	$html = (string) file_get_contents( $dir . $file );

	$html = preg_replace( '#(src|href)="/?(img|fonts)/#', '$1="' . $uri . '$2/', $html );
	$html = preg_replace( '#(src|href)="/?(styles\.css|app\.js|boot\.js|phone3d\.js)#', '$1="' . $uri . '$2', $html );
	$html = str_replace( 'https://eventa.ci/img/', $uri . 'img/', $html );
	$html = str_replace( 'https://eventa.ci/', home_url( '/' ), $html );
	// Les scripts lisent ce préfixe pour charger mascottes, FAQ et 3D.
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
