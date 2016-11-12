package Mojolicious::Plugin::Routes::Restful;
use Lingua::EN::Inflect 'PL';

#Oh dear, she's stuck in an infinite loop and he's an idiot! Oh well, that's love

BEGIN {
    $Mojolicious::Plugin::Routes::Restful::VERSION = '0.01';
}
use Mojo::Base 'Mojolicious::Plugin';

sub reserved_words {
    my $self = shift;
    return {
        No_Root  => 1,
        DEBUG    => 1,
        API_Only => 1
    };
}

sub _is_reserved_words {
    my $self = shift;
    my ($word) = @_;

}

sub register {
    my ( $self, $app, $args ) = @_;
    $args ||= {};
    for my $sub_ref (qw/ Routes Config /) {
        die __PACKAGE__, ": missing '$sub_ref' Routes hash in parameters\n"
          unless exists( $args->{$sub_ref} );
    }

    for my $sub_ref (qw/ Namespaces /) {
        die __PACKAGE__, ": missing '$sub_ref' Array in Config has parameter\n"
          unless ( exists( $args->{Config}->{$sub_ref} )
            and ref( $args->{Config}->{$sub_ref} ) eq 'ARRAY' );
    }

    my $config = $args->{Config};
    my $rapp   = $app->routes;
    my $routes = $args->{Routes};

    $rapp->namespaces( $config->{'Namespaces'} );

    foreach my $key ( keys( %{$routes} ) ) {
        my $route       = $routes->{$key};
        my $route_stash = $route->{stash} || {};
        my $action      = $route->{action} || "show";
        my $controller  = $route->{controller} || $key;
        my $resource    = "";

        # my $route_debug =

        # warn(
        # "key $key controller=" . $controller . " route=" . Dumper($route) )
        # if ( $route->{DEBUG} );

        unless ( $route->{No_Root} || $route->{API_Only} ) {
            $rapp->route("/$key")->via('GET')
              ->to( "$controller#$action", $route_stash );
            warn("Has route /$key via GET->$controller#$action")
              if ( $route->{DEBUG} );
        }
        unless ( $route->{No_ID} || $route->{API_Only} ) {
            $rapp->route("/$key/:id")->via('GET')
              ->to( "$controller#$action", $route_stash );
            warn("Has ID /$key/:id via GET->$controller#$action")
              if ( $route->{DEBUG} );
        }

        $resource =
          $self->_api_routes( $rapp, $key, $route->{api}, $route_stash )
          if ( keys( %{ $route->{api} } ) );

        foreach my $inline_key ( keys( %{ $route->{inline_routes} } ) ) {

            # use Data::Dumper;
            # warn("JPS $inline_key here ".Dumper($route->{inline_routes}));
            my $inline_route = $route->{inline_routes}->{$inline_key};
            my $inline_stash = $inline_route->{stash} || $route_stash;
            my $action       = "show" || $inline_route->{action};
            my $controller   = $key || $inline_route->{controller};

            $self->_inline_api_routes( $rapp, $inline_route->{api}, $resource,
                $inline_key, { parent => $resource } )
              if ( exists( $inline_route->{api} ) );

            next
              if ( $inline_route->{API_Only} );
            warn(
"Inline route = /$key/:id/$inline_key->get colroller $key->$inline_key"
            ) if ( $route->{DEBUG} );
            $rapp->route("/$key/:id/$inline_key")->via('GET')
              ->to( "$key#$inline_key", $inline_stash );

        }

        # $self->_sub_routes( $rapi, $rapp, $route, $resource, $key,
        # $route_stash );

        foreach my $sub_route_key ( keys( %{ $route->{sub_routes} } ) ) {

            my $sub_route = $route->{sub_routes}->{$sub_route_key};

            #    warn("$sub_route_key sub_route =".Dumper($sub_route ));
            my $sub_route_stash = $sub_route->{stash} || {};

            $sub_route_stash = { %{$route_stash}, %{$sub_route_stash} };

            $self->_child_api_routes( $rapp, $resource, $sub_route_key,
                $sub_route->{api} )
              if ($resource);

            next
              if ( $sub_route->{API_Only} );

            if ( $sub_route->{No_ID} ) {

                warn(
"No_id route = \/$key\/$sub_route_key->get contoller $key\-\>$sub_route_key"
                ) if ( $route->{DEBUG} );
                $rapp->route("/$key/$sub_route_key")->via('GET')
                  ->to( "$key#$sub_route_key", $sub_route_stash );

            }
            else {

                #warn("route = /$key/:id/$sub_route_key->get");
                $rapp->route("/$key/:id/$sub_route_key")->via('GET')
                  ->to( "$key#$sub_route_key", $sub_route_stash );
                $rapp->route("/$key/:id/$sub_route_key/:child_id")->via('GET')
                  ->to( "$key#$sub_route_key", $sub_route_stash );

                warn(
"sub route = /$key/:id/$sub_route_key->get controller $key#$sub_route_key"
                ) if ( $route->{DEBUG} );
                warn(
"sub route = /$key/:id/$sub_route_key/:child_id->get controller $key#$sub_route_key"
                ) if ( $route->{DEBUG} );

            }
        }
    }
    return $rapp;

}

