use strict;
use Test::More;

use Net::Google::Spreadsheets;

my ($service, $config);
BEGIN {
    plan skip_all => 'set TEST_NET_GOOGLE_SPREADSHEETS to run this test'
        unless $ENV{TEST_NET_GOOGLE_SPREADSHEETS};
    eval "use Config::Pit";
    plan skip_all => 'This Test needs Config::Pit.' if $@;
    $config = pit_get('google.com', require => {
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
    plan tests => 15;
}

{
    ok $service->spreadsheets;
}
{
    my $title = 'test for Net::Google::Speradsheets';
    my $ss = $service->spreadsheet({title => $title});
    ok $ss;
    isa_ok $ss, 'Net::Google::Spreadsheets::Spreadsheet';
    is $ss->title, $title;
    like $ss->id, qr{^http://spreadsheets.google.com/feeds/spreadsheets/};
    isa_ok $ss->author, 'XML::Atom::Person';
    is $ss->author->email, $config->{username};
    my $key = $ss->key;
    ok length $key, 'key defined';
    {
        my $ss2 = $service->spreadsheet({key => $key});
        ok $ss2;
        isa_ok $ss2, 'Net::Google::Spreadsheets::Spreadsheet';
        is $ss2->key, $key;
    }
}
{
    my $title = 'test for Net::Google::Speradsheets';
    my $spreadsheet = $service->spreadsheet({ 'title' => $title });
    ok $spreadsheet;
    isa_ok $spreadsheet, 'Net::Google::Spreadsheets::Spreadsheet';
    is $spreadsheet->title, $title;
}
