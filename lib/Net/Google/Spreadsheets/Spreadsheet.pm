package Net::Google::Spreadsheets::Spreadsheet;
use Moose;
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

sub worksheet {
    my ($self, $cond) = @_;
    return ($self->worksheets($cond))[0];
}

sub worksheets {
    my ($self, $cond) = @_;
    return $self->list_contents('Net::Google::Spreadsheets::Worksheet', $cond);
}

sub add_worksheet {
    my ($self, $args) = @_;
    my $entry = Net::Google::Spreadsheets::Worksheet->new($args || {})->entry;
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
