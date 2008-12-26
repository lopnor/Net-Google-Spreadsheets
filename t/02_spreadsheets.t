use strict;
use Test::More;

use Net::Google::Spreadsheets;

my $service;
BEGIN {
    plan skip_all => 'set TEST_NET_GOOGLE_SPREADSHEETS to run this test'
        unless $ENV{TEST_NET_GOOGLE_SPREADSHEETS};
    eval "use Config::Pit";
    plan skip_all => 'This Test needs Config::Pit.' if $@;
    my $config = pit_get('google.com', require => {
            'username' => 'your username',
            'password' => 'your password',
        }
    );
    $service = Net::Google::Spreadsheets->new(
        username => $config->{username},
        password => $config->{password},
    );
    my $title = 'test for Net::Google::Spreadsheets';
    my $sheet = $service->spreadsheet({title => $title});
    plan skip_all => "test spreadsheet '$title' doesn't exist." unless $sheet;
    plan tests => 5;
}
{
    my @sheets = $service->spreadsheets;
    ok scalar @sheets;
    isa_ok $sheets[0], 'Net::Google::Spreadsheets::Spreadsheet';
    ok $sheets[0]->title;
    ok $sheets[0]->key;
    ok $sheets[0]->etag;
}
