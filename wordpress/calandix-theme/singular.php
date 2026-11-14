<?php
/**
 * Page ou article : à propos, contact, pages légales… Les pages Elementor en
 * « Elementor Canvas » utilisent le gabarit d'Elementor à la place.
 */

$uri   = calandix_landing_uri();
$links = [
	'/'                 => 'Accueil',
	'/a-propos/'        => 'À propos',
	'/contact/'         => 'Contact',
	'/conditions/'      => 'Conditions générales',
	'/confidentialite/' => 'Confidentialité',
];
?><!doctype html>
<html <?php language_attributes(); ?>>
<head>
<meta charset="<?php bloginfo( 'charset' ); ?>">
<meta name="viewport" content="width=device-width, initial-scale=1">
<link rel="icon" type="image/png" href="<?php echo esc_url( $uri . 'img/favicon.png' ); ?>">
<style>
@font-face { font-family: "Red Hat Display"; font-weight: 500; font-display: swap; src: url("<?php echo esc_url( $uri . 'fonts/RedHatDisplay-500.woff2' ); ?>") format("woff2"); }
@font-face { font-family: "Red Hat Display"; font-weight: 800; font-display: swap; src: url("<?php echo esc_url( $uri . 'fonts/RedHatDisplay-800.woff2' ); ?>") format("woff2"); }
:root { --ink: #1A0637; --muted: #5E5373; --violet: #4D39E2; --line: #E8E3F0; --bg: #F7F5F2; }
* { box-sizing: border-box; }
body { margin: 0; background: var(--bg); color: var(--ink); font: 500 17px/1.65 "Red Hat Display", system-ui, sans-serif; }
a { color: var(--violet); text-underline-offset: 3px; }
::selection { background: #4D39E2; color: #fff; }
.cx-top, .cx-foot { max-width: 760px; margin: 0 auto; padding: 22px 20px; display: flex; flex-wrap: wrap; gap: 10px 18px; align-items: center; }
.cx-top { justify-content: space-between; }
.cx-top img { width: 150px; height: auto; display: block; }
.cx-top .cta { padding: 10px 18px; border-radius: 99px; background: var(--violet); color: #fff; font-weight: 800; text-decoration: none; }
main { max-width: 760px; margin: 0 auto; padding: 20px 20px 56px; }
main article { background: #fff; border: 1px solid var(--line); border-radius: 24px; padding: clamp(22px, 5vw, 44px); }
h1 { font-weight: 800; font-size: clamp(30px, 6vw, 44px); line-height: 1.12; letter-spacing: -0.03em; margin: 0 0 18px; text-wrap: balance; }
h2 { font-weight: 800; font-size: 21px; line-height: 1.3; margin: 32px 0 8px; }
p, li { max-width: 68ch; }
.lead { color: var(--muted); }
ul { padding-left: 1.2em; }
li { margin: 4px 0; }
.cx-foot { border-top: 1px solid var(--line); font-size: 15px; }
.cx-foot a { color: var(--muted); }
.cx-foot small { width: 100%; color: var(--muted); }
</style>
<?php wp_head(); ?>
</head>
<body <?php body_class( 'cx-page' ); ?>>
<?php wp_body_open(); ?>
<header class="cx-top">
	<a href="<?php echo esc_url( home_url( '/' ) ); ?>" aria-label="Calandix, accueil"><img src="<?php echo esc_url( $uri . 'img/calandix-logo.svg' ); ?>" width="760" height="124" alt="Calandix"></a>
	<a class="cta" href="<?php echo esc_url( home_url( '/app/' ) ); ?>">Essayer Calandix</a>
</header>
<main>
<?php
while ( have_posts() ) {
	the_post();
	echo '<article><h1>' . esc_html( get_the_title() ) . '</h1>';
	the_content();
	echo '</article>';
}
?>
</main>
<footer class="cx-foot">
	<?php foreach ( $links as $path => $label ) : ?>
		<a href="<?php echo esc_url( home_url( $path ) ); ?>"><?php echo esc_html( $label ); ?></a>
	<?php endforeach; ?>
	<small>© <?php echo esc_html( gmdate( 'Y' ) ); ?> Calandix · Calandix est un service délivré par TOOTEBO</small>
</footer>
<?php wp_footer(); ?>
</body>
</html>
