package Net::Google::Spreadsheets;
use Moose;

extends 'Net::Google::Spreadsheets::Base';

use Carp;
use Net::Google::AuthSub;
use Net::Google::Spreadsheets::UserAgent;
use Net::Google::Spreadsheets::Spreadsheet;

our $VERSION = '0.01';

BEGIN {
    $XML::Atom::DefaultVersion = 1;
}

has contents => (
    is => 'ro',
    default => 'http://spreadsheets.google.com/feeds/spreadsheets/private/full'
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
    required => 1,
    lazy => 1,
    default => sub {
        my ($self) = @_;
        my $authsub = Net::Google::AuthSub->new(
            service => 'wise',
            source => $self->source,
        );
        my $res = $authsub->login(
            $self->username,
            $self->password,
        );
        $res->is_success or return;
        Net::Google::Spreadsheets::UserAgent->new(
            source => $self->source,
            auth => $res->auth,
        );
    },
    handles => [qw(request feed entry post put)],
);

sub spreadsheets {
    my ($self, $args) = @_;
    my $cond = $args->{title} ? 
        {
            title => $args->{title},
            'title-exact' => 'true'
        } : {};
    my $feed = $self->feed(
        $self->contents,
        $cond
    );
    
    return grep {
        (!%$args && 1)
        ||
        ($args->{key} && $_->key eq $args->{key})
        ||
        ($args->{title} && $_->title eq $args->{title})
    } map {
        Net::Google::Spreadsheets::Spreadsheet->new(
            atom => $_, 
            service => $self
        )
    } $feed->entries;
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
    username => 'myname@gmail.com', 
    password => 'mypassword'
  );
  
  my @spreadsheets = $service->spreadsheets();

  # find a spreadsheet by key
  my $spreadsheet = $service->spreadsheet({key => 'pZV-pns_sm9PtH2WowhU2Ew'});

  # find a spreadsheet by title
  my $spreadsheet = $service->spreadsheet({title => 'list for new year cards'});
  my $worksheet = $spreadsheet->worksheet(1);

  my @fields = $worksheet->fields();

  my $inserted_row = $worksheet->insert(
    {
        name => 'danjou',
    }
  );

  my @rows = $worksheet->rows;

  my $row = $worksheet->row(1);

  $row->update(
    {
        nick => 'lopnor',
        mail => 'nobuo.danjou@gmail.com',
    }
  );

=head1 DESCRIPTION

Net::Google::Spreadsheets is a Perl module for using Google Spreadsheets API.

=head1 AUTHOR

Nobuo Danjou E<lt>nobuo.danjou@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
