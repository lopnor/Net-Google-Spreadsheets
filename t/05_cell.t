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
    plan tests => 11;
    $ws = $ss->add_worksheet;
}
{
    my $value = 'first cell value';
    my $cell = $ws->cell(1,1);
    isa_ok $cell, 'Net::Google::Spreadsheets::Cell';
    my $previous = $cell->content;
    is $previous, '';
    ok $cell->input_value($value);
    is $cell->content, $value;
}
{
    my $value = 'second cell value';
    my @cells = $ws->batchupdate_cell(
        {row => 1, col => 1, input_value => $value}
    );
    is scalar @cells, 1;
    isa_ok $cells[0], 'Net::Google::Spreadsheets::Cell';
    is $cells[0]->content, $value;
}
{
    my $value1 = 'third cell value';
    my $value2 = 'fourth cell value';
    my @cells = $ws->batchupdate_cell(
        {row => 1, col => 1, input_value => $value1},
        {row => 1, col => 2, input_value => $value2},
    );
    is scalar @cells, 2;
    isa_ok $cells[0], 'Net::Google::Spreadsheets::Cell';
    ok grep {$_->col == 1 && $_->row == 1 && $_->content eq $value1} @cells;
    ok grep {$_->col == 2 && $_->row == 1 && $_->content eq $value2} @cells;
}
END {
    $ws->delete;
}
