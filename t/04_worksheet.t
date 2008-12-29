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
    plan tests => 34;
}
{
    my @worksheets = $ss->worksheets;
    ok scalar @worksheets;
}
{
    my $args = {
        title => 'new worksheet',
        row_count => 10,
        col_count => 3,
    };
    my $ws = $ss->add_worksheet($args);
    isa_ok $ws, 'Net::Google::Spreadsheets::Worksheet';
    is $ws->title, $args->{title};
    is $ws->row_count, $args->{row_count};
    is $ws->col_count, $args->{col_count};
    my $ws2 = $ss->worksheet({title => $args->{title}});
    isa_ok $ws2, 'Net::Google::Spreadsheets::Worksheet';
    is $ws2->title, $args->{title};
    is $ws2->row_count, $args->{row_count};
    is $ws2->col_count, $args->{col_count};
    ok $ws2->delete;
    ok ! grep {$_->id eq $ws->id} $ss->worksheets;
    ok ! grep {$_->id eq $ws2->id} $ss->worksheets;
}
{
    my ($ws) = $ss->worksheets;
    isa_ok $ws, 'Net::Google::Spreadsheets::Worksheet';
}
{
    my $before = scalar $ss->worksheets;
    my $ws = $ss->add_worksheet({title => 'new_worksheet'});
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
    for (1 .. 2) {
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
    my @after = $ss->worksheets;
    is scalar @after, $before - 1;
    ok ! grep {$_->id eq $ws->id} @after;
}
