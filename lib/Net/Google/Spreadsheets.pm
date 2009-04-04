package Net::Google::Spreadsheets;
use Moose;
use 5.008;

extends 'Net::Google::Spreadsheets::Base';

use Carp;
use Net::Google::AuthSub;
use Net::Google::Spreadsheets::UserAgent;
use Net::Google::Spreadsheets::Spreadsheet;

our $VERSION = '0.02';

BEGIN {
    $XML::Atom::DefaultVersion = 1;
}

has +contents => (
    is => 'ro',
    default => 'http://spreadsheets.google.com/feeds/spreadsheets/private/full'
);

has +service => (
    default => sub {return $_[0]}
);

has source => (
    isa => 'Str',
    is => 'ro',
    required => 1,
    default => sub { __PACKAGE__.'-'.$VERSION },
);

has username => ( isa => 'Str', is => 'ro', required => 1 );
has password => ( isa => 'Str', is => 'ro', required => 1 );

has ua => (
    isa => 'Net::Google::Spreadsheets::UserAgent',
    is => 'ro',
    handles => [qw(request feed entry post put)],
);

sub BUILD {
    my $self = shift;
    my $authsub = Net::Google::AuthSub->new(
        service => 'wise',
        source => $self->source,
    );
    my $res = $authsub->login(
        $self->username,
        $self->password,
    );
    unless ($res && $res->is_success) {
        croak 'Net::Google::AuthSub login failed';
    } 
    $self->{ua} = Net::Google::Spreadsheets::UserAgent->new(
        source => $self->source,
        auth => $res->auth,
    );
}

sub spreadsheets {
    my ($self, $args) = @_;
    if ($args->{key}) {
        my $atom = eval {$self->entry($self->contents.'/'.$args->{key})};
        $atom or return;
        return Net::Google::Spreadsheets::Spreadsheet->new(
            atom => $atom,
            service => $self,
        );
    } else {
        my $cond = $args->{title} ?
        {
            title => $args->{title},
            'title-exact' => 'true'
        } : {};
        my $feed = $self->feed(
            $self->contents,
            $cond,
        );
        return grep {
            (!%$args && 1)
            ||
            ($args->{title} && $_->title eq $args->{title})
        } map {
            Net::Google::Spreadsheets::Spreadsheet->new(
                atom => $_,
                service => $self
            )
        } $feed->entries;
    }
}

sub spreadsheet {
    my ($self, $args) = @_;
    return ($self->spreadsheets($args))[0];
}

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
    }
  );

  # fetch rows
  my @rows = $worksheet->rows;

  # search a row
  my $row = $worksheet->row({sq => 'name = "Nobuo Danjou"'});

  # update content of a row
  $row->content(
    {
        nick => 'lopnor',
        mail => 'nobuo.danjou@gmail.com',
    }
  );

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

=head1 AUTHOR

Nobuo Danjou E<lt>nobuo.danjou@gmail.comE<gt>

=head1 SEE ALSO

L<http://code.google.com/intl/en/apis/spreadsheets/docs/2.0/developers_guide_protocol.html>

L<http://code.google.com/intl/en/apis/spreadsheets/docs/2.0/reference.html>

L<Net::Google::AuthSub>

L<Net::Google::Spreadsheets::Spreadsheet>

L<Net::Google::Spreadsheets::Worksheet>

L<Net::Google::Spreadsheets::Cell>

L<Net::Google::Spreadsheets::Row>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
