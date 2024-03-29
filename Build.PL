use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'App::ZofCMS::Plugin::Debug::Validator::HTML',
    license             => 'perl',
    dist_author         => q|Zoffix <'zoffix@cpan.org'>|,
    dist_version_from   => 'lib/App/ZofCMS/Plugin/Debug/Validator/HTML.pm',
    build_requires => {
        'Test::More' => 0,
    },
    build_recommends => {
        'App::ZofCMS::Test::Plugin' => 0.0104,
    },
    requires => {
        'HTML::Entities' => 1.35,
        'WebService::Validator::HTML::W3C' => 0.22,
        'LWP::UserAgent'                   => 2.036,
        perl                               => '5.006',
    },
    configure_requires => { 'Module::Build' => 0 },
    add_to_cleanup      => [ 'App-ZofCMS-Plugin-Debug-Validator-HTML-*' ],
    create_makefile_pl => 'traditional',
);
if ( $ENV{RELEASE_TESTING} ) {
    system('pod2text lib/App/ZofCMS/Plugin/Debug/Validator/HTML.pm > README');
}

$builder->create_build_script();
