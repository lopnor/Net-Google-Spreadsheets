package Net::Google::Spreadsheets;
use Moose;
use Carp;
use Net::Google::AuthSub;
use Net::Google::Spreadsheets::Spreadsheet;
use LWP::UserAgent;
use XML::Atom;
use XML::Atom::Feed;
use URI;
use HTTP::Headers;

our $VERSION = '0.01';

BEGIN {
    $XML::Atom::DefaultVersion = 1;
}

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

sub spreadsheets {
    my ($self, $cond) = @_;
    my $feed = $self->feed(
        'http://'.$self->host.'/feeds/spreadsheets/private/full',
        $cond
    );
    return [ map { 
        Net::Google::Spreadsheets::Spreadsheet->new(
            atom => $_,
            service => $self,
        ) 
    } $feed->entries ];
}

sub request {
    my ($self, $args) = @_;
    my $method = delete $args->{method};
    $method ||= $args->{content} ? 'POST' : 'GET';
    my $uri = URI->new($args->{'uri'});
    $uri->query_form($args->{query}) if $args->{query};
    my $req = HTTP::Request->new($method => "$uri");
    $req->content($args->{content}) if $args->{content};
    $req->header('Content-Type' => $args->{content_type}) if $args->{content_type};
    if ($args->{header}) {
        while (my @pair = each %{$args->{header}}) {
            $req->header(@pair);
        }
    }
    my $res = $self->ua->request($req);
    unless ($res->is_success) {
        warn $res->request->as_string;
        warn $res->as_string;
        croak "request failed: ",$res->code;
    }
    return $res;
}

sub feed {
    my ($self, $url, $query) = @_;
    my $res = $self->request(
        {
            uri => $url,
            query => $query || undef,
        }
    );
    return XML::Atom::Feed->new(\($res->content));
}

sub entry {
    my ($self, $url, $query) = @_;
    my $res = $self->request(
        {
            uri => $url,
            query => $query || undef,
        }
    );
    return XML::Atom::Entry->new(\($res->content));
}

sub post {
    my ($self, $url, $entry, $query) = @_;
    my $res = $self->request(
        {
            uri => $url,
            query => $query || undef,
            content => $entry->as_xml,
            content_type => 'application/atom+xml',
        }
    );
    return XML::Atom::Entry->new(\($res->content));
}

sub put {
    my ($self, $args) = @_;
    my $res = $self->request(
        {
            method => 'PUT',
            uri => $args->{self}->editurl,
            content => $args->{entry}->as_xml,
            header => {'If-Match' => $args->{self}->etag},
#            header => {'If-Match' => '*'},
            content_type => 'application/atom+xml',
        }
    );
    return XML::Atom::Entry->new(\($res->content));
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
