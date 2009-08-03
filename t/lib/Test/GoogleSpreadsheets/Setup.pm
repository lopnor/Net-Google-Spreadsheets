package Test::GoogleSpreadsheets::Setup;
use Moose::Role;
use Test::More;
use Net::Google::Spreadsheets;

has service => (
    is => 'ro',
    isa => 'Net::Google::Spreadsheets',
    required => 1,
    lazy_build => 1,
);

has config => (
    is => 'ro',
    isa => 'HashRef',
    required => 1,
    lazy_build => 1,
);

sub _build_service {
    my ($self) = @_;
    return Net::Google::Spreadsheets->new(
        username => $self->config->{username},
        password => $self->config->{password},
    );
}

sub _build_config {
    my ($self, $key) = @_;
    my $config = Config::Pit::get('google.com');
    return $config;
}

1;
