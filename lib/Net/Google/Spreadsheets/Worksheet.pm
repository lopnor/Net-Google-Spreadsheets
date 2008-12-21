package Net::Google::Spreadsheets::Worksheet;
use Moose;

extends 'Net::Google::Spreadsheets::Base';

has row_count => (
    isa => 'Int',
    is => 'rw',
    default => 100,
    trigger => sub {$_[0]->update}
);

has col_count => (
    isa => 'Int',
    is => 'rw',
    default => 20,
    trigger => sub {$_[0]->update}
);

around entry => sub {
    my ($next, $self) = @_;
    my $entry = $next->($self);
    $entry->set($self->gs, 'rowCount', $self->row_count);
    $entry->set($self->gs, 'colCount', $self->col_count);
    return $entry;
};

after _update_atom => sub {
    my ($self) = @_;
    $self->{row_count} = $self->atom->get($self->gs, 'rowCount');
    $self->{col_count} = $self->atom->get($self->gs, 'colCount');
};

1;
__END__

=head1 NAME

Net::Google::Spreadsheets::Worksheet - Representation of worksheet.

=head1 SYNOPSYS

=head1 AUTHOR

Nobuo Danjou E<lt>nobuo.danjou@gmail.comE<gt>

=cut
