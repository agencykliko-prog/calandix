<?php
// Page introuvable, avec le footer du site.
status_header( 404 );
nocache_headers();
calandix_render( '404.html' );
