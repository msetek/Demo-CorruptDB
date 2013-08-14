package Demo::CorruptDB::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

use DateTime;
BEGIN {
    @AnyDBM_File::ISA = qw(DB_File) # Breaks 
    # @AnyDBM_File::ISA = qw(GDBM_File) # Breaks (not found on OSX)
    # @AnyDBM_File::ISA = qw(NDBM_File) # Breaks, but only sometimes. Locks up with 100% CPU usage (siege without -c) or children crash.
    # @AnyDBM_File::ISA = qw(ODBM_File) # Breaks (not found on OSX)
}
use AnyDBM_File;
use Fcntl; # needed for O_ thingies

use CHI;

use Data::Random qw(:all);
 
sub _gen_key_val;

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=encoding utf-8

=head1 NAME

Demo::CorruptDB::Controller::Root - Root Controller for Demo::CorruptDB

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    tie my %DB, 'AnyDBM_File', '/tmp/corruptdb', O_RDWR|O_CREAT, 0666;

    my ($key, $val) = _gen_key_val;

    $DB{$key} = $val;
    my $res = $DB{$key};

    untie %DB;

    $c->stash( implementation => join(', ', @AnyDBM_File::ISA) );
    $c->stash( key => $key );
    $c->stash( result => $res );

    $c->detach( 'show_answer' );


}

sub memcached :Local {
    my ( $self, $c ) = @_;
    
    my $cache = CHI->new(
	driver => 'Memcached::libmemcached',
	namespace => 'testing',
	servers => [ '127.0.0.1:11211' ]
    );

    my ($key, $val) = _gen_key_val;

    $cache->set($key, $val, 'never');
    my $res = $cache->get($key);

    $c->stash( implementation => $cache->short_driver_name );
    $c->stash( key => $key );
    $c->stash( result => $res );

    $c->detach( 'show_answer' );
}

sub _gen_key_val {
    my $key = join('', rand_words( size => 10 ) );
    $key = substr( $key, 0, 250); # memcached limitation

    my $val = $key;

    return ($key, $val);
}

sub show_answer :Private {
    my ($self, $c) = @_;

    my $implementation = $c->stash->{implementation};
    my $answer = "Testing: $implementation\n";

    my $key = $c->stash->{key};
    my $res = $c->stash->{result};

    if ( !defined($res) ) {
        $answer .= "$implementation corruption detected: res is undef!\n";
        warn "$answer";
    } elsif ( $res ne $key ) {
	$answer .= "$implementation corruption detected: incorrect data returned!\n";
        warn "$answer";
    } else {
        $answer .= "Answer from: $$ is $res";
    }

    $c->res->header( 'Content-Type' => 'text/plain' );
    $c->response->body( $answer );
}

=head2 default

Standard 404 error page

=cut

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}

=head1 AUTHOR

Martin Setek

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
