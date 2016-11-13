package Mojolicious::Plugin::Routes::Restful;
use Lingua::EN::Inflect 'PL';
use Data::Dumper;
#Oh dear, she's stuck in an infinite loop and he's an idiot! Oh well, that's love

BEGIN {
    $Mojolicious::Plugin::Routes::Restful::VERSION = '0.01';
}
use Mojo::Base 'Mojolicious::Plugin';

sub _reserved_words {
    my $self = shift;
    return {
        No_Root  => 1,
        DEBUG    => 1,
        API_Only => 1
    };
}

sub _get_methods {
    my $self = shift;
    my ($via) = @_;

    return ['GET']
      unless ($via);
    my $valid = {
        GET    => 1,
        POST   => 1,
        PUT    => 1,
        DELETE => 1
    };

    my @uc_via = map( uc($_), @{$via} );

    return \@uc_via

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

        my $resource =
          $self->_make_routes( "ROOT", $rapp, $key, $routes->{$key},$config, "" );

         my $route       = $routes->{$key};

        foreach my $inline_key ( keys( %{ $route->{inline_routes} } ) ) {
          
           
            $self->_make_routes( "INLINE", $rapp, $inline_key,
                $route->{inline_routes}->{$inline_key},$key,$resource,$config ,$routes->{$key}->{stash});

        }


        foreach my $sub_route_key ( keys( %{ $route->{sub_routes} } ) ) {

           $self->_make_routes( "SUB", $rapp, $sub_route_key,
                $route->{sub_routes}->{$sub_route_key},$key,$resource,$config, $routes->{$key}->{stash});
          
        }
    }
    return $rapp;

}

sub _make_routes {
    my $self = shift;
    my ( $type, $rapp, $key, $route, $parent, $resource,$config, $parent_stash ) = @_;



    my $route_stash  = $route->{stash} || {};
    
    $route_stash = { %{ $route_stash }, %{$parent_stash} } 
     if ($parent_stash);
    my $action       = $route->{action}                           || "show";
    my $controller   = $route->{controller} || $key;
    my $methods      = $self->_get_methods( $route->{via} );
    my $methods_desc = join(',',@{ $methods });

    if ( $type eq 'ROOT' ) {
     
        unless ( $route->{No_Root} || $route->{API_Only} ) {
            $rapp->route("/$key")->via($methods)
              ->to( "$controller#$action", $route_stash );
              
            warn("$type  Route = /$key->Via->[$methods_desc]->$controller#$action")
              if ( $route->{DEBUG} );
        }
        
        unless ( $route->{No_ID} || $route->{API_Only} ) {
            $rapp->route("/$key/:id")->via($methods)
              ->to( "$controller#$action", $route_stash );
              
            warn("$type  Route = /$key/:id->Via->[$methods_desc]->$controller#$action")
              if ( $route->{DEBUG} );
        }

        $resource =
          $self->_api_routes( $rapp, $key, $route->{api},$config->{api} )
          if ( keys( %{ $route->{api} } ) );
          
        return $resource;

    }
    
    $controller = $route->{controller} || $parent; #aways use parent on kids

    if ( $type eq 'INLINE' ) {
      
        $action       = $route->{action} || $key;
      
        $self->_inline_api_routes( $rapp, $route->{api}, $resource, $key,$config->{api})
          if ( exists( $route->{api} ) );
          
        return
          if ( $route->{API_Only} );
        
        warn("$type Route = /$parent/:id/$key->Via->[$methods_desc]->$controller#$action" )
          if ( $route->{DEBUG} );

        $rapp->route("/$parent/:id/$key")->via($methods)->to( "$controller#$action", $route_stash );

    }
    elsif ( $type eq 'SUB' ) {
         $action       = $route->{action} || $key;

         $self->_sub_api_routes( $rapp, $resource, $key,
                $route->{api},$config->{api} )
              if ( exists( $route->{api} ));

        next
          if ( $route->{API_Only} );

        if ( $route->{No_ID} ) {

           warn("$type    Route = /$parent/$key->Via->[$methods_desc]->$controller#$action" )
              if ( $route->{DEBUG} );
            $rapp->route("/$parent/$key")->via($methods)
              ->to( "$parent#$key", $route_stash );

        }
        else {

            
            $rapp->route("/$parent/:id/$key")->via($methods)
              ->to( "$parent#$action", $route_stash );
            $rapp->route("/$parent/:id/$key/:child_id")->via($methods)
              ->to( "$parent#$action", $route_stash );

            warn("$type    Route = /$parent/:id/$key->Via->[$methods_desc]->$controller#$action" )
            if ( $route->{DEBUG} );
            warn("$type    Route = /$parent/:id/$key/:child_id->Via->[$methods_desc]->$controller#$action" )
             if ( $route->{DEBUG} );

        }
    }

}

