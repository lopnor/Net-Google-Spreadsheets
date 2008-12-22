package Net::Google::Spreadsheets::Spreadsheet;
use Moose;
use XML::Atom;
use Net::Google::Spreadsheets::Worksheet;
use Path::Class;

extends 'Net::Google::Spreadsheets::Base';

has +title => (
    is => 'ro',
);

has key => (
    isa => 'Str',
    is => 'ro',
    required => 1,
    lazy => 1,
    default => sub {
        my $self = shift;
        my $key = file(URI->new($self->id)->path)->basename;
        return $key;
    }
);

after _update_atom => sub {
    my ($self) = @_;
    $self->{content} = $self->atom->content->elem->getAttribute('src');
};

sub worksheets {
    my ($self, $cond) = @_;
    return $self->list_contents('Net::Google::Spreadsheets::Worksheet', $cond);
}

sub add_worksheet {
    my ($self, $args) = @_;
    my $entry = Net::Google::Spreadsheets::Worksheet->new($args)->entry;
    my $atom = $self->service->post($self->content, $entry);
    $self->sync;
    return Net::Google::Spreadsheets::Worksheet->new(
        container => $self,
        atom => $atom,
    );
}

1;
__END__

=head1 NAME

Net::Google::Spreadsheets::Spreadsheet - Representation of spreadsheet

=head1 SYNOPSIS

=head1 AUTHOR

Nobuo Danjou E<lt>nobuo.danjou@gmail.comE<gt>

=cut
