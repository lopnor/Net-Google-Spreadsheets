package Net::Google::Spreadsheets::Cell;
use Moose;

extends 'Net::Google::Spreadsheets::Base';

has row => (
    isa => 'Int',
    is => 'ro',
);

has col => (
    isa => 'Int',
    is => 'ro',
);

has input_value => (
    isa => 'Str',
    is => 'rw',
    trigger => sub {$_[0]->update},
);

after _update_atom => sub {
    my ($self) = @_;
    my ($elem) = $self->elem->getElementsByTagNameNS($self->gsns->{uri}, 'cell');
    $self->{row} = $elem->getAttribute('row');
    $self->{col} = $elem->getAttribute('col');
    $self->{input_value} = $elem->getAttribute('inputValue');
    $self->{content} = $elem->textContent || '';
};

around entry => sub {
    my ($next, $self) = @_;
    my $entry = $next->($self);
    $entry->set($self->gsns, 'cell', '', 
        {
            row => $self->row,
            col => $self->col,
            inputValue => $self->input_value,
        }
    );
    my $link = XML::Atom::Link->new;
    $link->rel('edit');
    $link->type('application/atom+xml');
    $link->href($self->editurl);
    $entry->link($link);
    $entry->id($self->id);
    return $entry;
};

1;
__END__

=head1 NAME

Net::Google::Spreadsheets::Cell - A representation class for Google Spreadsheet cell.

=head1 SYNOPSIS

=head1 SEE ALSO

L<http://code.google.com/intl/en/apis/spreadsheets/docs/2.0/developers_guide_protocol.html>

L<http://code.google.com/intl/en/apis/spreadsheets/docs/2.0/reference.html>

L<Net::Google::AuthSub>

L<Net::Google::Spreadsheets>

=head1 AUTHOR

Nobuo Danjou E<lt>nobuo.danjou@gmail.comE<gt>

=cut