sub _api_routes {

    my $self = shift;
    my ( $rapi, $key, $api ) = @_;

    my $resource = $api->{resource} || PL($key);
    my $verbs    = $api->{verbs};
    my $stash    = $api->{stash} || {};

    # warn("api routes  key=$key, .".Dumper($api))
    #if ($api->{DEBUG});

    warn( "api->/" . $resource . " ->get api-$resource#get" )
      if ( $verbs->{RETREIVE} )
      and ( $api->{DEBUG} );
    $rapi->route( "/" . $resource )->via('GET')
      ->to( "api-$resource#get", $stash )
      if ( $verbs->{RETREIVE} );

    warn( "api->/" . $resource . "/:id->get api-$resource#get" )
      if ( $verbs->{RETREIVE} )
      and ( $api->{DEBUG} );

    $rapi->route( "/" . $resource . "/:id" )->via('GET')
      ->to( "api-$resource#get", $stash )
      if ( $verbs->{RETREIVE} );

    warn( "api->/" . $resource . "->POST api-$resource#create" )
      if ( $verbs->{CREATE} )
      and ( $api->{DEBUG} );
    $rapi->route( "/" . $resource )->via('POST')
      ->to( "api-$resource#create", $stash )
      if ( $verbs->{CREATE} );

    warn( "api->/" . $resource . "/:id->PUT  api-$resource#update" )
      if ( $verbs->{UPDATE} )
      and ( $api->{DEBUG} );
    $rapi->route( "/" . $resource . "/:id" )->via('PUT')
      ->to( "api-$resource#update", $stash )
      if ( $verbs->{UPDATE} );

    warn( "api->/" . $resource . "/:id->DELETE api-$resource#delete" )
      if ( $verbs->{DELETE} )
      and ( $api->{DEBUG} );
    $rapi->route( "/" . $resource . "/:id" )->via('DELETE')
      ->to( "api-$resource#delete", $stash )
      if ( $verbs->{DELETE} );

    return $resource;

}

sub _child_api_routes {

    my $self = shift;
    my ( $rapi, $resource, $key, $api ) = @_;
    warn("_child_api_routes  $rapi,$resource,$key, $api")
      if ( $api->{DEBUG} );
    my $child_resource = $api->{resource} || PL($key);
    my $verbs          = $api->{verbs};
    my $stash          = $api->{stash} || {};
    $stash->{parent} = $resource;
    $stash->{child}  = $child_resource;

    warn(
"c-api-> /$resource/:id/$child_resource ->get controller=api-$resource#$child_resource"
      )
      if ( $verbs->{RETREIVE} )
      and ( $api->{DEBUG} );

    $rapi->route( "/" . $resource . "/:id/" . $child_resource )->via('GET')
      ->to( "api-$resource#$child_resource", $stash )
      if ( $verbs->{RETREIVE} );

    warn(
"c-api-> /$resource/:id/$child_resource/:child_id ->get controller=api-$child_resource#get parent=$resource"
      )
      if ( $verbs->{RETREIVE} )
      and ( $api->{DEBUG} );

    $rapi->route( "/" . $resource . "/:id/" . $child_resource . "/:child_id" )
      ->via('GET')->to( "api-$child_resource#get", $stash )
      if ( $verbs->{RETREIVE} );

    warn(
"c-api-> /$resource/:id/$child_resource ->post/create controller=api-$child_resource#create parent=$resource"
      )
      if ( $verbs->{CREATE} )
      and ( $api->{DEBUG} );

    $rapi->route( "/" . $resource . "/:id/" . $child_resource )->via('POST')
      ->to( "api-$child_resource#create", $stash )
      if ( $verbs->{CREATE} );

    warn(
"c-api-> /$resource/:id/$child_resource/:child_id ->put/update controller=api-$child_resource#update parent=$resource"
      )
      if ( $verbs->{UPDATE} )
      and ( $api->{DEBUG} );

    $rapi->route( "/" . $resource . "/:id/" . $child_resource . "/:child_id" )
      ->via('PUT')->to( "api-$child_resource#update", $stash )
      if ( $verbs->{UPDATE} );
    warn(
"c-api-> /$resource/:id/$child_resource/:child_id ->delete controller=api-$child_resource#delete parent=$resource"
      )
      if ( $verbs->{DELETE} )
      and ( $api->{DEBUG} );

    $rapi->route( "/" . $resource . "/:id/" . $child_resource . "/:child_id" )
      ->via('DELETE')->to( "api-$child_resource#delete", $stash )
      if ( $verbs->{DELETE} );

    warn("out  api routes ")
      if ( $api->{DEBUG} );
}