sub _api_url {
  my $self = shift;
  my ($resource, $config) = @_;
  my $ver      = $config->{ver}   || "";
  my $prefix   = $config->{prefix}   || "";
 
  my $url = join("/",grep($_ ne "",($ver,$prefix,$resource)));
  return $url;
}

sub _api_routes {

    my $self = shift;
    my ( $rapi, $key, $api,$config ) = @_;

    my $resource = $api->{resource} || PL($key);
    my $verbs    = $api->{verbs};
    my $stash    = $api->{stash} || {};
    my $contoller= $config->{controller}   || "api";
    
    my $url = $self->_api_url($resource,$config);
     
    warn("API ROOT  ->/" . $url . "->Via->GET-> $contoller-$resource#get" )
      if ( $verbs->{RETREIVE} )
      and ( $api->{DEBUG} );
      
    $rapi->route( "/" . $url )->via('GET')
      ->to( "$contoller-$resource#get", $stash )
      if ( $verbs->{RETREIVE} );

    warn("API ROOT  ->/" . $url . "/:id->Via->GET-> $contoller-$resource#get" )
      if ( $verbs->{RETREIVE} )
      and ( $api->{DEBUG} );

    $rapi->route( "/" . $url . "/:id" )->via('GET')
      ->to( "$contoller-$resource#get", $stash )
      if ( $verbs->{RETREIVE} );
      
    warn("API ROOT  ->/" . $url . "/:id->Via->POST-> $contoller-$resource#create" )
   if ( $verbs->{CREATE} )
      and ( $api->{DEBUG} );
      
    $rapi->route( "/" . $url )->via('POST')
      ->to( "$contoller-$resource#create", $stash )
      if ( $verbs->{CREATE} );

    warn("API ROOT  ->/" . $url . "/:id->Via->PUT-> $contoller-$resource#update" )
      if ( $verbs->{UPDATE} )
      and ( $api->{DEBUG} );
      
    $rapi->route( "/" . $url . "/:id" )->via('PUT')
      ->to( "api-$resource#update", $stash )
      if ( $verbs->{UPDATE} );
      
    warn("API ROOT  ->/" . $url . "/:id->Via->DELETE-> $contoller-$resource#delete" )
      if ( $verbs->{DELETE} )
      and ( $api->{DEBUG} );
      
    $rapi->route( "/" . $url . "/:id" )->via('DELETE')
      ->to( "$contoller-$resource#delete", $stash )
      if ( $verbs->{DELETE} );

    return $resource;

}

sub _sub_api_routes {

    my $self = shift;
    my ( $rapi, $resource, $key, $api,$config ) = @_;
   
    my $child_resource = $api->{resource} || PL($key);
    my $verbs          = $api->{verbs};
    my $stash          = $api->{stash} || {};
    my $contoller= $config->{api}->{controller}   || "api";
    $stash->{parent} = $resource;
    $stash->{child}  = $child_resource; 
    my $url = $self->_api_url($config);
    
    warn("API SUB   ->/" . $resource . "/:id/$child_resource ->Via->GET-> $contoller-$resource#$child_resource#get" )
      if ( $verbs->{RETREIVE} )  and ( $api->{DEBUG} );

    $rapi->route( "/" . $resource . "/:id/" . $child_resource )->via('GET')
      ->to( "api-$resource#$child_resource", $stash )
      if ( $verbs->{RETREIVE} );

    warn("API SUB   ->/" . $resource . "/:id/$child_resource/:child_id->Via->GET-> $contoller-$child_resource#get" )
      if ( $verbs->{RETREIVE} ) and ( $api->{DEBUG} );

    $rapi->route( "/" . $resource . "/:id/" . $child_resource . "/:child_id" )
      ->via('GET')->to( "$contoller-$child_resource#get", $stash )
      if ( $verbs->{RETREIVE} );

    warn("API SUB   ->/" . $resource . "/:id/$child_resource ->Via->POST-> $contoller-$child_resource#create" )
      if ( $verbs->{CREATE} ) and ( $api->{DEBUG} );

    $rapi->route( "/" . $resource . "/:id/" . $child_resource )->via('POST')
      ->to( "$contoller-$child_resource#create", $stash )
      if ( $verbs->{CREATE} );

    warn("API SUB   ->/" . $resource . "/:id/$child_resource/:child_id->Via->PUT-> $contoller-$child_resource#update" )
      if ( $verbs->{UPDATE} )  and ( $api->{DEBUG} );

    $rapi->route( "/" . $resource . "/:id/" . $child_resource . "/:child_id" )
      ->via('PUT')->to( "$contoller-$child_resource#update", $stash )
      if ( $verbs->{UPDATE} );
    warn("API SUB   ->/" . $resource . "/:id/$child_resource/:child_id->Via->DELETE-> $contoller-$child_resource#delete" )
      if ( $verbs->{DELETE} )  and ( $api->{DEBUG} );

    $rapi->route( "/" . $resource . "/:id/" . $child_resource . "/:child_id" )
      ->via('DELETE')->to( "$contoller-$child_resource#delete", $stash )
      if ( $verbs->{DELETE} );

}

