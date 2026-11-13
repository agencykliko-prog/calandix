<?php
/**
 * Publie build/elementor-accueil.json (landing_to_elementor.py) comme page
 * d'accueil Elementor. À exécuter sur le site (Novamira « execute-php »), une
 * fois le JSON téléversé dans wp-content/cx-tmp/elementor-accueil.json.
 *
 * - classes de la landing -> classes globales Elementor (même nom) ;
 * - page « Accueil » en Elementor Canvas, définie comme page d'accueil ;
 * - attributs data-* et corrections en ligne rangés en méta (_cx_attrs, _cx_fixes)
 *   pour le thème, qui les remet au rendu.
 */

use Elementor\Modules\GlobalClasses\Global_Classes_Parser;
use Elementor\Modules\GlobalClasses\Global_Classes_Repository;

$file = WP_CONTENT_DIR . '/cx-tmp/elementor-accueil.json';
$data = json_decode( (string) file_get_contents( $file ), true );
if ( ! $data ) {
	return 'JSON introuvable ou invalide';
}
$out = [];

// ─── Classes globales ───────────────────────────────────────────────
$label_to_id = [];
foreach ( [ false, true ] as $preview ) {
	$repo    = Global_Classes_Repository::make()->set_preview( $preview );
	$current = $repo->all( true )->get();
	$items   = $current['items'];
	$order   = $current['order'];
	foreach ( $items as $item ) {
		$label_to_id[ $item['label'] ] = $item['id'];
	}
	foreach ( $data['labels'] as $label ) {
		if ( ! isset( $label_to_id[ $label ] ) ) {
			$label_to_id[ $label ] = 'g-' . substr( md5( 'calandix:' . $label ), 0, 7 );
		}
		$gid = $label_to_id[ $label ];
		if ( ! isset( $items[ $gid ] ) ) {
			$items[ $gid ] = [ 'id' => $gid, 'type' => 'class', 'label' => $label, 'variants' => [] ];
			$order[]       = $gid;
		}
	}
	$parsed = Global_Classes_Parser::make()->parse( [ 'items' => $items, 'order' => $order ] );
	if ( ! $parsed->is_valid() ) {
		$e = $parsed->errors();
		return [ 'classes_invalides' => method_exists( $e, 'to_string' ) ? $e->to_string() : print_r( $e, true ) ];
	}
	$clean = $parsed->unwrap();
	$repo->put( $clean['items'], $clean['order'] );
	$out[ $preview ? 'classes_preview' : 'classes' ] = count( $clean['items'] );
}

// Libellés -> identifiants des classes globales.
$map = function ( array $els ) use ( &$map, $label_to_id ) {
	foreach ( $els as &$el ) {
		if ( isset( $el['settings']['classes']['value'] ) ) {
			$el['settings']['classes']['value'] = array_values( array_map(
				fn( $l ) => $label_to_id[ $l ] ?? $l,
				$el['settings']['classes']['value']
			) );
		}
		$el['elements'] = $map( $el['elements'] ?? [] );
	}
	return $els;
};
$elements = $map( $data['elements'] );

// ─── Page d'accueil ─────────────────────────────────────────────────
$existing = get_posts( [
	'post_type'   => 'page',
	'post_status' => 'any',
	'meta_key'    => '_calandix_landing',
	'meta_value'  => '1',
	'numberposts' => 1,
] );
$page_id = $existing ? $existing[0]->ID : wp_insert_post( [
	'post_type'   => 'page',
	'post_status' => 'publish',
	'post_title'  => 'Accueil',
	'post_name'   => 'accueil',
] );
if ( is_wp_error( $page_id ) ) {
	return $page_id->get_error_message();
}
wp_update_post( [ 'ID' => $page_id, 'post_status' => 'publish' ] );

update_post_meta( $page_id, '_calandix_landing', '1' );
update_post_meta( $page_id, '_elementor_edit_mode', 'builder' );
update_post_meta( $page_id, '_elementor_template_type', 'wp-page' );
update_post_meta( $page_id, '_elementor_version', ELEMENTOR_VERSION );
update_post_meta( $page_id, '_wp_page_template', 'elementor_canvas' );
update_post_meta( $page_id, '_elementor_data', wp_slash( wp_json_encode( $elements ) ) );
update_post_meta( $page_id, '_cx_attrs', $data['attrs'] );
update_post_meta( $page_id, '_cx_fixes', $data['fixes'] );

update_option( 'show_on_front', 'page' );
update_option( 'page_on_front', $page_id );
// Les couleurs et polices viennent de la landing, pas des réglages par défaut.
update_option( 'elementor_disable_color_schemes', 'yes' );
update_option( 'elementor_disable_typography_schemes', 'yes' );

\Elementor\Plugin::$instance->files_manager->clear_cache();
do_action( 'litespeed_purge_all' );
@unlink( $file );

$out['page_id'] = $page_id;
$out['edit']    = admin_url( 'post.php?post=' . $page_id . '&action=elementor' );
return $out;
