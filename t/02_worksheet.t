use strict;
use Test::More;

use Net::Google::Spreadsheets;

my $config;
BEGIN {
    plan skip_all => 'set TEST_NET_GOOGLE_SPREADSHEETS to run this test'
        unless $ENV{TEST_NET_GOOGLE_SPREADSHEETS};
    eval "use Config::Pit";
    plan skip_all => 'This Test need Config::Pit.' if $@;
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
my $title = 'test for Net::Google::Speradsheets';
my $spreadsheet = $service->spreadsheets(
    { 
        'title' => $title,
        'title-exact' => 'true',
    }
)->[0];
{
    ok $spreadsheet;
    isa_ok $spreadsheet, 'Net::Google::Spreadsheets::Spreadsheet';
    is $spreadsheet->title, $title;
    like $spreadsheet->id, qr{^http://spreadsheets.google.com/feeds/spreadsheets/};
    isa_ok $spreadsheet->author, 'XML::Atom::Person';
    is $spreadsheet->author->email, $config->{username};
}
{
    my $ws = $spreadsheet->worksheets->[0];
    isa_ok $ws, 'Net::Google::Spreadsheets::Worksheet';
}
{
    my $before = scalar @{$spreadsheet->worksheets};
    my $ws = $spreadsheet->add_worksheet;
    isa_ok $ws, 'Net::Google::Spreadsheets::Worksheet';
    is scalar @{$spreadsheet->worksheets}, $before + 1;
    ok grep {$_ == $ws} @{$spreadsheet->worksheets};
}
{
    my $ws = $spreadsheet->worksheets->[-1];
    my $title = $ws->title . '+add';
    ok $ws->title($title);
    is $ws->atom->title, $title;
    is $ws->title, $title;
}
{
    my $before = scalar @{$spreadsheet->worksheets};
    my $ws = $spreadsheet->worksheets->[-1];
    ok $ws->delete;
    is scalar @{$spreadsheet->worksheets}, $before - 1;
    ok ! grep {$_ == $ws} @{$spreadsheet->worksheets};
}
