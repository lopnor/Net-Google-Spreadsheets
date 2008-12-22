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
    plan tests => 18;
}
{
    my $ws = $ss->worksheets->[0];
    isa_ok $ws, 'Net::Google::Spreadsheets::Worksheet';
}
{
    my $before = scalar @{$ss->worksheets};
    my $ws = $ss->add_worksheet;
    isa_ok $ws, 'Net::Google::Spreadsheets::Worksheet';
    is scalar @{$ss->worksheets}, $before + 1;
    ok grep {$_ == $ws} @{$ss->worksheets};
}
{
    my $ws = $ss->worksheets->[-1];
    my $title = $ws->title . '+add';
    is $ws->title($title), $title;
    is $ws->atom->title, $title;
    is $ws->title, $title;
}
{
    my $ws = $ss->worksheets->[-1];
    my $etag_before = $ws->etag;
    my $before = $ws->col_count;
    my $col_count = $before + 1;
    is $ws->col_count($col_count), $col_count;
    is $ws->atom->get($ws->gs, 'colCount'), $col_count;
    is $ws->col_count, $col_count;
    isnt $ws->etag, $etag_before;
}
{
    my $ws = $ss->worksheets->[-1];
    my $ss_etag_before = $ss->etag;
    my $etag_before = $ws->etag;
    my $before = $ws->row_count;
    my $row_count = $before + 1;
    is $ws->row_count($row_count), $row_count;
    is $ws->atom->get($ws->gs, 'rowCount'), $row_count;
    is $ws->row_count, $row_count;
    isnt $ws->etag, $etag_before;
}
{
    my $before = scalar @{$ss->worksheets};
    my $ws = $ss->worksheets->[-1];
    ok $ws->delete;
    is scalar @{$ss->worksheets}, $before - 1;
    ok ! grep {$_ == $ws} @{$ss->worksheets};
}
