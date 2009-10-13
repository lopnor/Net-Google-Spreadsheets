use inc::Module::Install;
name 'Net-Google-Spreadsheets';
all_from 'lib/Net/Google/Spreadsheets.pm';

requires 'Carp';
requires 'XML::Atom';
requires 'Moose' => '0.34';
requires 'Net::Google::DataAPI' => '0.04';
requires 'URI';
requires 'Path::Class';

tests_recursive;
author_tests 'xt';

build_requires 'Test::More' => '0.88';
build_requires 'Test::Exception';
build_requires 'Test::MockModule';
build_requires 'Test::MockObject';
use_test_base;
auto_include;
auto_set_repository;
WriteAll;
