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
    {
        my $ua = Test::MockModule->new('LWP::UserAgent');
        $ua->mock('request' => sub {return HTTP::Response->new(302)});

        throws_ok {
            $service->spreadsheets;
        } qr{302 Found};
    }
    {
        my $ua = Test::MockModule->new('LWP::UserAgent');
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
        my $ua = Test::MockModule->new('LWP::UserAgent');
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
}

done_testing;
