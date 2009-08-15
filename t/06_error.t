use strict;
use Test::More tests => 1;
use Test::Exception;

use Net::Google::Spreadsheets;

throws_ok { 
    my $service = Net::Google::Spreadsheets->new(
        username => 'foo',
        password => 'bar',
    );
} qr{Net::Google::AuthSub login failed};
