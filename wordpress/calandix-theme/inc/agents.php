<?php
/**
 * Calandix pour les agents et outils d'IA.
 *
 * - robots.txt : Content-Signal et plan du site ;
 * - /sitemap.xml : liste des pages publiques ;
 * - accueil : version Markdown (Accept: text/markdown), en-tête Link vers
 *   llms.txt et le Markdown, données structurées (agents/jsonld.json) ;
 * - outils WebMCP déclarés dans la page (assets/agents.js).
 *
 * llms.txt et index.md sont copiés à la racine du site au déploiement
 * (fichiers statiques : servis même quand le cache répond).
 */

defined( 'ABSPATH' ) || exit;

/** Usage des contenus : recherche et réponses oui, entraînement non. */
const CALANDIX_CONTENT_SIGNAL = 'search=yes, ai-input=yes, ai-train=no';

/** Pages publiques listées dans le plan du site (slug => priorité). */
const CALANDIX_PUBLIC_PAGES = [
	''                 => '1.0',
	'a-propos/'        => '0.6',
	'contact/'         => '0.6',
	'conditions/'      => '0.4',
	'confidentialite/' => '0.4',
	'app/'             => '0.5',
];

// ─── robots.txt ─────────────────────────────────────────────────────────
add_filter(
	'robots_txt',
	function ( $output ) {
		if ( ! str_contains( $output, 'Content-Signal:' ) ) {
			$line   = 'Content-Signal: ' . CALANDIX_CONTENT_SIGNAL;
			$output = preg_match( '/^User-agent:\s*\*\s*$/mi', $output )
				? preg_replace( '/^(User-agent:\s*\*\s*)$/mi', "$1\n$line", $output, 1 )
				: "User-agent: *\n$line\nAllow: /\n\n" . $output;
		}
		$sitemap = home_url( '/sitemap.xml' );
		if ( ! str_contains( $output, $sitemap ) ) {
			$output = rtrim( $output ) . "\n\nSitemap: $sitemap\n";
		}
		return $output;
	},
	PHP_INT_MAX
);

// ─── /sitemap.xml ───────────────────────────────────────────────────────
add_action(
	'init',
	function () {
		$path = wp_parse_url( $_SERVER['REQUEST_URI'] ?? '', PHP_URL_PATH ); // phpcs:ignore
		if ( '/sitemap.xml' !== $path ) {
			return;
		}
		$urls = [];
		foreach ( CALANDIX_PUBLIC_PAGES as $slug => $priority ) {
			$mod = null;
			if ( '' === $slug ) {
				$mod = get_post_modified_time( 'c', true, (int) get_option( 'page_on_front' ) );
			} elseif ( 'app/' !== $slug ) {
				$page = get_page_by_path( rtrim( $slug, '/' ) );
				if ( ! $page || 'publish' !== $page->post_status ) {
					continue;
				}
				$mod = get_post_modified_time( 'c', true, $page );
			}
			$urls[] = '<url><loc>' . esc_url( home_url( '/' . $slug ) ) . '</loc>'
				. ( $mod ? '<lastmod>' . esc_html( $mod ) . '</lastmod>' : '' )
				. '<priority>' . $priority . '</priority></url>';
		}
		status_header( 200 );
		header( 'Content-Type: application/xml; charset=UTF-8' );
		header( 'X-Robots-Tag: noindex' );
		echo '<?xml version="1.0" encoding="UTF-8"?>' . "\n"
			. '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">' . implode( '', $urls ) . '</urlset>';
		exit;
	},
	0
);

// ─── Accueil : Markdown, en-têtes, données structurées ──────────────────

/** L'agent demande du Markdown plutôt que du HTML. */
function calandix_wants_markdown(): bool {
	$accept = strtolower( $_SERVER['HTTP_ACCEPT'] ?? '' ); // phpcs:ignore
	return str_contains( $accept, 'text/markdown' ) || str_contains( $accept, 'text/x-markdown' );
}

function calandix_agent_links(): string {
	return '<' . home_url( '/llms.txt' ) . '>; rel="describedby"; type="text/plain", '
		. '<' . home_url( '/index.md' ) . '>; rel="alternate"; type="text/markdown"';
}

add_action(
	'template_redirect',
	function () {
		if ( ! is_front_page() ) {
			return;
		}
		header( 'Link: ' . calandix_agent_links(), false );
		header( 'Vary: Accept', false );
		if ( ! calandix_wants_markdown() ) {
			return;
		}
		$file = get_template_directory() . '/agents/index.md';
		if ( ! is_readable( $file ) ) {
			return;
		}
		do_action( 'litespeed_control_set_nocache', 'version Markdown pour les agents' );
		status_header( 200 );
		header( 'Content-Type: text/markdown; charset=UTF-8' );
		readfile( $file ); // phpcs:ignore
		exit;
	},
	1
);

add_action(
	'wp_head',
	function () {
		if ( ! is_front_page() ) {
			return;
		}
		echo '<link rel="alternate" type="text/markdown" href="' . esc_url( home_url( '/index.md' ) ) . '">' . "\n";
		echo '<link rel="describedby" type="text/plain" href="' . esc_url( home_url( '/llms.txt' ) ) . '">' . "\n";
		$json = get_template_directory() . '/agents/jsonld.json';
		if ( is_readable( $json ) ) {
			$data = json_decode( (string) file_get_contents( $json ), true );
			if ( $data ) {
				echo '<script type="application/ld+json">'
					. wp_json_encode( $data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES )
					. "</script>\n";
			}
		}
	},
	2
);

// L'ancien bloc SoftwareApplication de la landing est remplacé par le graphe.
add_filter(
	'calandix_landing_head',
	fn( $head ) => preg_replace( '#<script type="application/ld\+json">.*?</script>#s', '', $head )
);

// Scripts du thème chargés dès l'affichage (pas de report par LiteSpeed) :
// les outils WebMCP doivent être déclarés au chargement de la page.
$calandix_keep = function ( $attrs ) {
	if ( isset( $attrs['id'] ) && str_starts_with( (string) $attrs['id'], 'calandix-' ) ) {
		$attrs['data-no-optimize'] = '1';
		$attrs['data-no-defer']    = '1';
	}
	return $attrs;
};
add_filter( 'wp_script_attributes', $calandix_keep );
add_filter( 'wp_inline_script_attributes', $calandix_keep );

// Outils WebMCP pour les agents intégrés au navigateur.
add_action(
	'wp_enqueue_scripts',
	function () {
		if ( ! is_front_page() || calandix_is_editor_preview() ) {
			return;
		}
		wp_enqueue_script(
			'calandix-agents',
			get_template_directory_uri() . '/assets/agents.js',
			[],
			wp_get_theme()->get( 'Version' ),
			[ 'strategy' => 'defer', 'in_footer' => true ]
		);
		wp_add_inline_script(
			'calandix-agents',
			'window.CX_AGENTS=' . wp_json_encode( [
				'faq'    => calandix_landing_uri() . 'candix-faq.json',
				'app'    => home_url( '/app/' ),
				'pages'  => array_map( fn( $s ) => home_url( '/' . $s ), array_keys( CALANDIX_PUBLIC_PAGES ) ),
			] ) . ';',
			'before'
		);
	}
);