sub _inline_api_routes {

    my $self = shift;
    my ( $rapi, $api, $resource, $child_resource, $stash ) = @_;
    my $verbs = $api->{verbs};
    $child_resource = $api->{resource} || $child_resource . "s";
    $stash = {}
      unless ($stash);
    $stash->{parent} = $resource;
    $stash->{child}  = $child_resource;
    warn(
"_inline_api_routes resource=$resource, child_resource=$child_resource, api=$api"
      )

      # . Dumper($api) )
      if ( $api->{DEBUG} );

# $rapi->route("/".$resource."/:id/".$child_resource)             ->via('GET')    ->to("api-$resource#$child_resource",$stash)
# if($verbs->{RETREIVE});

    warn(
"inline api-> /$resource/:id/$child_resource->post controller=api-$resource#create"
    ) if ( $verbs->{CREATE} and $api->{DEBUG} );

    $rapi->route( "/" . $resource . "/:id/" . $child_resource )->via('POST')
      ->to( "api-$resource#create", $stash )
      if ( $verbs->{CREATE} );

    warn(
"inline api-> /$resource/:id/$child_resource->get controller=api-$resource#$child_resource"
    ) if ( $verbs->{RETREIVE} and $api->{DEBUG} );
    $rapi->route( "/" . $resource . "/:id/" . $child_resource )->via('get')
      ->to( "api-$resource#$child_resource", $stash )
      if ( $verbs->{RETREIVE} );

    warn(
"inline api-> /$resource/:id/$child_resource->PUT controller=api-$resource#$child_resource"
    ) if ( $verbs->{UPDATE} and $api->{DEBUG} );
    $rapi->route( "/" . $resource . "/:id/" . $child_resource )->via('PUT')
      ->to( "api-$resource#$child_resource", $stash )
      if ( $verbs->{UPDATE} );

# $rapi->route("/".$resource."/:id/".$child_resource)            ->via('DELETE')->to("api-$child_resource#delete",$stash)
# if($verbs->{DELETE});

}

sub _sub_routes {
    my $self = shift;
    my ( $rapi, $rapp, $route, $resource, $key, $route_stash ) = shift;

    foreach my $sub_route_key ( keys( %{ $route->{sub_routes} } ) ) {

        my $sub_route = $route->{sub_routes}->{$sub_route_key};

        my $sub_route_stash = $sub_route->{stash} || {};

        #   warn("$sub_route_key sub_route =".Dumper($sub_route ));

        $sub_route_stash = { %{$route_stash}, %{$sub_route_stash} };

        $self->_child_api_routes( $rapi, $resource, $sub_route_key,
            $sub_route->{api} )
          if ($resource);

        next
          if ( $sub_route->{API_Only} );

        if ( $sub_route->{No_ID} ) {

            warn(
"No_id route = \/$key\/$sub_route_key->get contoller $key\-\>$sub_route_key"
            ) if ( $route->{DEBUG} );
            $rapp->route("/$key/$sub_route_key")->via('GET')
              ->to( "$key#$sub_route_key", $sub_route_stash );

        }
        else {

            #warn("route = /$key/:id/$sub_route_key->get");
            $rapp->route("/$key/:id/$sub_route_key")->via('GET')
              ->to( "$key#$sub_route_key", $sub_route_stash );
            $rapp->route("/$key/:id/$sub_route_key/:child_id")->via('GET')
              ->to( "$key#$sub_route_key", $sub_route_stash );

            warn(
"sub route = /$key/:id/$sub_route_key->get controller $key#$sub_route_key"
            ) if ( $route->{DEBUG} );
            warn(
"sub route = /$key/:id/$sub_route_key/:child_id->get controller $key#$sub_route_key"
            ) if ( $route->{DEBUG} );

        }
    }
}

