use strict;
use Test::More;

use Net::Google::Spreadsheets;

my $config;
BEGIN {
    plan skip_all => 'set TEST_NET_GOOGLE_SPREADSHEETS to run this test'
        unless $ENV{TEST_NET_GOOGLE_SPREADSHEETS};
    eval "use Config::Pit";
    plan skip_all => 'This Test needs Config::Pit.' if $@;
    $config = pit_get('google.com', require => {
            'username' => 'your username',
            'password' => 'your password',
        }
    );
    plan tests => 1;
}
my $service = Net::Google::Spreadsheets->new(
    username => $config->{username},
    password => $config->{password},
);
isa_ok $service, 'Net::Google::Spreadsheets';
