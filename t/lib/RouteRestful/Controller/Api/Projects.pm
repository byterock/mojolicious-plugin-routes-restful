package RouteRestful::Controller::Api::Projects;

use strict;
use warnings;
use Data::Dumper;
use v5.10;

my $project = {
    1 => {
        id       => 1,
        name     => 'project 1',
        type     => 'test type 1',
        owner    => 'Bloggs 1',
        users    => [ 'blogs 1', 'major 1' ],
        contacts => [ 'George 1', 'John 1', 'Paul 1', 'Ringo 1' ],
        planning => {
            name  => 'longterm 1',
            build => 1
        }
    },
    2 => {
        id       => 2,
        name     => 'project 2a',
        type     => 'test type 2a',
        owner    => 'Bloggs 2',
        users    => [ 'blogs 2', 'major 2' ],
        contacts => [ 'George 2', 'John 2', 'Paul 2', 'Ringo 2' ],
        planning => {
            name  => 'longterm 2',
            build => 2
        }
    }
};

use base 'Mojolicious::Controller';

sub create {
    my $self = shift;
    if ( $self->param('id') ) {
        return $self->render( json => { status => 404 } );
    }
    else {

        foreach my $in_key (qw(type name owner)) {
            $project->{3}->{$in_key} = $self->param($in_key);
        }
        $project->{3}->{id} = 3;

        $self->render(
            json => {
                status => 200,
                new_id => 3
            }
        );

    }

}

sub update {
    my $self = shift;

    if ( $self->param('id') ) {
        my $out = $project->{ $self->param('id') };
        foreach my $in_key (qw(type name owner)) {

            $out->{$in_key} = $self->param($in_key);
        }

        $self->render( json => { status => 200 } );
    }
    else {
        return $self->rendered(404);

    }

}

sub get {
    my $self = shift;

    my $out;
    if ( $self->param('id') ) {
        $out = $project->{ $self->param('id') };
    }
    else {
        $out = [ map { $project->{$_} } sort keys %{$project} ];
    }
    if ($out) {
        $self->render( json => $out );
    }
    else {

        return $self->rendered(404);
    }
}

sub delete {
    my $self = shift;
    if ( $self->param('id') ) {
        delete( $project->{ $self->param('id') } );

        $self->render( json => { status => 200 } );
    }
    else {
        return $self->rendered(404);

    }
}

sub details {
    my $self = shift;
    if ( $self->param('id') ) {
        my $out = $project->{ $self->param('id') };
        foreach my $in_key (qw(owner)) {
            $out->{$in_key} = $self->param($in_key);
        }
        $self->render( json => { status => 200 } );
    }
    else {
        return $self->rendered(404);

    }
}

sub longdetails {
    my $self = shift;
    if ( $self->param('id') ) {
        my $out = $project->{ $self->param('id') };
        foreach my $in_key (qw(type name)) {
            $out->{$in_key} = $self->param($in_key);
        }

        $self->render( json => { status => 200 } );
    }
    else {
        return $self->rendered(404);

    }

}

sub planning {
    my $self = shift;
    if ( $self->param('id') ) {
        my $out      = $project->{ $self->param('id') };
        my $planning = $self->param('planning');

        foreach my $in_key (qw(build name)) {

            $out->{planning}->{$in_key} =
              $planning->{headers}->{headers}->{$in_key}->[0];

        }
        $self->render( json => { status => 200 } );
    }
    else {
        return $self->rendered(404);

    }
}

sub users {
    my $self = shift;

    if ( $self->param('id') ) {

        my $out = $project->{ $self->param('id') }->{users};
        $self->render( json => $out );
    }
    else {
        return $self->rendered(404);

    }
}

sub contacts {
    my $self = shift;

    if ( $self->param('id') ) {

        my $out = $project->{ $self->param('id') }->{contacts};
        $self->render( json => $out );
    }
    else {
        return $self->rendered(404);

    }
}

1;
