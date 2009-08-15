use t::Util title => 'test for Net::Google::Spreadsheets';
use Test::More;

use Digest::MD5 qw(md5_hex);

ok my $service = service;

{
    my @sheets = $service->spreadsheets;
    ok scalar @sheets;
    isa_ok $sheets[0], 'Net::Google::Spreadsheets::Spreadsheet';
    ok $sheets[0]->title;
    ok $sheets[0]->key;
    ok $sheets[0]->etag;
}

{
    ok my $ss = spreadsheet;
    isa_ok $ss, 'Net::Google::Spreadsheets::Spreadsheet';
    is $ss->title, $t::Util::SPREADSHEET_TITLE;
    like $ss->id, qr{^http://spreadsheets.google.com/feeds/spreadsheets/};
    isa_ok $ss->author, 'XML::Atom::Person';
    is $ss->author->email, config->{username};
    my $key = $ss->key;
    ok length $key, 'key defined';
    my $ss2 = $service->spreadsheet({key => $key});
    ok $ss2;
    isa_ok $ss2, 'Net::Google::Spreadsheets::Spreadsheet';
    is $ss2->key, $key;
    is $ss2->title, $t::Util::SPREADSHEET_TITLE;
}

{
    my @existing = map {$_->title} $service->spreadsheets;
    my $title;
    while (1) {
        $title = md5_hex(time, $$, rand, @existing);
        grep {$_ eq $title} @existing or last; 
    }
    
    my $ss = $service->spreadsheet({title => $title});
    is $ss, undef, "spreadsheet named '$title' shouldn't exit";
    my @ss = $service->spreadsheets({title => $title});
    is scalar @ss, 0;
}

done_testing;
