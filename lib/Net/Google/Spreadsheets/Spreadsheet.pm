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
    _update_atom => sub {
        my ($self) = @_;
        $self->{worksheet_feed} = $self->atom->content->elem->getAttribute('src');
    },
);

has table_feed => (
    traits => ['Net::Google::Spreadsheets::Traits::Feed'],
    is => 'rw',
    isa => 'Str',
    entry_class => 'Net::Google::Spreadsheets::Table',
    lazy_build => 1,
);

sub _build_table_feed {
    my $self = shift;
    return sprintf('http://spreadsheets.google.com/feeds/%s/tables',$self->key);
}

after _update_atom => sub {
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

=head1 SEE ALSO

L<http://code.google.com/intl/en/apis/spreadsheets/docs/2.0/developers_guide_protocol.html>

L<http://code.google.com/intl/en/apis/spreadsheets/docs/2.0/reference.html>

L<Net::Google::AuthSub>

L<Net::Google::Spreadsheets>

=head1 AUTHOR

Nobuo Danjou E<lt>nobuo.danjou@gmail.comE<gt>

=cut
