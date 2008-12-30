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
    plan tests => 25;
    $ws = $ss->add_worksheet;
}
{
    my $value = 'first cell value';
    my $cell = $ws->cell({col => 1, row => 1});
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
    my $value3 = 'fifth cell value';
    {
        my @cells = $ws->batchupdate_cell(
            {row => 1, col => 1, input_value => $value1},
            {row => 1, col => 2, input_value => $value2},
            {row => 2, col => 2, input_value => $value3},
        );
        is scalar @cells, 3;
        isa_ok $cells[0], 'Net::Google::Spreadsheets::Cell';
        ok grep {$_->col == 1 && $_->row == 1 && $_->content eq $value1} @cells;
        ok grep {$_->col == 2 && $_->row == 1 && $_->content eq $value2} @cells;
        ok grep {$_->col == 2 && $_->row == 2 && $_->content eq $value3} @cells;
    }
    {
        my @cells = $ws->cells(
            {
                'min-row' => 1,
                'max-row' => 2,
                'min-col' => 1,
                'max-col' => 2,
            }
        );
        is scalar @cells, 3;
        ok grep {$_->col == 1 && $_->row == 1 && $_->content eq $value1} @cells;
        ok grep {$_->col == 2 && $_->row == 1 && $_->content eq $value2} @cells;
        ok grep {$_->col == 2 && $_->row == 2 && $_->content eq $value3} @cells;
    }
    {
        my @cells = $ws->cells( { range => 'A1:B2' } );
        is scalar @cells, 3;
        ok grep {$_->col == 1 && $_->row == 1 && $_->content eq $value1} @cells;
        ok grep {$_->col == 2 && $_->row == 1 && $_->content eq $value2} @cells;
        ok grep {$_->col == 2 && $_->row == 2 && $_->content eq $value3} @cells;
    }
    {
        my @cells = $ws->cells( { range => 'A1:B2', 'return-empty' => 'true' } );
        is scalar @cells, 4;
        ok grep {$_->col == 1 && $_->row == 2 && $_->content eq ''} @cells;
    }
}
{
    my @cells = $ws->batchupdate_cell(
        {row => 1, col => 1, input_value => 100},
        {row => 1, col => 2, input_value => 200},
        {row => 1, col => 3, input_value => '=A1+B1'},
    );
    is scalar @cells, 3;
    isa_ok $cells[0], 'Net::Google::Spreadsheets::Cell';
    my $result = $ws->cell({ row => 1, col => 3});
    is $result->content, 300;
}
END {
#    $ws->delete;
}
