package Net::Google::Spreadsheets::Row;
use Moose;

extends 'Net::Google::Spreadsheets::Base';

has +content => (
    isa => 'HashRef',
    is => 'rw',
    default => sub { +{} },
    trigger => sub {
        $_[0]->update
    },
);

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

sub param {
    my ($self, $arg) = @_;
    return $self->content unless $arg;
    if (ref $arg && (ref $arg eq 'HASH')) {
        return $self->content(
            {
                %{$self->content},
                %$arg,
            }
        );
    } else {
        return $self->content->{$arg};
    }
}

1;
__END__

=head1 NAME

Net::Google::Spreadsheets::Row - A representation class for Google Spreadsheet row.

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


=head1 ATTRIBUTES

=head2 content

Rewritable attribute. You can get and set the value.

=head1 SEE ALSO

L<http://code.google.com/intl/en/apis/spreadsheets/docs/2.0/developers_guide_protocol.html>

L<http://code.google.com/intl/en/apis/spreadsheets/docs/2.0/reference.html>

L<Net::Google::AuthSub>

L<Net::Google::Spreadsheets>

=head1 AUTHOR

Nobuo Danjou E<lt>nobuo.danjou@gmail.comE<gt>

=cut

