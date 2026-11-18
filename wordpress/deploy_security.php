<?php
/**
 * calandix.com · en-têtes de sécurité et fichiers sensibles au niveau du
 * serveur (audit OWASP du 18 nov. 2026). À exécuter sur le site (Novamira
 * « execute-php »). Sans risque, peut être relancé : le bloc est remplacé.
 *
 * Le thème (inc/security.php) pose les mêmes en-têtes sur les pages PHP ;
 * ce bloc couvre aussi les fichiers statiques (application sous /app/,
 * images, scripts) qui ne passent pas par WordPress.
 */

$ht    = ABSPATH . '.htaccess';
$rules = implode( "\n", [
	'# BEGIN Calandix securite',
	'<IfModule mod_headers.c>',
	'Header always set X-Content-Type-Options "nosniff"',
	'Header always set X-Frame-Options "SAMEORIGIN"',
	'Header always set Referrer-Policy "strict-origin-when-cross-origin"',
	'Header always set Permissions-Policy "camera=(), microphone=(), geolocation=(), payment=(), usb=(), interest-cohort=()"',
	'Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"',
	'Header always unset X-Powered-By',
	'Header unset X-Powered-By',
	'</IfModule>',
	'# XML-RPC (force brute), version de WordPress, sauvegardes et journaux : jamais servis.',
	'<FilesMatch "^(xmlrpc\.php|readme\.html|license\.txt|wp-config-sample\.php|\.htaccess\.bak.*|.*\.(bak|old|orig|sql|log|swp))$">',
	'Require all denied',
	'</FilesMatch>',
	'Options -Indexes',
	'# END Calandix securite',
] );

$cur = (string) file_get_contents( $ht );
if ( ! file_exists( $ht . '.bak-securite' ) ) {
	copy( $ht, $ht . '.bak-securite' );
}
$cur = preg_replace( '/# BEGIN Calandix securite.*?# END Calandix securite\n*/s', '', $cur );
// Après le bloc des agents s'il existe, sinon en tête de fichier.
if ( str_contains( $cur, '# END Calandix agents' ) ) {
	$cur = str_replace( "# END Calandix agents\n", "# END Calandix agents\n\n" . $rules . "\n", $cur );
} else {
	$cur = $rules . "\n\n" . $cur;
}
$before = (string) file_get_contents( $ht );
$ok     = false !== file_put_contents( $ht, $cur );

// Contrôle : si le site ou l'application ne répondent plus, on revient à
// l'état précédent.
$check = function ( string $path ) {
	$r = wp_remote_get( home_url( $path ), [ 'timeout' => 15, 'redirection' => 0, 'sslverify' => true ] );
	return is_wp_error( $r ) ? 0 : (int) wp_remote_retrieve_response_code( $r );
};
$home = $check( '/' );
$app  = $check( '/app/' );
if ( 200 !== $home || 200 !== $app ) {
	file_put_contents( $ht, $before );
	return [ 'htaccess' => 'annulé', 'accueil' => $home, 'app' => $app ];
}
do_action( 'litespeed_purge_all' );
return [ 'htaccess' => $ok ? 'ok' : 'échec', 'accueil' => $home, 'app' => $app ];
