package Net::Google::Spreadsheets;
use Moose;
use Carp;
use Net::Google::AuthSub;
use Net::Google::Spreadsheets::Spreadsheet;
use LWP::UserAgent;
use XML::Atom::Feed;
use URI;
use HTTP::Headers;

our $VERSION = '0.01';

has username => ( isa => 'Str', is => 'ro', required => 1 );
has password => ( isa => 'Str', is => 'ro', required => 1 );

has source => (
    isa => 'Str',
    is => 'ro',
    required => 1,
    default => sub { __PACKAGE__.'-'.$VERSION },
);

has auth => (
    isa => 'Str',
    is => 'rw',
    required => 1,
    lazy => 1,
    default => sub {
        my $self = shift;
        my $authsub = Net::Google::AuthSub->new(
            service => 'wise',
            source => $self->source,
        );
        my $res = $authsub->login(
            $self->username,
            $self->password,
        );
        $res->is_success or return;
        return $res->auth;
    },
);

has host => (
    isa => 'Str',
    is => 'ro',
    required => 1,
    default => 'spreadsheets.google.com',
);

has ua => (
    isa => 'LWP::UserAgent',
    is => 'ro',
    required => 1,
    lazy => 1,
    default => sub {
        my $self = shift;
        my $ua = LWP::UserAgent->new(
            agent => $self->source,
        );
        $ua->default_headers(
            HTTP::Headers->new(
                Authorization => sprintf('GoogleLogin auth=%s', $self->auth),
                GData_Version => 2,
            )
        );
        return $ua;
    }
);

sub list_spreadsheets {
    my ($self, $cond) = @_;
    my $uri = URI->new("http://".$self->host);
    $uri->path('/feeds/spreadsheets/private/full');
    $uri->query_form($cond) if $cond;
    my $req = HTTP::Request->new(GET => "$uri");
    my $res = $self->ua->request($req);
    unless ($res->is_success) {
        croak "request failed: ",$res->code;
    }
    my $feed = XML::Atom::Feed->new(\($res->content));
    return map { Net::Google::Spreadsheets::Spreadsheet->new(atom => $_) } $feed->entries;
}

1;
__END__

=head1 NAME

Net::Google::Spreadsheets - A Perl module for using Google Spreadsheets API.

=head1 SYNOPSIS

  use Net::Google::Spreadsheets;

  my $api = Net::Google::Spreadsheets->new;
  my $res = $api->login(
    {
        username => 'myname@gmail.com', 
        password => 'mypassword'
    }
  );
  
  my @spreadsheets = $api->list();

  my $spreadsheet = $api->spreadsheet('pZV-pns_sm9PtH2WowhU2Ew');
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
