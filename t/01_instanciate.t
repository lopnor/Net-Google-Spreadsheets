use lib 't/lib';
use Test::GoogleSpreadsheets::Util;
use Test::FITesque;

run_tests {
    test {
        ['Test::GoogleSpreadsheets::Fixture'],
        ['check_instance'],
    }
};
