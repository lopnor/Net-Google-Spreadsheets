use strict;
use Test::More;
use utf8;

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
    plan tests => 14;
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
    my $row = $ws->add_row($value);
    isa_ok $row, 'Net::Google::Spreadsheets::Row';
    is_deeply $row->content, $value;

    is_deeply $row->param, $value;
    is $row->param('name'), $value->{name};
    my $newval = {name => '檀上伸郎'};
    is_deeply $row->param($newval), {
        %$value,
        %$newval,
    };

    my $value2 = {
        name => 'Kazuhiro Osawa',
        nick => 'yappo',
        mail => '',
    };
    $row->content($value2);
    is_deeply $row->content, $value2;
    is scalar $ws->rows, 1;
    ok $row->delete;
    is scalar $ws->rows, 0;
}
{
    $ws->add_row( { name => $_ } ) for qw(danjou lopnor soffritto);
    is scalar $ws->rows, 3;
    my $row = $ws->row({sq => 'name = "lopnor"'});
    isa_ok $row, 'Net::Google::Spreadsheets::Row';
    is_deeply $row->content, {name => 'lopnor', nick => '', mail => ''};
}
END {
    $ws->delete;
}
