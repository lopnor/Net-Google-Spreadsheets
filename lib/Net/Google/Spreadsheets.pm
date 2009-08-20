package Net::Google::Spreadsheets;
use Moose;
use namespace::clean -except => 'meta';
use 5.008001;

with 
    'Net::Google::Spreadsheets::Role::Base',
    'Net::Google::Spreadsheets::Role::Service';

our $VERSION = '0.06';

has spreadsheet_feed => (
    traits => ['Net::Google::Spreadsheets::Traits::Feed'],
    is => 'ro',
    isa => 'Str',
    default => 'http://spreadsheets.google.com/feeds/spreadsheets/private/full',
    entry_class => 'Net::Google::Spreadsheets::Spreadsheet',
);

__PACKAGE__->meta->make_immutable;

sub _build_service {return $_[0]}

sub _build_source { return __PACKAGE__. '-' . $VERSION }

1;
__END__

=head1 NAME

Net::Google::Spreadsheets - A Perl module for using Google Spreadsheets API.

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

  # find a worksheet by title
  my $worksheet = $spreadsheet->worksheet(
    {
        title => 'Sheet1'
    }
  );

  # create a worksheet
  my $new_worksheet = $spreadsheet->add_worksheet(
    {
        title => 'Sheet2',
        row_count => 100,
        col_count => 3,
    }
  );

  # update cell by batch request
  $worksheet->batchupdate_cell(
    {row => 1, col => 1, input_value => 'name'},
    {row => 1, col => 2, input_value => 'nick'},
    {row => 1, col => 3, input_value => 'mail'},
    {row => 1, col => 4, input_value => 'age'},
  );

  # get a cell
  my $cell = $worksheet->cell({col => 1, row => 1});

  # update input value of a cell
  $cell->input_value('new value');

  # add a row
  my $new_row = $worksheet->add_row(
    {
        name => 'Nobuo Danjou',
        nick => 'lopnor',
        mail => 'nobuo.danjou@gmail.com',
        age  => '33',
    }
  );

  # fetch rows
  my @rows = $worksheet->rows;

  # or fetch rows with query
  
  @rows = $worksheet->rows({sq => 'age > 20'});

  # search a row
  my $row = $worksheet->row({sq => 'name = "Nobuo Danjou"'});

  # update content of a row
  $row->content(
    {
        nick => 'lopnor',
        mail => 'nobuo.danjou@gmail.com',
    }
  );

  # delete the row
  $row->delete;

  # delete the worksheet
  $worksheet->delete;

  # create a table
  my $table = $spreadsheet->add_table(
    {
        worksheet => $new_worksheet,
        columns => ['name', 'nick', 'mail address', 'age'],
    }
  );

  # add a record
  my $record = $table->add_record(
    {
        name => 'Nobuo Danjou',
        nick => 'lopnor',
        'mail address' => 'nobuo.danjou@gmail.com',
        age  => '33',
    }
  );

  # find a record
  my $found = $table->record(
    {
        sq => '"mail address" = "nobuo.danjou@gmail.com"'
    }
  );

  # delete it
  $found->delete;

  # delete table
  $table->delete;

=head1 DESCRIPTION

Net::Google::Spreadsheets is a Perl module for using Google Spreadsheets API.

=head1 METHODS

=head2 new

Creates Google Spreadsheet API client. It takes arguments below:

=over 4

=item username

Username for Google. This should be full email address format like 'mygoogleaccount@example.com'.

=item password

Password corresponding to the username.

=item source

Source string to pass to Net::Google::AuthSub.

=back

=head2 spreadsheets(\%condition)

returns list of Net::Google::Spreadsheets::Spreadsheet objects. Acceptable arguments are:

=over 4

=item title

title of the spreadsheet.

=item title-exact

whether title search should match exactly or not.

=item key

key for the spreadsheet. You can get the key via the URL for the spreadsheet.
http://spreadsheets.google.com/ccc?key=key

=back

=head2 spreadsheet(\%condition)

Returns first item of spreadsheets(\%condition) if available.

=head1 TESTING

To test this module, you have to prepare as below.

=over 4

=item create a spreadsheet by hand

Go to L<http://docs.google.com> and create a spreadsheet.

=item set SPREADSHEET_TITLE environment variable

  export SPREADSHEET_TITLE='my test spreadsheet'

or so.

=item set username and password for google.com via Config::Pit

install Config::Pit and type 

  ppit set google.com

then some editor comes up and type your username and password like

  ---
  username: myname@gmail.com
  password: foobarbaz

=item run tests

as always,

  perl Makefile.PL
  make
  make test

=back

=head1 AUTHOR

Nobuo Danjou E<lt>nobuo.danjou@gmail.comE<gt>

=head1 SEE ALSO

L<http://code.google.com/intl/en/apis/spreadsheets/docs/3.0/developers_guide_protocol.html>

L<http://code.google.com/intl/en/apis/spreadsheets/docs/3.0/reference.html>

L<Net::Google::AuthSub>

L<Net::Google::Spreadsheets::Spreadsheet>

L<Net::Google::Spreadsheets::Worksheet>

L<Net::Google::Spreadsheets::Cell>

L<Net::Google::Spreadsheets::Row>

L<Net::Google::Spreadsheets::Table>

L<Net::Google::Spreadsheets::Record>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
