<?php
// Accueil : la page choisie dans Réglages › Lecture (Elementor), sinon la
// landing statique.
if ( is_page() ) {
	get_template_part( 'singular' );
	return;
}
calandix_render( 'index.html' );
