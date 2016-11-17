package RouteRestful;
use Mojo::Base 'Mojolicious';

sub startup {
    my $self = shift;

    $self->plugin(
        "Routes::Restful",
        { 
            CONFIG => { Namespaces => ['RouteRestful::Controller'] },
            PARENT => {
                project => {
                    #DEBUG => 1,
                    API   => {
                        #DEBUG => 1,
                        VERBS => {
                            CREATE   => 1,
                            UPDATE   => 1,
                            RETREIVE => 1,
                            REPLACE  => 1,
                            DELETE   => 1
                        },
                    },
                    INLINE => {
                        detail => {
                            #DEBUG => 1,
                            API   => { VERBS => { UPDATE   => 1,
                                                  RETREIVE => 1 } }
                        },
                        planning => {
                            #DEBUG => 1,
                            API => {
                               #DEBUG => 1,
                                RESOURCE => 'planning',
                                VERBS    => { UPDATE   => 1,
                                              RETREIVE => 1 }
                            }
                        },
                        longdetail => {
                            #DEBUG => 1,
                            API   => {
                               #DEBUG => 1,
                                VERBS => { UPDATE => 1 }
                            }
                        }
                    },
                    CHILD => {
                        user => {
                                                            #DEBUG => 1,
                            API => {
                                #DEBUG => 1,
                                VERBS => {
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
                            API => {
                                #DEBUG => 1,
                                VERBS => {
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
