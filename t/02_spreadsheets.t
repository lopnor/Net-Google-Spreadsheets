use lib 't/lib';
use Test::GoogleSpreadsheets::Util 
    title => 'test for Net::Google::Spreadsheets';
use Test::FITesque;

run_tests {
    test {
        ['Test::GoogleSpreadsheets::Spreadsheet'],
        ['get_spreadsheets'],
        ['get_a_spreadsheet', 'test for Net::Google::Spreadsheets'],
        ['get_nonexisting_spreadsheet'],
    }
};
