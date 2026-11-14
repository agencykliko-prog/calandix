<?php
/**
 * Met à jour UNE section de la page d'accueil Elementor à partir de
 * build/elementor-accueil.json, sans toucher au reste de la page (les
 * modifications faites dans Elementor ailleurs sont conservées).
 *
 * À exécuter sur le site (Novamira « execute-php »), le JSON déposé dans
 * wp-content/cx-tmp/elementor-accueil.json. Réglages ci-dessous :
 * - $section : identifiant CSS (#) de la section à remplacer ;
 * - $texts   : remplacements de texte ailleurs dans la page (avant => après).
 */

use Elementor\Modules\GlobalClasses\Global_Classes_Parser;
use Elementor\Modules\GlobalClasses\Global_Classes_Repository;

$section = 'tarifs';
$texts   = [
	'Commission de <b>6 % à 2 %</b> selon la formule, 14 jours d’essai.' =>
		'Commission de <b>6 % à 2 %</b> selon la formule, 7 jours d’essai sur Creator et Business.',
	'5 % en Starter (3 000 FCFA / mois), 4 % en Creator (5 900 FCFA / mois) et 2 % en Business (9 900 FCFA / mois)' =>
		'5 % en Starter (5 000 FCFA / mois), 4 % en Creator (10 000 FCFA / mois) et 2 % en Business (15 000 FCFA / mois)',
];

$page = (int) get_option( 'page_on_front' );
if ( ! get_post_meta( $page, '_calandix_landing', true ) ) {
	return 'La page d’accueil n’est pas la page Calandix';
}
$file = WP_CONTENT_DIR . '/cx-tmp/elementor-accueil.json';
$new  = json_decode( (string) file_get_contents( $file ), true );
$live = json_decode( (string) get_post_meta( $page, '_elementor_data', true ), true );
if ( ! $new || ! $live ) {
	return 'Données illisibles';
}

$is_section = fn( $el ) => ( $el['settings']['_cssid']['value'] ?? null ) === $section;

// Section dans la nouvelle conversion.
$find = function ( array $els ) use ( &$find, $is_section ) {
	foreach ( $els as $el ) {
		if ( $is_section( $el ) ) {
			return $el;
		}
		$hit = $find( $el['elements'] ?? [] );
		if ( $hit ) {
			return $hit;
		}
	}
	return null;
};
$fresh = $find( $new['elements'] );
if ( ! $fresh ) {
	return 'Section introuvable dans le JSON';
}

// Identifiants déjà pris sur la page en ligne.
$taken   = [];
$collect = function ( array $els ) use ( &$collect, &$taken ) {
	foreach ( $els as $el ) {
		$taken[ $el['id'] ] = true;
		$collect( $el['elements'] ?? [] );
	}
};
$collect( $live );

// Classes globales : libellés -> identifiants, en créant les nouvelles.
$label_to_id = [];
$labels      = [];
$walk_labels = function ( array $els ) use ( &$walk_labels, &$labels ) {
	foreach ( $els as $el ) {
		foreach ( $el['settings']['classes']['value'] ?? [] as $l ) {
			$labels[ $l ] = true;
		}
		$walk_labels( $el['elements'] ?? [] );
	}
};
$walk_labels( [ $fresh ] );
foreach ( [ false, true ] as $preview ) {
	$repo    = Global_Classes_Repository::make()->set_preview( $preview );
	$current = $repo->all( true )->get();
	$items   = $current['items'];
	$order   = $current['order'];
	foreach ( $items as $item ) {
		$label_to_id[ $item['label'] ] = $item['id'];
	}
	$added = false;
	foreach ( array_keys( $labels ) as $label ) {
		$gid = $label_to_id[ $label ] ?? 'g-' . substr( md5( 'calandix:' . $label ), 0, 7 );
		$label_to_id[ $label ] = $gid;
		if ( ! isset( $items[ $gid ] ) ) {
			$items[ $gid ] = [ 'id' => $gid, 'type' => 'class', 'label' => $label, 'variants' => [] ];
			$order[]       = $gid;
			$added         = true;
		}
	}
	if ( $added ) {
		$parsed = Global_Classes_Parser::make()->parse( [ 'items' => $items, 'order' => $order ] );
		if ( ! $parsed->is_valid() ) {
			return 'Classes globales invalides';
		}
		$clean = $parsed->unwrap();
		$repo->put( $clean['items'], $clean['order'] );
	}
}

// Nouveaux identifiants (sans collision), classes en identifiants globaux,
// attributs et corrections en ligne reportés sur les nouveaux identifiants.
$attrs  = (array) get_post_meta( $page, '_cx_attrs', true );
$fixes  = (array) get_post_meta( $page, '_cx_fixes', true );
$rename = function ( array $el ) use ( &$rename, &$taken, $label_to_id, $new, &$attrs, &$fixes ) {
	$old = $el['id'];
	do {
		$id = substr( md5( $old . wp_rand() ), 0, 7 );
	} while ( isset( $taken[ $id ] ) );
	$taken[ $id ] = true;
	$el['id']     = $id;
	if ( isset( $el['settings']['classes']['value'] ) ) {
		$el['settings']['classes']['value'] = array_values( array_map(
			fn( $l ) => $label_to_id[ $l ] ?? $l,
			$el['settings']['classes']['value']
		) );
	}
	if ( isset( $new['attrs'][ $old ] ) ) {
		$attrs[ $id ] = $new['attrs'][ $old ];
	}
	if ( isset( $new['fixes'][ $old ] ) ) {
		$fixes[ $id ] = $new['fixes'][ $old ];
	}
	$el['elements'] = array_map( $rename, $el['elements'] ?? [] );
	return $el;
};
$fresh = $rename( $fresh );

// Remplacement de la section, et des textes ailleurs.
$swapped = 0;
$replace = function ( array $els ) use ( &$replace, $is_section, $fresh, &$swapped, &$attrs, &$fixes ) {
	foreach ( $els as $i => $el ) {
		if ( $is_section( $el ) ) {
			// Les attributs de l'ancienne section ne servent plus.
			$drop = function ( array $e ) use ( &$drop, &$attrs, &$fixes ) {
				unset( $attrs[ $e['id'] ], $fixes[ $e['id'] ] );
				array_map( $drop, $e['elements'] ?? [] );
			};
			$drop( $el );
			$els[ $i ] = $fresh;
			++$swapped;
			continue;
		}
		$els[ $i ]['elements'] = $replace( $el['elements'] ?? [] );
	}
	return $els;
};
$live = $replace( $live );
if ( 1 !== $swapped ) {
	return 'Section « ' . $section . ' » trouvée ' . $swapped . ' fois sur la page';
}

$done = [];
array_walk_recursive( $live, function ( &$v ) use ( $texts, &$done ) {
	if ( ! is_string( $v ) ) {
		return;
	}
	foreach ( $texts as $from => $to ) {
		if ( str_contains( $v, $from ) ) {
			$v           = str_replace( $from, $to, $v );
			$done[ $from ] = true;
		}
	}
} );

update_post_meta( $page, '_elementor_data', wp_slash( wp_json_encode( $live ) ) );
update_post_meta( $page, '_cx_attrs', $attrs );
update_post_meta( $page, '_cx_fixes', $fixes );
\Elementor\Plugin::$instance->files_manager->clear_cache();
do_action( 'litespeed_purge_all' );
@unlink( $file );

return [
	'section'  => $section,
	'textes'   => count( $done ) . ' / ' . count( $texts ),
	'page'     => $page,
];
