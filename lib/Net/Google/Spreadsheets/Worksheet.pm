package Net::Google::Spreadsheets::Worksheet;
use Moose;

extends 'Net::Google::Spreadsheets::Base';

has row_count => (
    isa => 'Int',
    is => 'rw',
    default => 100,
);

has col_count => (
    isa => 'Int',
    is => 'rw',
    default => 20,
);

around entry => sub {
    my ($next, $self) = @_;
    my $entry = $next->($self);
    $entry->set($self->gs, 'rowCount', $self->row_count);
    $entry->set($self->gs, 'colCount', $self->col_count);
    return $entry;
};

1;
__END__

=head1 NAME

Net::Google::Spreadsheets::Worksheet - Representation of worksheet.

=head1 SYNOPSYS

=head1 AUTHOR

Nobuo Danjou E<lt>nobuo.danjou@gmail.comE<gt>

=cut
