use strict;
use Test::More;
use Test::Exception;
use Test::MockModule;
use Test::MockObject;
use LWP::UserAgent;

use Net::Google::Spreadsheets;

throws_ok { 
    my $service = Net::Google::Spreadsheets->new(
        username => 'foo',
        password => 'bar',
    );
} qr{Net::Google::AuthSub login failed};

{
    my $res = Test::MockObject->new;
    $res->mock(is_success => sub {return 1});
    $res->mock(auth => sub {return 'foobar'});
    my $auth = Test::MockModule->new('Net::Google::AuthSub');
    $auth->mock('login' => sub {return $res});

    ok my $service = Net::Google::Spreadsheets->new(
        username => 'foo',
        password => 'bar',
    );
    is $service->ua->auth, 'foobar';
    my $ua = Test::MockModule->new('LWP::UserAgent');
    {
        $ua->mock('request' => sub {return HTTP::Response->parse(<<'END')});
302 Found
Location: http://www.google.com/

END
        throws_ok {
            $service->spreadsheets;
        } qr{302 Found};
    }
    {
        $ua->mock('request' => sub {return HTTP::Response->parse(<<END)});
200 OK
Content-Type: application/atom+xml
Content-Length: 1

1
END
        throws_ok {
            $service->spreadsheets;
        } qr{broken};
    }
    {
        $ua->mock('request' => sub {return HTTP::Response->parse(<<END)});
200 OK
Content-Type: text/html
Content-Length: 13

<html></html>
END
        throws_ok {
            $service->spreadsheets;
        } qr{is not 'application/atom\+xml'};
    }
    {
        $ua->mock('request' => sub {return HTTP::Response->parse(<<'END')});
200 OK
ETag: W/"hogehoge"
Content-Type: application/atom+xml; charset=UTF-8; type=feed
Content-Length: 958

<?xml version='1.0' encoding='UTF-8'?><feed xmlns='http://www.w3.org/2005/Atom' xmlns:openSearch='http://a9.com/-/spec/opensearch/1.1/' xmlns:gd='http://schemas.google.com/g/2005' gd:etag='W/&quot;hogehoge&quot;'><id>http://spreadsheets.google.com/feeds/spreadsheets/private/full</id><updated>2009-08-15T09:41:23.289Z</updated><category scheme='http://schemas.google.com/spreadsheets/2006' term='http://schemas.google.com/spreadsheets/2006#spreadsheet'/><title>Available Spreadsheets - foobar@gmail.com</title><link rel='alternate' type='text/html' href='http://docs.google.com'/><link rel='http://schemas.google.com/g/2005#feed' type='application/atom+xml' href='http://spreadsheets.google.com/feeds/spreadsheets/private/full'/><link rel='self' type='application/atom+xml' href='http://spreadsheets.google.com/feeds/spreadsheets/private/full?tfe='/><openSearch:totalResults>0</openSearch:totalResults><openSearch:startIndex>1</openSearch:startIndex></feed>
END
        my @ss = $service->spreadsheets;
        is scalar @ss, 0;
    }
}

done_testing;