sub _inline_api_routes {

    my $self = shift;
    my ( $rapi, $api, $resource, $child_resource,$config) = @_;
    my $verbs = $api->{verbs};
    $child_resource = $api->{resource} || PL($child_resource);
    my $stash        = $api->{stash} || {};
    my $contoller= $config->{api}->{controller}   || "api";
    $stash->{parent} = $resource;
    $stash->{child}  = $child_resource;
    my $url = $self->_api_url($config);


    # warn("API INLINE->/" . $resource . "/:id/$child_resource->Via->POST-> api-$resource#create" )
     # if ( $verbs->{CREATE} and $api->{DEBUG} );

    # $rapi->route( "/" . $resource . "/:id/" . $child_resource )->via('POST')
      # ->to( "api-$resource#create", $stash )
      # if ( $verbs->{CREATE} );
      
    warn("API INLINE->/" . $resource . "/:id/$child_resource->Via->GET> $contoller-$resource#$child_resource" )
     if ( $verbs->{RETREIVE} and $api->{DEBUG} );
     
    $rapi->route( "/" . $resource . "/:id/" . $child_resource )->via('GET')
      ->to( "$contoller-$resource#$child_resource", $stash )
      if ( $verbs->{RETREIVE} );

    warn("API INLINE->/" . $resource . "/:id/$child_resource->Via->PUT> $contoller-$resource#$child_resource" )
    if ( $verbs->{UPDATE} and $api->{DEBUG} );
    
    $rapi->route( "/" . $resource . "/:id/" . $child_resource )->via('PUT')
      ->to( "$contoller-$resource#$child_resource", $stash )
      if ( $verbs->{UPDATE} );


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
  | Key    | /project                    | GET | pm#list           |
  | Key    | /project/:id                | GET | pm#list           |
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

=head4 Via

By defualt all 'Key' routes use the 'Get' http method.  You can change this, if you want to or any other valid combination of
HTTP methods.  As this plugin has a resful protion I am not sure you would you want to.  
Takes an array-ref of valid http methods which will be changed to uppercase.  So with this hash


  Routes => {
            project => {Via   =>[qw(Post GeT)]},
            user    => {Via =>[qw(POST PUt),
                        action=>'update']}
          }

would yeld these routes;

  +--------+-----------------------------+------+-------------------+
  |  Type  |    Route                    | Via  | Controller#Action |
  +--------+-----------------------------+------+-------------------+ 
  | Key    | /project                    | GET  | project#show      |
  | Key    | /project/:id                | GET  | project#show      |
  | Key    | /project                    | POST | project#show      |
  | Key    | /project/:id                | POST | project#show      |
  | Key    | /user                       | POST | user#update       |
  | Key    | /user/:id                   | POST | user#update       |
  | Key    | /user                       | PUT  | user#update       |
  | Key    | /user/:id                   | PUT  | user#update       |
  +--------+-----------------------------+------+-------------------+

Note here how the 'action' of the user route was changed to 'update' as it would not be a very good idea to have a sub
in your controller called 'show' that updates a entity.  
=head4 inline_routes

These are routes that go unter on the 'Key'
   
   api', version => 'v1'

=over 4 inline_routes

An 'inline' route is one that normally points to only part of a single entity but not a collection of that entity.  
Useing an example 'Project' page it could be made up of a number panels, pages, tabs etc. each containing only part of 
the whole project.  In the example below we have three panels on the project page

  +----------+---------+----------+
  | Abstract | Details | Admin    | 
  +          +---------+----------+
  |                               |
  | Some content here             |
  ...
  
So to create the routes for the above one would have a hash like this

    Routes => {
            project => {
              stash =>{page=>'project'},
              inline_routes => { abstract=>{
                                   stash=>{tab=>'abstract'}
                                   },
                                 detail=>{
                                   stash=>{tab=>'detail'},
                                  },
                                 admin=>{
                                   stash=>{tab=>'admin'},
                                   }
                                 }
               },
          }
          
which would give you these routes

  +--------+-----------------------------+-----+-------------------+----------------+
  |  Type  |    Route                    | Via | Controller#Action | Stashed Values |
  +--------+-----------------------------+-----+-------------------+----------------+
  | Key    | /project                    | GET | project#show      | page = project |
  | Key    | /project/:id                | GET | project#show      | page = project |
  | Inline | /project/:id/abstract       | GET | project#abstract  | tab  = abstract|
  | Inline | /project/:id/detail         | GET | project#detail    | tab  = detail  |
  | Inline | /project/:id/admin          | GET | project#admin     | tab  = admin   |
  +--------+-----------------------------+-----+-------------------+----------------+
 
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
