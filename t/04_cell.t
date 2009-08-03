use lib 't/lib';
use Test::GoogleSpreadsheets::Util 
    title => 'test for Net::Google::Spreadsheets';
use Test::FITesque;

run_tests {
    test {
        ['Test::GoogleSpreadsheets::Cell', 
            {spreadsheet_title => 'test for Net::Google::Spreadsheets'}],
        ['edit_cell', {col => 1, row => 1, input_value => 'hogehoge'}],
        ['batchupdate_cell', 
            {col => 1, row => 1, input_value => 'foobar'},
        ],
        ['check_value', {col => 1, row => 1}, 'foobar'],
    }
};
