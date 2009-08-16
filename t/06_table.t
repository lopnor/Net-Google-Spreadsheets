use t::Util;
use Test::More;

my $ws_title = 'test worksheet for table '.scalar localtime;
my $ss = spreadsheet;
ok my $ws = $ss->add_worksheet({title => $ws_title}), 'add worksheet';
is $ws->title, $ws_title;

{
    my @t = $ss->tables;
    is scalar @t, 0;
    is $ss->table, undef;
}

{
    ok my $table = $ss->add_table(
        {
            title => 'test table '.scalar localtime,
            summary => 'this is summary of this table',
            worksheet => $ws,
            header => 1,
            start_row => 2,
            columns => [
            {index => 1, name => 'name'},
            {index => 2, name => 'mail address'},
            {index => 3, name => 'nick'},
            ],
        }
    );
    isa_ok $table, 'Net::Google::Spreadsheets::Table';
}

{
    my @t = $ss->tables;
    ok scalar @t;
    isa_ok $t[0], 'Net::Google::Spreadsheets::Table';
}

{
    ok my $t = $ss->table;
    isa_ok $t, 'Net::Google::Spreadsheets::Table';

    ok $t->delete;
    is $ss->table, undef;
}

ok $ws->delete, 'delete worksheet';

done_testing;
