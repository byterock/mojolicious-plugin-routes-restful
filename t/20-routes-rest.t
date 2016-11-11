use Test::More;
use Test::Mojo;
use lib 't/lib';

my $module = 'Mojolicious::Plugin::Routes::Restful';
use_ok($module);

my $t = Test::Mojo->new("RouteRestful");

my $routes = $t->app->routes;

use Data::Dumper;

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
    update1 => {
        name  => 'project 1a',
        type  => 'test type 1a',
        owner => 'Bloggs 12',
    },
    update_result1 => {
        id       => 1,
        name     => 'project 1a',
        type     => 'test type 1a',
        contacts => [ 'George 1', 'John 1', 'Paul 1', 'Ringo 1' ],
        owner    => 'Bloggs 12',
        users    => [ 'blogs 1', 'major 1' ],
        planning => {
            name  => 'longterm 1',
            build => '1'
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
            build => '2'
        }
    }
};

my $project_new = {
    name  => 'project 3',
    type  => 'test type 3',
    owner => 'Bloggs 3',
};

#check the non API gets

$t->get_ok("/project")->status_is(200)->content_is('show all');
$t->get_ok("/project/1")->status_is(200)->content_is('show for 1');
$t->get_ok("/project/2")->status_is(200)->content_is('show for 2');    #
$t->get_ok("/project/1/longdetail")->status_is(200)
  ->content_is('longdetail for 1');#
$t->get_ok("/project/1/detail")->status_is(200)->content_is('detail for 1');
$t->get_ok("/project/1/planning")->status_is(200)
  ->content_is('all plans for project=1');
$t->get_ok("/project/1/user")->status_is(200)
  ->content_is('all users for project=1');#
$t->get_ok("/project/1/user/1")->status_is(200)
  ->content_is('user=1, for project=1');#
$t->get_ok("/project/2/user/2")->status_is(200)
  ->content_is('user=2, for project=2');#
$t->get_ok("/project/1/contact")->status_is(200)
  ->content_is('all contacts for project=1');#
$t->get_ok("/project/1/contact/1")->status_is(200)
  ->content_is('contact=1, for project=1');#
$t->get_ok("/project/1/contact/2")->status_is(200)->content_is('contact=2, for project=1');#

#and now the API routes

$t->get_ok("/projects")->status_is(200)->json_is( '/1' => $project->{2} );
$t->get_ok("/projects/1")->status_is(200)->json_is( $project->{1} );#
$t->put_ok( "/projects/1" => form => $project->{update1} )->status_is(200);
$t->get_ok("/projects/1")->status_is(200)
  ->json_is( $project->{update_result1} );#
$t->post_ok( "/projects" => form => $project_new )->status_is(200)->json_is(
    {
        status => 200,
        new_id => 3
    }
);
$project_new->{id} = '3';
$t->get_ok("/projects/3")->status_is(200)->json_is($project_new);
$t->delete_ok( "/projects/3" => form => $project_new )->status_is(200)
  ->json_is( { status => 200 } );
$t->get_ok("/projects/3")->status_is(404);
$t->put_ok( "/projects/2/longdetails" => form =>
      { name => 'project 2a', type => 'test type 2a', } )->status_is(200);
$t->get_ok("/projects/2")->status_is(200)->json_is( $project->{2} );    #

$t->put_ok(
    "/projects/2/planning" => form => {
        planning => {
            name  => 'longterm 2a',
            build => '2a'
        }
    }
)->status_is(200);
$project->{2}->{planning} = {
    name  => 'longterm 2a',
    build => '2a'
};
$t->get_ok("/projects/2")->status_is(200)->json_is( $project->{2} );    #
$t->put_ok( "/projects/1/details" => form => { owner => 'Blogs3' } )
  ->status_is(200);
$project->{1}->{owner} = 'Blogs3';
$project->{1}->{type}  = 'test type 1a';
$project->{1}->{name}  = 'project 1a';

$t->get_ok("/projects/1")->status_is(200)->json_is( $project->{1} );    #
$t->get_ok("/projects/1/users")->status_is(200)
  ->json_is( $project->{1}->{users} );                                  #
$t->get_ok("/projects/1/contacts")->status_is(200)
  ->json_is( $project->{1}->{contacts} );                               #
$t->get_ok("/projects/1/users/1")->status_is(200)
  ->json_is( $project->{1}->{users}->[0] );                             #
$t->post_ok( "/projects/1/users" => form => { user => 'Yoko' } )->status_is(200)
  ->json_is( { status => 200, new_id => 3 } );
push( @{ $project->{1}->{users} }, 'Yoko' );
$t->get_ok("/projects/1/users/3")->status_is(200)
  ->json_is( $project->{1}->{users}->[2] );
$t->delete_ok("/projects/1/users/3")->status_is(200);
$t->get_ok("/projects/1/users/3")->status_is(404);

$t->get_ok("/projects/2/contacts/1")->status_is(200)
  ->json_is( $project->{2}->{contacts}->[0] );                          #
$t->post_ok( "/projects/2/contacts" => form => { contact => 'Yoko' } )
  ->status_is(200)->json_is( { status => 200, new_id => 5 } );
push( @{ $project->{2}->{contacts} }, 'Yoko' );
$t->get_ok("/projects/2/contacts/5")->status_is(200)
  ->json_is( $project->{2}->{contacts}->[4] );
$t->delete_ok("/projects/2/contacts/3")->status_is(200);
$t->get_ok("/projects/2/contacts/3")->status_is(404);

#note here the changes done with '/projects/1/users/' PUT/POST  will 
#not be visable if you get call /projects/1/users as the data is not shared across 
#contolers! Its is only a test or the route not the controller

done_testing;