return 1;
__END__

=pod

=head1 NAME

Mojolicious::Plugin::Routes::Restful- A plugin to generate Routes and RESTful api routes.

=head1 VERSION

version 1.04

=head1 SYNOPSIS
In you Mojo App:

  package RouteRestful;
  use Mojo::Base 'Mojolicious';

  sub startup {
    my $self = shift;
    my $r = $self->plugin( "Routes::Restful", => {
                   Config => { Namespaces => ['Controller'] },
                   Routes => {
                     project => {
                       api   => {
                         verbs => {
                           CREATE   => 1,
                           UPDATE   => 1,
                           RETREIVE => 1,
                           DELETE   => 1
                         },
                       },
                       inline_routes => {
                         detail => {
                           api => { 
                           verbs => { UPDATE => 1 } }
                         },
                       },
                       sub_routes => {
                         user => {
                           api => {
                             verbs => {
                               CREATE   => 1,
                               RETREIVE => 1,
                               UPDATE   => 1,
                               DELETE   => 1
                             }
                           }
                         }
                       }
                     }
                   } 
                 );
          
    }
    1;
    
And presto the following non restful routes

  +--------+-----------------------------+-----+-------------------+
  |  Type  |    Route                    | Via | Controller#Action |
  +--------+-----------------------------+-----+-------------------+ 
  | Key    | /project                    | GET | project#show      |
  | Key    | /project/:id                | GET | project#show      |
  | Inline | /project/:id/detail         | GET | project#detail    |
  | Sub    | /project/:id/user           | GET | project#user      |
  | Sub    | /project/:id/user/:child_id | GET | project#user      |
  +--------+-----------------------------+-----+-------------------+

and the following restful API routes

  +--------+-------------------------------+--------+----------------------------------+
  |  Type  |       Route                   | Via    | Controller#Action                |
  +--------+-------------------------------+--------+----------------------------------+
  | Key    | /projects                     | GET    | api-projects#get                 |
  | Key    | /projects/:id                 | GET    | api-projects#get                 |
  | Key    | /projects                     | POST   | api-projects#create              |
  | Key    | /projects/:id                 | PUT    | api-projects#update              |
  | Key    | /projects/:id                 | DELETE | api-projects#delete              |
  | Inline | /projects/:id/details         | PUT    | api-projects#details             |
  | Sub    | /projects/:id/users           | GET    | api-projects#users               |
  | Sub    | /projects/:id/users/:child_id | GET    | api-users#get parent=projects    |
  | Sub    | /projects/:id/users           | POST   | api-users#create parent=projects |
  | Sub    | /projects/:id/users/:child_id | PUT    | api-users#update parent=projects |
  | Sub    | /projects/:id/users/:child_id | DELETE | api-users#delete parent=projects |
  +--------+-------------------------------+--------+----------------------------------+


=head1 DESCRIPTION

L<Mojolicious::Plugin::Routes::Restful> is a L<Mojolicious::Plugin> if a highly configurable route generator for your Mojo App.
Simply drop the plugin at the top of your srart class add in config hash and you have your routes for you system.

=head1 METHODS

Well none! Like the L<|'Box Factory'|https://simpsonswiki.com/wiki/Box_Factory> it olny generates routes to put in you app.

=head1 CONFIGURATION

You define which routes and the behaviour of your routes with a congfig hash that contains settings for global attribues 
and overriders specific defintions of your routes. 

=head2 Config

This contorls the global settings of the routes that are generated. 

=head3 Namepaces

Use this to Change the default namespaces for all routes you generate. Does the same thing as

    $r->namespaces(['MyApp::MyController']);
    
It must be an array ref.



=head2 Routes

This hash is used to define both you regular and restful routes. The design idea phliosphy being the assumption that if you have a 'route'
to a content resource you may want a restful API resource to access the data for that content resource and you may want to limt what parts of the API you open up.  

By default it uses the 'key' values of the hash as the controller name. So given this hash

  Routes => {
            project => {},
            user    => {}
          }

only these routes will be created

  +--------+-----------------------------+-----+-------------------+
  |  Type  |    Route                    | Via | Controller#Action |
  +--------+-----------------------------+-----+-------------------+ 
  | Key    | /project                    | GET | project#show      |
  | Key    | /project/:id                | GET | project#show      |
  | Key    | /user                       | GET | user#show         |
  | Key    | /user/:id                   | GET | user#show         |
  +--------+-----------------------------+-----+-------------------+

These are the 'Root' level routes and to save saying 'Root' and 'Route' in the same sentence over and over abain this doucmennt will call
these 'Key' routes hearafter.

=head3 'Routes' Modifiers

The world is a compley place and there is never a simple solution that covers all the bases this plugin inclues a number of modifiers to customize
your routes to suite your sites needs.

=head4 action

You can overide the default 'show' action by simply using this modifier so

  Routes => {
            project => {action=>'list'},
          }

would get you 

  +--------+-----------------------------+-----+-------------------+
  |  Type  |    Route                    | Via | Controller#Action |
  +--------+-----------------------------+-----+-------------------+ 
  | Key    | /project                    | GET | project#list      |
  | Key    | /project/:id                | GET | project#list      |
  +--------+-----------------------------+-----+-------------------+

=head4 controller

One can overide the use of 'key' as the controller name by using this modifier so

  Routes => {
            project => {action=>'list'
                         controller=>'pm'},
          }

  +--------+-----------------------------+-----+-------------------+
  |  Type  |    Route                    | Via | Controller#Action |
  +--------+-----------------------------+-----+-------------------+ 
  | Key    | /project                    | GET | pm#list      |
  | Key    | /project/:id                | GET | pm#list      |
  +--------+-----------------------------+-----+-------------------+

=head4  No_Root

Sometimes one might not want to open up a 'Root' resource so you can use this modifier to drop that route

  Routes => {
            project => {action=>'list'
                         controller=>'pm'
                         No_Root=>1 },
          }

would get you 

  +--------+-----------------------------+-----+-------------------+
  |  Type  |    Route                    | Via | Controller#Action |
  +--------+-----------------------------+-----+-------------------+ 
  | Key    | /project/:id                | GET | pm#list           |
  +--------+-----------------------------+-----+-------------------+

=head4  No_Id

Likewise you may not wand to have an id on a 'Root' resource so you can use this modifier to drop that route

  Routes => {
            project => {action=>'all_projects'
                         controller=>'pm'
                         No_Id=>1 },
          }

would get you

  +--------+-----------------------------+-----+-------------------+
  |  Type  |    Route                    | Via | Controller#Action |
  +--------+-----------------------------+-----+-------------------+ 
  | Key    | /project                    | GET | pm#all_projects   |
  +--------+-----------------------------+-----+-------------------+

Just to warn you now that if you use 'No_Id' and 'No_Root' you would get no routes.

=head4 API_Only

Sometimes you want just the restful API so insted of using No_Id and 'No_Root' use the 'API_Only' and get
no routes!

=head4 stash

Need some static data on all itmes along a route?  Well with this modifier you can.  So given this hash

  Routes => {
            project => {stash=>{selected_tab=>'project'}},
            user    => {stash=>{selected_tab=>'user'}}
          }
          
You would get the same routes as with the first example but the 'tab' variable will be available in the stash.  So
you could use it on your controller to pass the current navigaiton state into the content pages say, as in in this
case, to set up a  the 'Selected Tab' in a  view.

=head4 inline_routes

These are routes that go unter on the 'Key'
   
   api', version => 'v1'

=over 4 inline_routes





=head1 AUTHOR

John Scoles, C<< <byterock  at hotmail.com> >>

=head1 BUGS / CONTRIBUTING

Please report any bugs or feature requests through the web interface at L<https://github.com/byterock/>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.
    perldoc Mojolicious::Plugin::Authorization
You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation L<http:/>

=item * CPAN Ratings L<http://cpanratings.perl.org/d/>

=item * Search CPAN L<http://search.cpan.org/dist//>

=back

=head1 ACKNOWLEDGEMENTS


    
=head1 LICENSE AND COPYRIGHT

Copyright 2012 John Scoles.
This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.
See http://dev.perl.org/licenses/ for more information.

=cut
