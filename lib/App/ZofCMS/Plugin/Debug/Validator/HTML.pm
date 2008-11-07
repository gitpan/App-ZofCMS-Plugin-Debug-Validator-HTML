package App::ZofCMS::Plugin::Debug::Validator::HTML;

use warnings;
use strict;

our $VERSION = '0.0101';

use WebService::Validator::HTML::W3C;
use LWP::UserAgent;

sub new { bless {}, shift }

sub process {
    my ( $self, $template, $query, $config ) = @_;

    my %conf = (
        t_name          => 'plug_val_html',
        q_name          => 'plug_val_html',
        validator_uri   => 'http://127.0.0.1/w3c-markup-validator/check',

        %{ delete $config->conf->{plug_validator_html} || {} },
        %{ delete $template->{plug_validator_html}     || {} },
    );
    unless ( defined $conf{address} ) {
        my $query_string = $ENV{QUERY_STRING};
        $query_string =~ s/&?\Q$conf{q_name}=\E[^&]+//g;
        $conf{address} = 'http://' . $ENV{SERVER_NAME}
            . $ENV{SCRIPT_NAME} . '?' . $query_string;
    }

    return
        unless $query->{ $conf{q_name} };

    my $response = LWP::UserAgent->new->get( $conf{address} );
    unless ( $response->is_success ) {
        $template->{t}{ $conf{t_name} }
        = "Error fetching your page: [$conf{address}] " . $response->status_line;
        return;
    }

    my $val = WebService::Validator::HTML::W3C->new(
        detailed        => 1,
        validator_uri   => $conf{validator_uri},
        timeout         => 30,
    );

    unless ( $val->validate_markup( $response->content ) ) {
        $template->{t}{ $conf{t_name} } = 'Validator error: ' . $val->validator_error;
        return;
    }
    my $num_errors = $val->num_errors;

    unless ( $num_errors ) {
        $template->{t}{ $conf{t_name} } = 'HTML is valid';
        return;
    }

    my @out = ( "Invalid: <b>$num_errors</b> errors" );

    foreach my $error ( @{ $val->errors } ) {
        push @out, sprintf "line: %s, col: %s, error: %s",
                map $error->$_, qw/line col msg/;
    }

    $template->{t}{ $conf{t_name} } = join "\n", map "<p>$_</p>", @out;

    return;
}

1;
__END__

=head1 NAME

App::ZofCMS::Plugin::Debug::Validator::HTML - debugging plugin for auto validating HTML

=head1 SYNOPSIS

In your Main Config file or ZofCMS Template:

    plugins => [ 'Debug::Validator::HTML' ]

In your L<HTML::Template> template:

    <tmpl_var name="plug_val_html">

Access your page with L<http://your.domain.com/index.pl?page=/test&plug_val_html=1>

Read the validation results \o/

=head1 DESCRIPTION

The module is a B<debugging> plugin for L<App::ZofCMS> that provides means to validate the HTML
code that you are writing on the spot.

This documentation assumes you've read L<App::ZofCMS>, L<App::ZofCMS::Config> and L<App::ZofCMS::Template>

=head1 MAIN CONFIG FILE AND ZofCMS TEMPLATE FIRST-LEVEL KEYS

=head2 C<plugins>

    plugins => [ qw/Debug::Validator::HTML/ ],

You need to include the plugin in the list of plugins to be executed.

=head2 C<plug_validator_html>

    # everything is optional
    plug_validator_html => {
        t_name          => 'plug_val_html',
        q_name          => 'plug_val_html',
        validator_uri   => 'http://127.0.0.1/w3c-markup-validator/check',
        address         => 'http://your.site.com/index.pl?page=/test', 
    }

The plugin takes its optional configuration from C<plug_validator_html> first-level key that
takes a hashref as a value. Plugin will B<still run> even if C<plug_validator_html> key
is not present. You can set any of the config options in either Main Config File or ZofCMS
Template file. Whatever you set in ZofCMS Template file will override the same key if
it was set in Main Config File. Possible keys/values are as follows:

=head3 C<t_name>

    t_name => 'plug_val_html',

B<Optional>. The plugin sets validation results in one of the keys in the C<{t}> special key.
The C<t_name> argument specifies the name of that key. See C<HTML::Template VARIABLES> section
below for details. B<Defaults to:> C<plug_val_html>

=head3 C<q_name>

    q_name => 'plug_val_html',

B<Optional>. To trigger the execution of the plugin you need to pass a query parameter that
is set to a true value. This is to speed up normal development process (because
you don't really want to validate on every refresh) but most importantly it is to prevent
infinite loops where the plugin will try to execute itself while fetching your HTML for
validation. See C<SYNOPSIS> section for example
on how to trigger the validator with this query parameter. B<Defaults to:> C<plug_val_html>

=head3 C<validator_uri>

    validator_uri   => 'http://127.0.0.1/w3c-markup-validator/check',

B<Optional>.
Plugin accesses a W3C markup validator. The C<validator_uri> argument takes a URI pointing
to the validator. It would be REALLY GREAT if you'd download the
validator for your system and use a local version. Debian/Ubuntu users can do it
as simple as C<sudo apt-get install w3c-markup-validator>,
others see L<http://validator.w3.org/source/>. If you cannot install a local version
of the validator set C<validator_uri> to L<http://validator.w3.org/check>. B<Defaults to:>
C<http://127.0.0.1/w3c-markup-validator/check>

=head3 C<address>

    address => 'http://your.site.com/index.pl?page=/test',

B<Optional>. The plugin uses needs to fetch your page in order to get the markup to validate.
Generally you don't need to touch C<address> argument as the plugin will do its black magic
to figure out, but in case it fails you can set it or wish to validate some other page
that is not the one on which you are displaying the results, you can set the C<address>
argument that takes a string that is the URI to the page you wish to validate.

=head1 HTML::Template VARIABLES

    <tmpl_var name='plug_val_html'>

The plugin sets only one L<HTML::Template> variable; its name is what you set in
C<t_name> argument, which defaults to C<plug_val_html>.

If your HTML code is valid, this variable will be replaced with words C<HTML is valid>.
Otherwise you'll see either an error message for why validation failed or actual error
messages that explain why your HTML is invalid.

=head1 USAGE NOTES

You'd probably would want to include the plugin to execute in your Main Config File
and put the C<< <tmpl_var name=""> >> in your base template while developing the site.
Just don't forget to take it out when you done ;)

PLEASE! Install a local validator. Tons of people already accessing the one that is hosted
in C<http://w3.org>, don't make the lag worse.

=head1 AUTHOR

'Zoffix, C<< <'zoffix at cpan.org'> >>
(L<http://zoffix.com/>, L<http://haslayout.net/>, L<http://zofdesign.com/>)

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-zofcms-plugin-debug-validator-html at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-ZofCMS-Plugin-Debug-Validator-HTML>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::ZofCMS::Plugin::Debug::Validator::HTML

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-ZofCMS-Plugin-Debug-Validator-HTML>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-ZofCMS-Plugin-Debug-Validator-HTML>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-ZofCMS-Plugin-Debug-Validator-HTML>

=item * Search CPAN

L<http://search.cpan.org/dist/App-ZofCMS-Plugin-Debug-Validator-HTML>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 'Zoffix, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
