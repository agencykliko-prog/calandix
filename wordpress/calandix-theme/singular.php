<?php
/**
 * Page ou article : gabarit minimal. Les pages Elementor en « Elementor
 * Canvas » utilisent le gabarit d'Elementor à la place.
 */
?><!doctype html>
<html <?php language_attributes(); ?>>
<head>
<meta charset="<?php bloginfo( 'charset' ); ?>">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title><?php echo esc_html( wp_get_document_title() ); ?></title>
<?php wp_head(); ?>
</head>
<body <?php body_class(); ?>>
<?php wp_body_open(); ?>
<main class="cx-page">
<?php
while ( have_posts() ) {
	the_post();
	the_content();
}
?>
</main>
<?php wp_footer(); ?>
</body>
</html>
