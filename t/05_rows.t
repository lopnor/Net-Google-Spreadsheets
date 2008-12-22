use strict;
use Test::More;

use Net::Google::Spreadsheets;

my $ws;
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
    my $service = Net::Google::Spreadsheets->new(
        username => $config->{username},
        password => $config->{password},
    );
    my $title = 'test for Net::Google::Spreadsheets';
    my $ss = $service->spreadsheet({title => $title});
    plan skip_all => "test spreadsheet '$title' doesn't exist." unless $ss;
    plan tests => 1;
    $ws = $ss->add_worksheet;
}
END {
    $ws->delete;
}
