package Net::Google::Spreadsheets::Worksheet;
use Moose;
use Carp;
use namespace::clean -except => 'meta';

extends 'Net::Google::Spreadsheets::Base';

use Net::Google::Spreadsheets::Cell;

has row_feed => (
    traits => ['Net::Google::Spreadsheets::Traits::Feed'],
    is => 'ro',
    isa => 'Str',
    entry_class => 'Net::Google::Spreadsheets::Row',
    entry_arg_builder => sub {
        my ($self, $args) = @_;
        return {content => $args};
    },
    from_atom => sub {
        my $self = shift;
        $self->{row_feed} = $self->atom->content->elem->getAttribute('src');
    },
);

has cellsfeed => (
    traits => ['Net::Google::Spreadsheets::Traits::Feed'],
    is => 'ro',
    isa => 'Str',
    entry_class => 'Net::Google::Spreadsheets::Cell',
    entry_arg_builder => sub {
        my ($self, $args) = @_;
        croak 'you can\'t call add_cell!';
    },
    query_arg_builder => sub {
        my ($self, $args) = @_;
        if (my $col = delete $args->{col}) {
            $args->{'max-col'} = $col;
            $args->{'min-col'} = $col;
            $args->{'return-empty'} = 'true';
        }
        if (my $row = delete $args->{row}) {
            $args->{'max-row'} = $row;
            $args->{'min-row'} = $row;
            $args->{'return-empty'} = 'true';
        }
        return $args;
    },
    from_atom => sub {
        my ($self) = @_;
        ($self->{cellsfeed}) = map {$_->href} grep {
            $_->rel eq 'http://schemas.google.com/spreadsheets/2006#cellsfeed'
        } $self->atom->link;
    }
);

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

around to_atom => sub {
    my ($next, $self) = @_;
    my $entry = $next->($self);
    $entry->set($self->gsns, 'rowCount', $self->row_count);
    $entry->set($self->gsns, 'colCount', $self->col_count);
    return $entry;
};

after from_atom => sub {
    my ($self) = @_;
    $self->{row_count} = $self->atom->get($self->gsns, 'rowCount');
    $self->{col_count} = $self->atom->get($self->gsns, 'colCount');
};

__PACKAGE__->meta->make_immutable;

sub batchupdate_cell {
    my ($self, @args) = @_;
    my $feed = XML::Atom::Feed->new;
    for ( @args ) {
        my $id = sprintf("%s/R%sC%s",$self->cellsfeed, $_->{row}, $_->{col});
        $_->{id} = $_->{editurl} = $id;
        my $entry = Net::Google::Spreadsheets::Cell->new($_)->to_atom;
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
        my $node = XML::Atom::Util::first(
            $_->elem, $self->batchns->{uri}, 'status'
        );
        $node->getAttribute('code') == 200;
    } $res_feed->entries;
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
    {col => 4, row => 1, input_value => 'age'},
  );

  # get a cell object
  my $cell = $worksheet->cell({col => 1, row => 1});

  # add a row
  my $new_row = $worksheet->add_row(
    {
        name => 'Nobuo Danjou',
        nick => 'lopnor',
        mail => 'nobuo.danjou@gmail.com',
        age  => '33',
    }
  );

  # get rows
  my @rows = $worksheet->rows;

  # search rows
  @rows = $worksheet->rows({sq => 'age > 20'});

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

See L<http://code.google.com/intl/en/apis/spreadsheets/docs/3.0/reference.html#ListParameters> for details.

=head2 row(\%condition)

Returns first item of rows(\%condition) if available.

=head2 add_row(\%contents)

Creates new row and returns a Net::Google::Spreadsheets::Row object representing it. Arguments are
contents of a row as a hashref.

  my $row = $ws->add_row(
    {
        name => 'Nobuo Danjou',
        nick => 'lopnor',
        mail => 'nobuo.danjou@gmail.com',
        age  => '33',
    }
  );

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

See L<http://code.google.com/intl/en/apis/spreadsheets/docs/3.0/reference.html#CellParameters> for details.

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

L<http://code.google.com/intl/en/apis/spreadsheets/docs/3.0/developers_guide_protocol.html>

L<http://code.google.com/intl/en/apis/spreadsheets/docs/3.0/reference.html>

L<Net::Google::AuthSub>

L<Net::Google::Spreadsheets>

=head1 AUTHOR

Nobuo Danjou E<lt>nobuo.danjou@gmail.comE<gt>

=cut
