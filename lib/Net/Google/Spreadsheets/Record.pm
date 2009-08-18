package Net::Google::Spreadsheets::Record;
use Moose;
use namespace::clean -except => 'meta';
use XML::Atom::Util qw(nodelist);

with 
    'Net::Google::Spreadsheets::Role::Base',
    'Net::Google::Spreadsheets::Role::HasContent';

after from_atom => sub {
    my ($self) = @_;
    for my $node (nodelist($self->elem, $self->gsns->{uri}, 'field')) {
        $self->{content}->{$node->getAttribute('name')} = $node->textContent;
    }
};

around to_atom => sub {
    my ($next, $self) = @_;
    my $entry = $next->($self);
    while (my ($key, $value) = each %{$self->{content}}) {
        $entry->add($self->gsns, 'field', $value, {name => $key});
    }
    return $entry;
};

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Net::Google::Spreadsheets::Record - A representation class for Google Spreadsheet record.

=head1 SYNOPSIS

  use Net::Google::Spreadsheets;

  my $service = Net::Google::Spreadsheets->new(
    username => 'mygoogleaccount@example.com',
    password => 'mypassword',
  );

  # get a record
  my $record = $service->spreadsheet(
    {
        title => 'list for new year cards',
    }
  )->table(
    {
        title => 'addressbook',
    }
  )->record(
    {
        sq => 'id = 1000',
    }
  );

  # get the content of a row
  my $hashref = $record->content;
  my $id = $hashref->{id};
  my $address = $hashref->{address};

  # update a row
  $record->content(
    {
        id => 1000,
        address => 'somewhere',
        zip => '100-0001',
        name => 'Nobuo Danjou',
    }
  );

  # get and set values partially
  
  my $value = $record->param('name');
  # returns 'Nobuo Danjou'
  
  my $newval = $record->param({address => 'elsewhere'});
  # updates address (and keeps other fields) and returns new record value (with all fields)

  my $hashref2 = $record->param;
  # same as $record->content;

=head1 METHODS

=head2 param

sets and gets content value.

=head1 ATTRIBUTES

=head2 content

Rewritable attribute. You can get and set the value.

=head1 SEE ALSO

L<http://code.google.com/intl/en/apis/spreadsheets/docs/3.0/developers_guide_protocol.html>

L<http://code.google.com/intl/en/apis/spreadsheets/docs/3.0/reference.html>

L<Net::Google::AuthSub>

L<Net::Google::Spreadsheets>

L<Net::Google::Spreadsheets::Table>

L<Net::Google::Spreadsheets::Row>

=head1 AUTHOR

Nobuo Danjou E<lt>nobuo.danjou@gmail.comE<gt>

=cut

