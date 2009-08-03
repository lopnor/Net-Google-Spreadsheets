use lib 't/lib';
use Test::GoogleSpreadsheets::Util
    title => 'test for Net::Google::Spreadsheets';
use Test::FITesque;

my $args = {
    title => 'new worksheet',
    row_count => 10,
    col_count => 3,
};

my $args2 = {
    title => 'foobar',
};

run_tests {
    test {
        ['Test::GoogleSpreadsheets::Worksheet', 
            {spreadsheet_title => 'test for Net::Google::Spreadsheets'}
        ],
        ['get_worksheets'],
        ['add_worksheet', $args],
        ['edit_title', {from => $args->{title}, to => $args2->{title}}],
        ['edit_rowcount', {title => $args2->{title}}],
        ['delete_worksheet', {title => $args2->{title}}],
    }
}
