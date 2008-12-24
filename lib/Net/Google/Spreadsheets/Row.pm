package Net::Google::Spreadsheets::Row;
use Moose;

extends 'Net::Google::Spreadsheets::Base';

has +content => (
    isa => 'HashRef',
    is => 'rw',
    default => sub { +{} },
    trigger => sub {$_[0]->update},
);

after _update_atom => sub {
    my ($self) = @_;
    for my $node ($self->elem->getElementsByTagNameNS($self->gsxns->{uri}, '*')) {
        $self->{content}->{$node->localname} = $node->textContent;
    }
};

around entry => sub {
    my ($next, $self) = @_;
    my $entry = $next->($self);
    while (my ($key, $value) = each %{$self->{content}}) {
        $entry->set($self->gsxns, $key, $value);
    }
    return $entry;
};

1;
__END__

=head1 NAME

Net::Google::Spreadsheets::Row - A representation class for Google Spreadsheet row.

=head1 SYNOPSIS

=head1 AUTHOR

Nobuo Danjou E<lt>nobuo.danjou@gmail.comE<gt>

=cut

