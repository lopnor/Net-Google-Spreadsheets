package Net::Google::Spreadsheets::Table;
use Moose;
use namespace::clean -except => 'meta';

extends 'Net::Google::Spreadsheets::Base';

after _update_atom => sub {
    my ($self) = @_;
    for my $node ($self->elem->getElementsByTagNameNS($self->gsxns->{uri}, '*')) {
        $self->{content}->{$node->localname} = $node->textContent;
    }
};

around entry => sub {
    my ($next, $self) = @_;
    my $entry = $next->($self);
    while (my ($key, $value) = each %{$self->{content}}) {
        $entry->set($self->gsxns, $key, $value);
    }
    return $entry;
};

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

Net::Google::Spreadsheets::Table - A representation class for Google Spreadsheet table.

=head1 SYNOPSIS

  use Net::Google::Spreadsheets;

  my $service = Net::Google::Spreadsheets->new(
    username => 'mygoogleaccount@example.com',
    password => 'mypassword',
  );

  # get a row
  my $row = $service->spreadsheet(
    {
        title => 'list for new year cards',
    }
  )->worksheet(
    {
        title => 'Sheet1',
    }
  )->row(
    {
        sq => 'id = 1000'
    }
  );

  # get the content of a row
  my $hashref = $row->content;
  my $id = $hashref->{id};
  my $address = $hashref->{address};

  # update a row
  $row->content(
    {
        id => 1000,
        address => 'somewhere',
        zip => '100-0001',
        name => 'Nobuo Danjou',
    }
  );

  # get and set values partially
  
  my $value = $row->param('name');
  # returns 'Nobuo Danjou'
  
  my $newval = $row->param({address => 'elsewhere'});
  # updates address (and keeps other fields) and returns new row value (with all fields)

  my $hashref = $row->param;
  # same as $row->content;

=head1 METHODS

=head2 param

sets and gets content value.

=head1 CAVEATS

Space characters in hash key of rows will be removed when you access rows. See below.

  my $ws = Net::Google::Spreadsheets->new(
    username => 'me@gmail.com', 
    password => 'foobar'
  )->spreadsheet({titile => 'sample'})->worksheet(1);
  $ws->batchupdate_cell(
    {col => 1,row => 1, input_value => 'name'},
    {col => 2,row => 1, input_value => 'mail address'},
  ); 
  $ws->add_row(
    {
        name => 'my name',
        mailaddress => 'me@gmail.com',
  #      above passes, below fails.
  #      'mail address' => 'me@gmail.com',
    }
  );

=head1 ATTRIBUTES

=head2 content

Rewritable attribute. You can get and set the value.

=head1 SEE ALSO

L<http://code.google.com/intl/en/apis/spreadsheets/docs/3.0/developers_guide_protocol.html>

L<http://code.google.com/intl/en/apis/spreadsheets/docs/3.0/reference.html>

L<Net::Google::AuthSub>

L<Net::Google::Spreadsheets>

=head1 AUTHOR

Nobuo Danjou E<lt>nobuo.danjou@gmail.comE<gt>

=cut

