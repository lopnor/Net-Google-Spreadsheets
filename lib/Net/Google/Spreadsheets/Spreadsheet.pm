package Net::Google::Spreadsheets::Spreadsheet;
use Moose;
use namespace::clean -except => 'meta';

extends 'Net::Google::Spreadsheets::Base';

use Net::Google::Spreadsheets::Worksheet;
use Path::Class;
use URI;

has +title => (
    is => 'ro',
);

has key => (
    isa => 'Str',
    is => 'ro',
);

has worksheet_feed => (
    traits => ['Net::Google::Spreadsheets::Traits::Feed'],
    is => 'rw',
    isa => 'Str',
    entry_class => 'Net::Google::Spreadsheets::Worksheet',
    from_atom => sub {
        my ($self) = @_;
        $self->{worksheet_feed} = $self->atom->content->elem->getAttribute('src');
    },
);

has table_feed => (
    traits => ['Net::Google::Spreadsheets::Traits::Feed'],
    is => 'rw',
    isa => 'Str',
    entry_class => 'Net::Google::Spreadsheets::Table',
    required => 1,
    lazy_build => 1,
);

sub _build_table_feed {
    my $self = shift;
    return sprintf('http://spreadsheets.google.com/feeds/%s/tables',$self->key);
}

after from_atom => sub {
    my ($self) = @_;
    $self->{key} = file(URI->new($self->id)->path)->basename;
};

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

Net::Google::Spreadsheets::Spreadsheet - Representation of spreadsheet.

=head1 SYNOPSIS

  use Net::Google::Spreadsheets;

  my $service = Net::Google::Spreadsheets->new(
    username => 'mygoogleaccount@example.com',
    password => 'mypassword'
  );

  my @spreadsheets = $service->spreadsheets();

  # find a spreadsheet by key
  my $spreadsheet = $service->spreadsheet(
    {
        key => 'key_of_a_spreasheet'
    }
  );

  # find a spreadsheet by title
  my $spreadsheet_by_title = $service->spreadsheet(
    {
        title => 'list for new year cards'
    }
  );

  # create a worksheet
  my $worksheet = $spreadsheet->add_worksheet(
    {
        title => 'foobar',
        col_count => 10,
        row_count => 100,
    }
  );

  # list worksheets
  my @ws = $spreadsheet->worksheets;
  # find a worksheet
  my $ws = $spreadsheet->worksheet({title => 'fooba'});

  # create a table
  my $table = $spreadsheet->add_table(
    {
        title => 'sample table',
        worksheet => $worksheet,
        columns => ['id', 'username', 'mail', 'password'],
    }
  );

  # list tables
  my @t = $spreadsheet->tables;
  # find a worksheet
  my $t = $spreadsheet->table({title => 'sample table'});


=head1 METHODS

=head2 worksheets(\%condition)

Returns a list of Net::Google::Spreadsheets::Worksheet objects. Acceptable arguments are:

=over 4

=item title

=item title-exact

=back

=head2 worksheet(\%condition)

Returns first item of worksheets(\%condition) if available.

=head2 add_worksheet(\%attribuets)

Creates new worksheet and returns a Net::Google::Spreadsheets::Worksheet object representing it. 
Arguments (all optional) are:

=over 4

=item title

=item col_count

=item row_count

=back

=head2 tables(\%condition)

Returns a list of Net::Google::Spreadsheets::Table objects. Acceptable arguments are:

=over 4

=item title

=item title-exact

=back

=head2 table(\%condition)

Returns first item of tables(\%condition) if available.

=head2 add_table(\%attribuets)

Creates new table and returns a Net::Google::Spreadsheets::Table object representing it.
Arguments are:

=over 4

=item title (optional)

=item summary (optional)

=item worksheet

Worksheet where the table lives. worksheet instance or the title.

=item header (optional, default = 1)

Row number of header

=item start_row (optional, default = 2)

The index of the first row of the data section.

=item insertion_mode (optional, default = 'overwrite')

Insertion mode. 'insert' inserts new row into the worksheet when creating record, 'overwrite' tries to use existing rows in the worksheet.

=item columns

Columns of the table. you can specify them as hashref, arrayref, arrayref of hashref.

  $ss->add_table(
    {
        worksheet => $ws,
        columns => [
            {index => 1, name => 'foo'},
            {index => 2, name => 'bar'},
            {index => 3, name => 'baz'},
        ],
    }
  );

  $ss->add_table(
    {
        worksheet => $ws,
        columns => {
            A => 'foo',
            B => 'bar',
            C => 'baz',
        }
    }
  );

  $ss->add_table(
    {
        worksheet => $ws,
        columns => ['foo', 'bar', 'baz'],
    }
  );

'index' of the first case and hash key of the second case is column index of the worksheet. 
In the third case, the columns is automatically placed to the columns of the worksheet 
from 'A' to 'Z' order.

=back

=head1 SEE ALSO

L<http://code.google.com/intl/en/apis/spreadsheets/docs/3.0/developers_guide_protocol.html>

L<http://code.google.com/intl/en/apis/spreadsheets/docs/3.0/reference.html>

L<Net::Google::AuthSub>

L<Net::Google::Spreadsheets>

L<Net::Google::Spreadsheets::Worksheet>

L<Net::Google::Spreadsheets::Table>

=head1 AUTHOR

Nobuo Danjou E<lt>nobuo.danjou@gmail.comE<gt>

=cut
