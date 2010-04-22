package Net::Google::Spreadsheets::Table;
use Any::Moose;
use Any::Moose '::Util::TypeConstraints';
use namespace::autoclean;
use Net::Google::DataAPI;
use XML::Atom::Util qw(nodelist first create_element);

with 'Net::Google::DataAPI::Role::Entry';

subtype 'ColumnList'
    => as 'ArrayRef[Net::Google::Spreadsheets::Table::Column]';
coerce 'ColumnList'
    => from 'ArrayRef[HashRef]'
    => via {
        [ map {Net::Google::Spreadsheets::Table::Column->new($_)} @$_ ]
    };
coerce 'ColumnList'
    => from 'ArrayRef[Str]'
    => via {
        my @c;
        my $index = 0;
        for my $value (@$_) {
            push @c, Net::Google::Spreadsheets::Table::Column->new(
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
            push @c, Net::Google::Spreadsheets::Table::Column->new(
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

feedurl record => (
    entry_class => 'Net::Google::Spreadsheets::Record',
    arg_builder => sub {
        my ($self, $args) = @_;
        return {content => $args};
    },
    as_content_src => 1,
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
    my $gsns = $self->ns('gs')->{uri};
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
        push @columns, Net::Google::Spreadsheets::Table::Column->new(
            index => $_->getAttribute('index'),
            name => $_->getAttribute('name'),
        );
    }
    $self->{columns} = \@columns;
};

around to_atom => sub {
    my ($next, $self) = @_;
    my $entry = $next->($self);
    my $gsns = $self->ns('gs')->{uri};
    $entry->summary($self->summary) if $self->summary;
    $entry->set($gsns, 'worksheet', '', {name => $self->worksheet});
    $entry->set($gsns, 'header', '', {row => $self->header});
    my $data = create_element($gsns, 'data');
    $data->setAttribute(startRow => $self->start_row);
    $data->setAttribute(insertionMode => $self->insertion_mode);
    $data->setAttribute(startRow => $self->start_row) if $self->start_row;
    for ( @{$self->columns} ) {
        my $column = create_element($gsns, 'column');
        $column->setAttribute(index => $_->index);
        $column->setAttribute(name => $_->name);
        $data->appendChild($column);
    }
    $entry->set($gsns, 'data', $data);
    return $entry;
};

__PACKAGE__->meta->make_immutable;

package # hide from PAUSE
    Net::Google::Spreadsheets::Table::Column;
use Any::Moose;

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

  # get a table
  my $table = $service->spreadsheet(
    {
        title => 'list for new year cards',
    }
  )->table(
    {
        title => 'sample table',
    }
  );

  # create a record
  my $r = $table->add_record(
    {
        name => 'Nobuo Danjou',
        nick => 'lopnor',
        mail => 'nobuo.danjou@gmail.com',
        age  => '33',
    }
  );

  # get records
  my @records = $table->records;

  # search records
  @records = $table->records({sq => 'age > 20'});
  
  # search a record 
  my $record = $table->record({sq => 'name = "Nobuo Danjou"'});

=head1 METHODS

=head2 records(\%condition)

Returns a list of Net::Google::Spreadsheets::Record objects. Acceptable arguments are:

=over 2

=item * sq

Structured query on the full text in the worksheet. see the URL below for detail.

=item * orderby

Set column name to use for ordering.

=item * reverse

Set 'true' or 'false'. The default is 'false'.

=back

See L<http://code.google.com/intl/en/apis/spreadsheets/docs/3.0/reference.html#RecordParameters> for details.

=head2 record(\%condition)

Returns first item of records(\%condition) if available.

=head2 add_record(\%contents)

Creates new record and returns a Net::Google::Spreadsheets::Record object representing it. 
Arguments are contents of a row as a hashref.

  my $record = $table->add_record(
    {
        name => 'Nobuo Danjou',
        nick => 'lopnor',
        mail => 'nobuo.danjou@gmail.com',
        age  => '33',
    }
  );

=head1 SEE ALSO

L<http://code.google.com/intl/en/apis/spreadsheets/docs/3.0/developers_guide_protocol.html>

L<http://code.google.com/intl/en/apis/spreadsheets/docs/3.0/reference.html>

L<Net::Google::AuthSub>

L<Net::Google::Spreadsheets>

L<Net::Google::Spreadsheets::Spreadsheet>

L<Net::Google::Spreadsheets::Record>

=head1 AUTHOR

Nobuo Danjou E<lt>nobuo.danjou@gmail.comE<gt>

=cut

