package Test::GoogleSpreadsheets::Fixture;
use Moose;
use namespace::clean -except => 'meta';
use MooseX::NonMoose;
use Test::More;
use Digest::MD5 qw(md5_hex);

BEGIN {extends 'Test::FITesque::Fixture'};
with 'Test::GoogleSpreadsheets::Setup';

sub check_instance :Test {
    my ($self) = @_;
    isa_ok($self->service, 'Net::Google::Spreadsheets');
}

__PACKAGE__->meta->make_immutable;

1;
