use strict;
use warnings;
use Net::Google::DataAPI::Auth::OAuth2;
use Net::OAuth2::AccessToken;
use Term::Prompt;
use Data::Dumper;
use JSON qw(encode_json decode_json);

my $oauth2 = Net::Google::DataAPI::Auth::OAuth2->new(
    client_id       => '155919245515-hecvp8u7d5upvct9mbgrl61epr0c5vh8.apps.googleusercontent.com',
    client_secret   => '1iE14ndZRYReD7mbOyg8EzbR',
    scope           => ['http://spreadsheets.google.com/feeds/'],
);
my $url = $oauth2->authorize_url();

print "open this url [$url] in browser to get code\n";
my $code = prompt('x', 'paste the code: ', '', '');

my $token = $oauth2->get_access_token($code) or die;
my $session = encode_json($token->session_freeze);

print "Oauth2 access_token [" . $session . "]\n\n";
