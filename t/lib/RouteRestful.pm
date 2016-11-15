package RouteRestful;
use Mojo::Base 'Mojolicious';

sub startup {
    my $self = shift;

    $self->plugin(
        "Routes::Restful",
        { 
            Config => { Namespaces => ['RouteRestful::Controller'] },
            Routes => {
                project => {
                    #DEBUG => 1,
                    api   => {
                        #DEBUG => 1,
                        verbs => {
                            CREATE   => 1,
                            UPDATE   => 1,
                            RETREIVE => 1,
                            REPLACE  => 1,
                            DELETE   => 1
                        },
                    },
                    inline_routes => {
                        detail => {
                            #DEBUG => 1,
                            api   => { verbs => { UPDATE   => 1,
                                                  RETREIVE => 1 } }
                        },
                        planning => {
                            #DEBUG => 1,
                            api => {
                               #DEBUG => 1,
                                resource => 'planning',
                                verbs    => { UPDATE   => 1,
                                              RETREIVE => 1 }
                            }
                        },
                        longdetail => {
                            #DEBUG => 1,
                            api   => {
                               #DEBUG => 1,
                                verbs => { UPDATE => 1 }
                            }
                        }
                    },
                    sub_routes => {
                        user => {
                                                            #DEBUG => 1,
                            api => {
                                #DEBUG => 1,
                                verbs => {
                                    CREATE   => 1,
                                    RETREIVE => 1,
                                    REPLACE  => 1,
                                    UPDATE   => 1,
                                    DELETE   => 1
                                }
                            }
                        },
                        contact => {
                                                            #DEBUG => 1,
                            api => {
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
