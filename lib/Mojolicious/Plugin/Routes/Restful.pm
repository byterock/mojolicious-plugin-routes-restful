package Mojolicious::Plugin::Routes::Restful;
use Lingua::EN::Inflect 'PL';

#Oh dear, she's stuck in an infinite loop and he's an idiot! Oh well, that's love 

BEGIN {
    $Mojolicious::Plugin::Routes::Restful::VERSION = '0.01';
}
use Mojo::Base 'Mojolicious::Plugin';


sub reserved_words {
  my $self = shift;
  return {No_Root=>1,
          DEBUG=>1,
          API_Only=>1};
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
    $rapp->namespaces( $config->{'Namespaces'} );

   
    #  Namespace
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

        unless ( $route->{No_Root} ) {
            $rapp->route("/$key")->via('GET')
              ->to( "$controller#$action", $route_stash );
            warn("Has route /$key via GET->$controller#$action")
              if ( $route->{DEBUG} );
        }
        unless ( $route->{No_ID} ) {
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
"_inline_api_routes resource=$resource, child_resource=$child_resource, api=$api")
          # . Dumper($api) )
      if ( $api->{DEBUG} );

# $rapi->route("/".$resource."/:id/".$child_resource) 			->via('GET')	->to("api-$resource#$child_resource",$stash)
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

# $rapi->route("/".$resource."/:id/".$child_resource)			->via('DELETE')->to("api-$child_resource#delete",$stash)
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
