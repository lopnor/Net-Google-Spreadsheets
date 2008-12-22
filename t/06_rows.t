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
    plan tests => 8;
    $ws = $ss->add_worksheet;
}
{
    is scalar $ws->rows, 0;
    $ws->batchupdate_cell(
        {col => 1, row => 1, input_value => 'name'},
        {col => 2, row => 1, input_value => 'mail'},
        {col => 3, row => 1, input_value => 'nick'},
    );
    is scalar $ws->rows, 0;
    my $value = {
        name => 'Nobuo Danjou',
        mail => 'nobuo.danjou@gmail.com',
        nick => 'lopnor',
    };
    my $row = $ws->insert_row($value);
    isa_ok $row, 'Net::Google::Spreadsheets::Row';
    is_deeply $row->content, $value;
    my $value2 = {
        name => 'Kazuhiro Osawa',
        nick => 'yappo',
    };
    $row->content($value2);
    is_deeply $row->content, $value2;
    is scalar $ws->rows, 1;
    ok $row->delete;
    is scalar $ws->rows, 0;
}
END {
    $ws->delete;
}
