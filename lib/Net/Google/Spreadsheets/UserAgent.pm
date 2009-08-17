package Net::Google::Spreadsheets::UserAgent;
use Moose;
use namespace::clean -except => 'meta';
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
    lazy_build => 1,
);
sub _build_ua {
    my $self = shift;
    my $ua = LWP::UserAgent->new(
        agent => $self->source,
        requests_redirectable => [],
    );
    $ua->default_headers(
        HTTP::Headers->new(
            Authorization => sprintf('GoogleLogin auth=%s', $self->auth),
            GData_Version => '3.0',
        )
    );
    return $ua;
}

__PACKAGE__->meta->make_immutable;

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
    my $res = eval {$self->ua->request($req)};
    if ($@ || !$res->is_success) {
        die sprintf("request for '%s' failed:\n\t%s\n\t%s\n\t", $uri, ($@ || $res->status_line), ($! || $res->content));
    }
    my $type = $res->content_type;
    if ($res->content_length && $type !~ m{^application/atom\+xml}) {
        die sprintf("Content-Type of response for '%s' is not 'application/atom+xml':  %s", $uri, $type);
    }
    if (my $res_obj = $args->{response_object}) {
        my $obj = eval {$res_obj->new(\($res->content))};
        croak sprintf("response for '%s' is broken: %s", $uri, $@) if $@;
        return $obj;
    }
    return $res;
}

sub feed {
    my ($self, $url, $query) = @_;
    return $self->request(
        {
            uri => $url,
            query => $query || undef,
            response_object => 'XML::Atom::Feed',
        }
    );
}

sub entry {
    my ($self, $url, $query) = @_;
    return $self->request(
        {
            uri => $url,
            query => $query || undef,
            response_object => 'XML::Atom::Entry',
        }
    );
}

sub post {
    my ($self, $url, $entry, $header) = @_;
    return $self->request(
        {
            uri => $url,
            content => $entry->as_xml,
            header => $header || undef,
            content_type => 'application/atom+xml',
            response_object => ref $entry,
        }
    );
}

sub put {
    my ($self, $args) = @_;
    return $self->request(
        {
            method => 'PUT',
            uri => $args->{self}->editurl,
            content => $args->{entry}->as_xml,
            header => {'If-Match' => $args->{self}->etag },
            content_type => 'application/atom+xml',
            response_object => 'XML::Atom::Entry',
        }
    );
}

1;
__END__

=head1 NAME

Net::Google::Spreadsheets::UserAgent - UserAgent for Net::Google::Spreadsheets.

=head1 SEE ALSO

L<http://code.google.com/intl/en/apis/spreadsheets/docs/3.0/developers_guide_protocol.html>

L<http://code.google.com/intl/en/apis/spreadsheets/docs/3.0/reference.html>

L<Net::Google::AuthSub>

L<Net::Google::Spreadsheets>

=head1 AUTHOR

Nobuo Danjou E<lt>nobuo.danjou@gmail.comE<gt>

=cut
