package RouteRestful::Controller::Project;

use strict;
use warnings;
use v5.10;

use base 'Mojolicious::Controller';

my %project = {1=>{ id=>1,
                    name=>'project 1',
                    type=>'test type 1',
                    owner=>'Bloggs 1',
                    users=>['blogs 1','major 1'],
                    contacts=>['George 1','John 1','Paul 1','Ringo 1'],
                    planning=>{name=>'longterm 1',
                                build=>1}},
                2=>{ id=>2,
                    name=>'project 2',
                    type=>'test type 2',
                    owner=>'Bloggs 2',
                    users=>['blogs 2','major 2'],
                    contacts=>['George 2','John 2','Paul 2','Ringo 2'],
                    planning=>{name=>'longterm 2',
                                build=>2}}};

sub show {
   
   my $self = shift;
   $self->stash(
        id        => $self->param('id'),
        project   => $project{ $self->param('id')},
    );
    $self->render('/project/show');

}

sub detail {
    my $self = shift;
 $self->stash(
        id        => $self->param('id'),
        project   => $project{ $self->param('id')},
    );
    $self->render('project/detail');
}

sub longdetail {
    my $self = shift;
    
    $self->stash(
        id        => $self->param('id'),
        project   => $project{ $self->param('id')},
    );
    $self->render('project/longdetail');
}

sub planning {
    my $self = shift;
     $self->stash(
        id        => $self->param('id'),
        project   => $project{ $self->param('id')},
    );
    $self->render('project/planning');
}

sub user {
    my $self = shift;
      $self->stash(
        id        => $self->param('id'),
        project   => $project{ $self->param('id')},
    );
    $self->render('project/user');
}

sub contact {
    my $self = shift;
  
     $self->stash(
        id        => $self->param('id'),
        project   => $project{ $self->param('id')},
    );
    $self->render('project/contact');
}
1;