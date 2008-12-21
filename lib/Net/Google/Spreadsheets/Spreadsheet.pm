package Net::Google::Spreadsheets::Spreadsheet;
use Moose;
use XML::Atom;
use Net::Google::Spreadsheets::Worksheet;

extends 'Net::Google::Spreadsheets::Base';

has worksheets => (
    isa => 'ArrayRef[Net::Google::Spreadsheets::Worksheet]',
    is => 'rw',
    weaken => 1,
    default => sub { return [] },
);

after _update_atom => sub {
    my ($self) = @_;
    $self->{content} = $self->atom->content->elem->getAttribute('src');
    my $feed = $self->service->feed($self->content);
    my @new_ws;
    for my $entry ($feed->entries) {
        my $ws = Net::Google::Spreadsheets::Worksheet->new(
            container => $self,
            atom => $entry,
        );
        push @new_ws, $ws;
        if (my ($orig) = grep {$_->id eq $ws->id} @{$self->worksheets}) {
            $orig->atom($entry) if $orig->etag ne $ws->etag;
        } else {
            push @{$self->worksheets}, $ws;
        }
    }
    $self->worksheets([ grep {my $ws = $_; grep {$ws->id eq $_->id} @new_ws} @{$self->worksheets} ]);
};


sub add_worksheet {
    my ($self, $args) = @_;
    my $title = $args->{title} 
        || "Sheet".(scalar @{$self->worksheets} + 1);
    my $entry = XML::Atom::Entry->new;
    $entry->title($title);
    $entry->set($self->gs, 'colCount', 20);
    $entry->set($self->gs, 'rowCount', 100);
    my $atom = $self->service->post($self->content, $entry);
    my $ws = Net::Google::Spreadsheets::Worksheet->new(
        container => $self,
        atom => $atom,
    );
    push @{$self->worksheets}, $ws;
    return $ws;
}

1;
__END__

=head1 NAME

Net::Google::Spreadsheets::Spreadsheet - Representation of spreadsheet

=head1 SYNOPSYS

=head1 AUTHOR

Nobuo Danjou E<lt>nobuo.danjou@gmail.comE<gt>

=cut
