package Net::Google::Spreadsheets::Table;
use Moose;
use Moose::Util::TypeConstraints;
use namespace::clean -except => 'meta';
use XML::Atom::Util qw(nodelist first create_element);

subtype 'ColumnList'
    => as 'ArrayRef[Net::Google::Spreadsheets::Column]';
coerce 'ColumnList'
    => from 'ArrayRef[HashRef]'
    => via {
        [ map {Net::Google::Spreadsheets::Column->new($_)} @$_ ]
    };
coerce 'ColumnList'
    => from 'ArrayRef[Str]'
    => via {
        my @c;
        my $index = 0;
        for my $value (@$_) {
            push @c, Net::Google::Spreadsheets::Column->new(
                index => ++$index,
                name => $value,
            );
        }
        \@c;
    };
coerce 'ColumnList'
    => from 'HashRef'
    => via {
        my @c;
        while (my ($key, $value) = each(%$_)) {
            push @c, Net::Google::Spreadsheets::Column->new(
                index => $key,
                name => $value,
            );
        }
        \@c;
    };

subtype 'WorksheetName'
    => as 'Str';
coerce 'WorksheetName'
    => from 'Net::Google::Spreadsheets::Worksheet'
    => via {
        $_->title
    };

extends 'Net::Google::Spreadsheets::Base';

has record_feed => (
    traits => ['Net::Google::Spreadsheets::Traits::Feed'],
    is => 'ro',
    isa => 'Str',
    entry_class => 'Net::Google::Spreadsheets::Record',
    entry_arg_builder => sub {
        my ($self, $args) = @_;
        return {content => $args};
    },
    from_atom => sub {
        my $self = shift;
        $self->{record_feed} = first($self->elem, '', 'content')->getAttribute('src');
    },
);

has summary => ( is => 'rw', isa => 'Str' );
has worksheet => ( is => 'ro', isa => 'WorksheetName', coerce => 1 );
has header => ( is => 'ro', isa => 'Int', required => 1, default => 1 ); 
has start_row => ( is => 'ro', isa => 'Int', required => 1, default => 2 );
has num_rows => ( is => 'ro', isa => 'Int' );
has columns => ( is => 'ro', isa => 'ColumnList', coerce => 1 );
has insertion_mode => ( is => 'ro', isa => (enum ['insert', 'overwrite']), default => 'overwrite' );

after from_atom => sub {
    my ($self) = @_;
    my $gsns = $self->gsns->{uri};
    my $elem = $self->elem;
    $self->{summary} = $self->atom->summary;
    $self->{worksheet} = first( $elem, $gsns, 'worksheet')->getAttribute('name');
    $self->{header} = first( $elem, $gsns, 'header')->getAttribute('row');
    my @columns;
    my $data = first($elem, $gsns, 'data');
    $self->{insertion_mode} = $data->getAttribute('insertionMode');
    $self->{start_row} = $data->getAttribute('startRow');
    $self->{num_rows} = $data->getAttribute('numRows');
    for (nodelist($data, $gsns, 'column')) {
        push @columns, Net::Google::Spreadsheets::Column->new(
            index => $_->getAttribute('index'),
            name => $_->getAttribute('name'),
        );
    }
    $self->{columns} = \@columns;
};

around to_atom => sub {
    my ($next, $self) = @_;
    my $entry = $next->($self);
    $entry->summary($self->summary) if $self->summary;
    $entry->set($self->gsns, 'worksheet', '', {name => $self->worksheet});
    $entry->set($self->gsns, 'header', '', {row => $self->header});
    my $data = create_element($self->gsns, 'data');
    $data->setAttribute(startRow => $self->start_row);
    $data->setAttribute(insertionMode => $self->insertion_mode);
    $data->setAttribute(startRow => $self->start_row) if $self->start_row;
    for ( @{$self->columns} ) {
        my $column = create_element($self->gsns, 'column');
        $column->setAttribute(index => $_->index);
        $column->setAttribute(name => $_->name);
        $data->appendChild($column);
    }
    $entry->set($self->gsns, 'data', $data);
    return $entry;
};

__PACKAGE__->meta->make_immutable;

package # hide from PAUSE
    Net::Google::Spreadsheets::Column;
use Moose;

has 'index' => ( is => 'ro', isa => 'Str' );
has 'name' => ( is => 'ro', isa => 'Str' );

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

