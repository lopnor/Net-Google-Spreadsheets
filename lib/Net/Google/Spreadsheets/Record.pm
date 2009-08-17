package Net::Google::Spreadsheets::Record;
use Moose;
use namespace::clean -except => 'meta';
use XML::Atom::Util qw(nodelist);

extends 'Net::Google::Spreadsheets::Base';
with 'Net::Google::Spreadsheets::Role::HasContent';

after from_atom => sub {
    my ($self) = @_;
    for my $node (nodelist($self->elem, $self->gsns->{uri}, 'field')) {
        $self->{content}->{$node->getAttribute('name')} = $node->textContent;
    }
};

around to_atom => sub {
    my ($next, $self) = @_;
    my $entry = $next->($self);
    while (my ($key, $value) = each %{$self->{content}}) {
        $entry->add($self->gsns, 'field', $value, {name => $key});
    }
    return $entry;
};

__PACKAGE__->meta->make_immutable;

1;

__END__
