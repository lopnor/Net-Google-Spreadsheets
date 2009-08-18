package Net::Google::Spreadsheets::Role::Base;
use Moose::Role;
use namespace::clean -except => 'meta';
use Carp;

has service => (
    isa => 'Net::Google::Spreadsheets',
    is => 'ro',
    required => 1,
    lazy_build => 1,
    weak_ref => 1,
);

sub _build_service { shift->container->service };

my %ns = (
    gd => 'http://schemas.google.com/g/2005',
    gs => 'http://schemas.google.com/spreadsheets/2006',
    gsx => 'http://schemas.google.com/spreadsheets/2006/extended',
    batch => 'http://schemas.google.com/gdata/batch',
);

while (my ($prefix, $uri) = each %ns) {
    __PACKAGE__->meta->add_method(
        "${prefix}ns" => sub {
            XML::Atom::Namespace->new($prefix, $uri)
        }
    );
}

my %rel2label = (
    edit => 'editurl',
    self => 'selfurl',
);

for (values %rel2label) {
    has $_ => (isa => 'Str', is => 'ro');
}

has atom => (
    isa => 'XML::Atom::Entry',
    is => 'rw',
    trigger => sub {
        my ($self, $arg) = @_;
        my $id = $self->atom->get($self->ns, 'id');
        croak "can't set different id!" if $self->id && $self->id ne $id;
        $self->from_atom;
    },
    handles => ['ns', 'elem', 'author'],
);

has id => (
    isa => 'Str',
    is => 'ro',
);

has title => (
    isa => 'Str',
    is => 'rw',
    default => 'untitled',
    trigger => sub {$_[0]->update}
);

has etag => (
    isa => 'Str',
    is => 'rw',
);

has container => (
    isa => 'Maybe[Net::Google::Spreadsheets::Role::Base]',
    is => 'ro',
);

sub from_atom {
    my ($self) = @_;
    $self->{title} = $self->atom->title;
    $self->{id} = $self->atom->get($self->ns, 'id');
    $self->etag($self->elem->getAttributeNS($self->gdns->{uri}, 'etag'));
    for ($self->atom->link) {
        my $label = $rel2label{$_->rel} or next;
        $self->{$label} = $_->href;
    }
}

sub to_atom {
    my ($self) = @_;
    $XML::Atom::DefaultVersion = 1;
    my $entry = XML::Atom::Entry->new;
    $entry->title($self->title) if $self->title;
    return $entry;
}

sub sync {
    my ($self) = @_;
    my $entry = $self->service->entry($self->selfurl);
    $self->atom($entry);
}

sub update {
    my ($self) = @_;
    $self->etag or return;
    my $atom = $self->service->put(
        {
            self => $self,
            entry => $self->to_atom,
        }
    );
    $self->container->sync;
    $self->atom($atom);
}

sub delete {
    my $self = shift;
    my $res = $self->service->request(
        {
            uri => $self->editurl,
            method => 'DELETE',
            header => {'If-Match' => $self->etag},
        }
    );
    $self->container->sync if $res->is_success;
    return $res->is_success;
}

1;

__END__
