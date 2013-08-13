package Demo::CorruptDB::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

use DateTime;
BEGIN {
    # @AnyDBM_File::ISA = qw(DB_File) # Breaks
    # @AnyDBM_File::ISA = qw(GDBM_File) # Breaks
    @AnyDBM_File::ISA = qw(NDBM_File) # Breaks, but only sometimes?
    # @AnyDBM_File::ISA = qw(ODBM_File) # Breaks
}
use AnyDBM_File;
use Fcntl; # needed for O_ thingies

use CHI;

use Data::Random qw(:all);
 
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

    my $key = join(' ', rand_words( size => 120 ) );
    my $val = $key;

    $DB{$key} = $val;

    my $res = $DB{$key};

    untie %DB;

    my $answer = 'Testing: ' . join(', ', @AnyDBM_File::ISA) . "\n";
    if ( !defined($res) ) {
        $answer .= "DB corruption detected: res is undef!\n";
        print STDERR $answer;
    } elsif ( $res ne $val ) {
	$answer .= "DB corruption detected: incorrect data returned!\n";
        print STDERR $answer;
    } else {
        $answer .= "Answer from: $$ is $res";
    }

    $c->response->body( $answer );

}

sub memcached : Local :Args(0) {
    my ( $self, $c ) = @_;
    
    my $cache = CHI->new(
	driver => 'Memcached::libmemcached',
	namespace => 'testing',
	servers => [ '127.0.0.1:11211' ]
    );

    my $key = join(' ', rand_words( size => 120 ) );
    my $val = $key;

    $cache->set($key, $val, 'never');

    my $res = $cache->get($key);

    my $answer;
    if ( !defined($res) ) {
        $answer = "Cache corruption detected: res is undef!\n";
        print STDERR $answer;
    } elsif ( $res ne $val ) {
	$answer = "Cache corruption detected: incorrect data returned!\n";
        print STDERR $answer;
    } else {
        $answer = "Answer from: $$ is $res";
    }

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
