#!/usr/bin/env perl

use Test::More tests => 4;

BEGIN {
    use_ok('HTML::Entities');
    use_ok('WebService::Validator::HTML::W3C');
    use_ok('LWP::UserAgent');
	use_ok( 'App::ZofCMS::Plugin::Debug::Validator::HTML' );
}

diag( "Testing App::ZofCMS::Plugin::Debug::Validator::HTML $App::ZofCMS::Plugin::Debug::Validator::HTML::VERSION, Perl $], $^X" );
