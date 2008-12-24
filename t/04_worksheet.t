use strict;
use Test::More;

use Net::Google::Spreadsheets;

my $ss;
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
    $ss = $service->spreadsheet({title => $title});
    plan skip_all => "test spreadsheet '$title' doesn't exist." unless $ss;
    plan tests => 28;
}
{
    my ($ws) = $ss->worksheets;
    isa_ok $ws, 'Net::Google::Spreadsheets::Worksheet';
}
{
    my $before = scalar $ss->worksheets;
    my $ws = $ss->add_worksheet;
    isa_ok $ws, 'Net::Google::Spreadsheets::Worksheet';
    is scalar $ss->worksheets, $before + 1;
    ok grep {$_->id eq $ws->id} $ss->worksheets;
}
{
    my $ws = ($ss->worksheets)[-1];
    my $title = $ws->title . '+add';
    is $ws->title($title), $title;
    is $ws->atom->title, $title;
    is $ws->title, $title;
}
{
    my $ws = ($ss->worksheets)[-1];
    for (1 .. 3) {
        my $col_count = $ws->col_count + 1;
        my $row_count = $ws->row_count + 1;
        is $ws->col_count($col_count), $col_count;
        is $ws->atom->get($ws->gsns, 'colCount'), $col_count;
        is $ws->col_count, $col_count;
        is $ws->row_count($row_count), $row_count;
        is $ws->atom->get($ws->gsns, 'rowCount'), $row_count;
        is $ws->row_count, $row_count;
    }
}
{
    my $before = scalar $ss->worksheets;
    my $ws = ($ss->worksheets)[-1];
    ok $ws->delete;
    is scalar $ss->worksheets, $before - 1;
    ok ! grep {$_ == $ws} $ss->worksheets;
}
