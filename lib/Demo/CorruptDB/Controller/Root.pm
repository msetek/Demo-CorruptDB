package Demo::CorruptDB::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

use DateTime;
use DB_File;
#use ANYDBM_File;

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

    dbmopen(my %DB, '/tmp/corruptdb', 0666 );

    my $rand = int( rand( 100000 ) );

    my $now = DateTime->now;

    $DB{$rand} = $now;

    my $res = $DB{$rand};

    dbmclose %DB;

    my $answer;
    unless( defined($res) ) {
        $answer = "DB corruption detected: res is undef!\n";
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
