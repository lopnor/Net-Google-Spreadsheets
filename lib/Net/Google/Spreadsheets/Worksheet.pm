package Net::Google::Spreadsheets::Worksheet;
use Moose;
use Net::Google::Spreadsheets::Row;
use Net::Google::Spreadsheets::Cell;

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

has cellsfeed => (
    isa => 'Str',
    is => 'ro',
);

around entry => sub {
    my ($next, $self) = @_;
    my $entry = $next->($self);
    $entry->set($self->gsns, 'rowCount', $self->row_count);
    $entry->set($self->gsns, 'colCount', $self->col_count);
    return $entry;
};

after _update_atom => sub {
    my ($self) = @_;
    $self->{content} = $self->atom->content->elem->getAttribute('src');
    ($self->{cellsfeed}) = map {$_->href} grep {
        $_->rel eq 'http://schemas.google.com/spreadsheets/2006#cellsfeed'
    } $self->atom->link;
    $self->{row_count} = $self->atom->get($self->gsns, 'rowCount');
    $self->{col_count} = $self->atom->get($self->gsns, 'colCount');
};


sub rows {
    my ($self, $cond) = @_;
    return $self->list_contents('Net::Google::Spreadsheets::Row', $cond);
}

sub cell {
    my ($self, $row, $col) = @_;
    $self->cellsfeed or return;
    my $url = sprintf("%s/R%sC%s", $self->cellsfeed, $row, $col);
    return Net::Google::Spreadsheets::Cell->new(
        container => $self,
        atom => $self->service->entry($url),
    );
}

sub batchupdate_cell {
    my ($self, @args) = @_;
    my $feed = XML::Atom::Feed->new;
    for ( @args ) {
        my $id = sprintf("%s/R%sC%s",$self->cellsfeed, $_->{row}, $_->{col});
        $_->{id} = $_->{editurl} = $id;
        my $entry = Net::Google::Spreadsheets::Cell->new($_)->entry;
        $entry->set($self->batchns, operation => '', {type => 'update'});
        $entry->set($self->batchns, id => $id);
        $feed->add_entry($entry);
    }
    my $res_feed = $self->service->post($self->cellsfeed."/batch", $feed, {'If-Match' => '*'});
    $self->sync;
    return map { 
        Net::Google::Spreadsheets::Cell->new(
            atom => $_,
            container => $self,
        )
    } grep {
        my ($node) = $_->elem->getElementsByTagNameNS($self->batchns->{uri}, 'status');
        $node->getAttribute('code') == 200;
    } $res_feed->entries;
}

sub add_row {
    my ($self, $args) = @_;
    my $entry = Net::Google::Spreadsheets::Row->new(
        content => $args,
    )->entry;
    my $atom = $self->service->post($self->content, $entry);
    $self->sync;
    return Net::Google::Spreadsheets::Row->new(
        container => $self,
        atom => $atom,
    );
}

1;
__END__

=head1 NAME

Net::Google::Spreadsheets::Worksheet - Representation of worksheet.

=head1 SYNOPSIS

=head1 AUTHOR

Nobuo Danjou E<lt>nobuo.danjou@gmail.comE<gt>

=cut
