package Net::Google::Spreadsheets::Traits::Feed;
use Moose::Role;

has entry_class => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has entry_arg_builder => (
    is => 'ro',
    isa => 'CodeRef',
    required => 1,
    default => sub {
        return sub {
            my ($self, $args) = @_;
            return $args || {};
        };
    },
);

has query_arg_builder => (
    is => 'ro',
    isa => 'CodeRef',
    required => 1,
    default => sub {
        return sub {
            my ($self, $args) = @_;
            return $args || {};
        };
    },
);

has from_atom => (
    is => 'ro',
    isa => 'CodeRef',
    required => 1,
    default => sub {
        return sub {};
    }
);

after install_accessors => sub {
    my $attr = shift;
    my $class = $attr->associated_class;
    my $key = $attr->name;

    my $entry_class = $attr->entry_class;
    my $arg_builder = $attr->entry_arg_builder;
    my $query_builder = $attr->query_arg_builder;
    my $from_atom = $attr->from_atom;
    my $method_base = lc [ split('::', $entry_class) ]->[-1];

    $class->add_method(
        "add_${method_base}" => sub {
            my ($self, $args) = @_;
            Class::MOP::load_class($entry_class);
            $args = $arg_builder->($self, $args);
            my $entry = $entry_class->new($args)->to_atom;
            my $atom = $self->service->post($self->$key, $entry);
            $self->sync;
            return $entry_class->new(
                container => $self,
                atom => $atom,
            );
        }
    );

    $class->add_method(
        "${method_base}s" => sub {
            my ($self, $cond) = @_;
            $self->$key or return;
            Class::MOP::load_class($entry_class);
            $cond = $query_builder->($self, $cond);
            my $feed = $self->service->feed($self->$key, $cond);
            return map {
                $entry_class->new(
                    container => $self,
                    atom => $_,
                )
            } $feed->entries;
        }
    );

    $class->add_method(
        $method_base => sub {
            my ($self, $cond) = @_;
            my $method = "${method_base}s";
            return [ $self->$method($cond) ]->[0];
        }
    );

    $class->add_after_method_modifier(
        'from_atom' => sub {
            my $self = shift;
            $from_atom->($self);
        }
    );
};

1;
