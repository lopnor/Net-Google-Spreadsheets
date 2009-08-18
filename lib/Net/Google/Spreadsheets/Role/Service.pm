package Net::Google::Spreadsheets::Role::Service;
use Moose::Role;

use Carp;
use Net::Google::AuthSub;
use Net::Google::Spreadsheets::UserAgent;

has source => (
    isa => 'Str',
    is => 'ro',
    required => 1,
    lazy_build => 1,
);

has username => ( isa => 'Str', is => 'ro', required => 1 );
has password => ( isa => 'Str', is => 'ro', required => 1 );

has ua => (
    isa => 'Net::Google::Spreadsheets::UserAgent',
    is => 'ro',
    handles => [qw(request feed entry post put)],
    required => 1,
    lazy_build => 1,
);

sub _build_ua {
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
    return Net::Google::Spreadsheets::UserAgent->new(
        source => $self->source,
        auth => $res->auth,
    );
}

sub BUILD {
    my ($self) = @_;
    $self->ua; #check if login ok?
}

1;
