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

sub row {
    my ($self, $cond) = @_;
    return ($self->rows($cond))[0];
}

sub cells {
    my ($self, $cond) = @_;
    my $feed = $self->service->feed($self->cellsfeed, $cond);
    return map {Net::Google::Spreadsheets::Cell->new(container => $self, atom => $_)} $feed->entries;
}

sub cell {
    my ($self, $args) = @_;
    $self->cellsfeed or return;
    my $url = sprintf("%s/R%sC%s", $self->cellsfeed, $args->{row}, $args->{col});
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

  my $service = Net::Google::Spreadsheets->new(
    username => 'mygoogleaccount@example.com',
    password => 'mypassword',
  );

  my $ss = $service->spreadsheet(
    {
        key => 'key_of_a_spreasheet'
    }
  );

  my $worksheet = $ss->worksheet({title => 'Sheet1'});

  # update cell by batch request
  $worksheet->batchupdate_cell(
    {col => 1, row => 1, input_value => 'name'},
    {col => 2, row => 1, input_value => 'nick'},
    {col => 3, row => 1, input_value => 'mail'},
  );

  # get a cell object
  my $cell = $worksheet->cell({col => 1, row => 1});

  # add a row
  my $new_row = $worksheet->add_row(
    {
        name => 'Nobuo Danjou',
        nick => 'lopnor',
        mail => 'nobuo.danjou@gmail.com',
    }
  );

  # get rows
  my @rows = $worksheet->rows;

  # search a row
  my $row = $worksheet->row({sq => 'name = "Nobuo Danjou"'});

=head1 METHODS

=head2 rows(\%condition)

Returns a list of Net::Google::Spreadsheets::Row objects. Acceptable arguments are:

=over 4

=item sq

Structured query on the full text in the worksheet. see the URL below for detail.

=item orderby

Set column name to use for ordering.

=item reverse

Set 'true' or 'false'. The default is 'false'.

=back

See L<http://code.google.com/intl/en/apis/spreadsheets/docs/2.0/reference.html#ListParameters> for details.

=head2 row(\%condition)

Returns first item of spreadsheets(\%condition) if available.

=head2 cells(\%args)

Returns a list of Net::Google::Spreadsheets::Cell objects. Acceptable arguments are:

=over 4

=item min-row

=item max-row

=item min-col

=item max-col

=item range

=item return-empty

=back

See L<http://code.google.com/intl/en/apis/spreadsheets/docs/2.0/reference.html#CellParameters> for details.

=head2 cell(\%args)

Returns Net::Google::Spreadsheets::Cell object. Arguments are:

=over 4

=item col

=item row

=back

=head2 batchupdate_cell(@args)

update multiple cells with a batch request. Pass a list of hash references containing:

=over 4

=item col

=item row

=item input_value

=back

=head1 SEE ALSO

L<http://code.google.com/intl/en/apis/spreadsheets/docs/2.0/developers_guide_protocol.html>

L<http://code.google.com/intl/en/apis/spreadsheets/docs/2.0/reference.html>

L<Net::Google::AuthSub>

L<Net::Google::Spreadsheets>

=head1 AUTHOR

Nobuo Danjou E<lt>nobuo.danjou@gmail.comE<gt>

=cut
