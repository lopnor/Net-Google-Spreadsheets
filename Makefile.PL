use inc::Module::Install;
name 'Net-Google-Spreadsheets';
all_from 'lib/Net/Google/Spreadsheets.pm';

requires 'Carp';
requires 'XML::Atom';
requires 'Net::Google::AuthSub';
requires 'Crypt::SSLeay';
requires 'LWP::UserAgent';
requires 'URI';
requires 'Moose';
requires 'Path::Class';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
build_requires 'Test::Exception';
use_test_base;
auto_include;
WriteAll;
