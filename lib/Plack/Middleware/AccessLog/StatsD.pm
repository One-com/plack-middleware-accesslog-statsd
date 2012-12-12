package Plack::Middleware::AccessLog::StatsD;

use strict;
use warnings;

use parent qw(Plack::Middleware::EasyHooks);

our $VERSION = '0.01';

sub before {
    my ($self, $env) = @_;

    $env->{'statsd.start_time'} = [Time::HiRes::gettimeofday()];
    $env->{'statsd.length'}     = 0;
}

sub after {
    my ($self, $env, $res) = @_;

    $env->{'statsd.status'} = $res->[0];
}

sub filter {
    my ($self, $env, $chunk) = @_;

    $env->{'statsd.length'} += length $chunk;
    return $chunk;
}

my %methods = map { $_ => 1 } qw( copy delete get head lock mkcol move options post propfind proppatch put search unlock );
sub finalize {
    my ($self, $env) = @_;

    # Sanity check of method name to avoid spamming the StatsD server
    return unless $env->{REQUEST_METHOD} =~ /^[A-Z]{1,16}$/;

    my $socket = IO::Socket::INET->new(
        Proto => 'udp',
        PeerAddr => $self->{host},
        PeerPort => $self->{port} // 8125,
    ) or return;
    
    my $prefix = $self->{prefix};
    my $method = lc( $env->{REQUEST_METHOD} );
    my $status = $env->{'statsd.status'};
    my $length = $env->{'statsd.length'};
    my $time   = int( tv_interval( $env->{'statsd.start_time'} ) * 1000 );

    $prefix =~ /[.]?$/./ if $prefix;

    $socket->send( $prefix."response.$status:1|c" );
    $socket->send( $prefix."response_time.$method:$time|ms" );
    $socket->send( $prefix."response_size.$method:$length|ms" );
}

1;

__END__

=head1 NAME

Plack::Middleware::AccessLog::StatsD - Logs requests to StatsD server

=head1 SYNOPSIS

    #in app.psgi
    use Plack::Builder;

    builder {
        enable "Plack::Middleware::AccessLog::StatsD",
            host   => 'statsd.example.net',
            port   => 8125,
            prefix => 'my_app';

        $app;
    };

=head1 DESCRIPTION

Plack::Middleware::AccessLog::StatsD logs information about individual
requests to a StatsD server. Currently the following metrics are logged:

=over 4

=item <prefix>.response.<status> (counter)

=item <prefix>.response_time.<method> (timer)

=item <prefix>.response_time.<method> (timer)

=back

=head1 CONFIGURATION

The following configuration parameters are available:

=over 4

=item host

Hostname for the StatsD server

=item port (default: 8125)

Port the StatsD server is listeneing on

=item prefix

Prefix for the keys added to StatsD

=back

=head1 SEE ALSO

L<https://github.com/etsy/statsd>

=head1 AUTHOR

Peter Makholm E<lt>peter@makholm.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Peter Makholm.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


