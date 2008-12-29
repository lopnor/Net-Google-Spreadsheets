package Net::Google::Spreadsheets::UserAgent;
use Moose;
use Carp;
use LWP::UserAgent;
use HTTP::Headers;
use HTTP::Request;
use URI;
use XML::Atom::Entry;
use XML::Atom::Feed;

has source => (
    isa => 'Str',
    is => 'ro',
    required => 1,
);

has auth => (
    isa => 'Str',
    is => 'rw',
    required => 1,
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
        die sprintf("request for '%s' failed: %s", $uri, $res->status_line);
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
    my ($self, $url, $entry, $header) = @_;
    my $res = $self->request(
        {
            uri => $url,
            content => $entry->as_xml,
            header => $header || undef,
            content_type => 'application/atom+xml',
        }
    );
    return (ref $entry)->new(\($res->content));
}

sub put {
    my ($self, $args) = @_;
    my $res = $self->request(
        {
            method => 'PUT',
            uri => $args->{self}->editurl,
            content => $args->{entry}->as_xml,
            header => {'If-Match' => $args->{self}->etag },
            content_type => 'application/atom+xml',
        }
    );
    return XML::Atom::Entry->new(\($res->content));
}

1;
__END__

=head1 NAME

Net::Google::Spreadsheets::UserAgent - UserAgent for Net::Google::Spreadsheets.

=head1 SEE ALSO

L<http://code.google.com/intl/en/apis/spreadsheets/docs/2.0/developers_guide_protocol.html>

L<http://code.google.com/intl/en/apis/spreadsheets/docs/2.0/reference.html>

L<Net::Google::AuthSub>

L<Net::Google::Spreadsheets>

=head1 AUTHOR

Nobuo Danjou E<lt>nobuo.danjou@gmail.comE<gt>

=cut
