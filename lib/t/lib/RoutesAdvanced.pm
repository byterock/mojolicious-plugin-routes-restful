package RoutesAdvanced;
use Mojo::Base 'Mojolicious';

sub startup {
    my $self = shift;

    $self->plugin(
        "Routes::Restful",
        {
            Config => {
                api => {
                    resource_ver    => 'V_1',
                    resource_prefix => 'myapp',
                    prefix          => 'ipa'
                },
                Namespaces => [
                    'RoutesAdvanced::Controller',
                    'RoutesAdvanced::Controller::My',
                    'RoutesAdvanced::Controller::Ipa',
                    'RoutesAdvanced::Controller::Ipa::Projects',
                ]
            },
            Routes => {
                lab => {
                    No_ID => 1,

                    #DEBUG => 1,

                },
                office => {
                    No_Root => 1,
                    #DEBUG   => 1,
                },
                papers => {
                    API_Only => 1,

                    #DEBUG => 1,
                    api => 
                    {resource=>'paper',
                        controller     => 'papers',
                        #DEBUG => 1,
                        verbs => { RETREIVE => 1, },
                    },

                },
                project => {
                    action     => 'process',
                    controller => 'my-project',
                    via        => [ 'get', 'post' ],

                    #DEBUG => 1,
                    inline_routes => {
                        detail => {

                            #DEBUG => 1,
                            action     => 'project',
                            controller => 'detail',
                            via        => [ 'get', 'post' ],
                            api        => {
                                #DEBUG => 1,
                                action     => 'mydeatails',
                                resource  => 'my_details',
                                verbs => {
                                    RETREIVE => 1
                                }
                            }
                        },
                        planning => {
                            #DEBUG    => 1,
                            API_Only => 1,
                            api      => {

                                #DEBUG => 1,
                                resource => 'planning',
                                verbs    => {
                                      
                                     RETREIVE => 1
                                }
                            }
                        },
                    },
                    sub_routes => {
                        user => {
                            action     => 'my_projects',
                            controller => 'my-user',
                            via        => [ 'delete', 'patch', 'put' ],

                            #DEBUG => 1,

                            api => {
                                controller => 'projects-user',
                                resource   => 'view_users',
                                DEBUG => 1,
                                verbs => {
                                    RETREIVE => 1,
                                }
                            }
                        },
                        contact => {

                            #DEBUG => 1,
                            API_Only => 1,
                            api      => {

                                #DEBUG => 1,
                                verbs => {
                                    CREATE   => 1,
                                    REPLACE  => 1,
                                    RETREIVE => 1,
                                    UPDATE   => 1,
                                    DELETE   => 1
                                }
                            }
                        },
                    },
                },
            }
        }
    );

}

return 1;
