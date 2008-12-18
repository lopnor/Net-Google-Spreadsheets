package Net::Google::Spreadsheets::Spreadsheet;
use Moose;

has atom => (
    isa => 'XML::Atom::Entry',
    is => 'ro',
    required => 1,
);

has key => (
    isa => 'Str',
    is => 'ro',
    required => 1,
    lazy => 1,
    default => sub {
    },
);

1;
__END__

=head1 NAME

Net::Google::Spreadsheets::Spreadsheet - Representation of spreadsheet

=head1 SYNOPSYS

=head1 AUTHOR

Nobuo Danjou E<lt>nobuo.danjou@gmail.comE<gt>

=cut
