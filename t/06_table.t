use t::Util;
use Test::More;

my $ws_title = 'test worksheet for table '.scalar localtime;
my $table_title = 'test table '.scalar localtime;
my $ss = spreadsheet;
ok my $ws = $ss->add_worksheet({title => $ws_title}), 'add worksheet';
is $ws->title, $ws_title;

my @t = $ss->tables;
my $previous_table_count = scalar @t;

{
    ok my $table = $ss->add_table(
        {
            title => $table_title,
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
    is scalar @t, $previous_table_count + 1;
    isa_ok $t[0], 'Net::Google::Spreadsheets::Table';
}

{
    ok my $t = $ss->table({title => $table_title});
    isa_ok $t, 'Net::Google::Spreadsheets::Table';
    is $t->title, $table_title;
    is $t->summary, 'this is summary of this table';
    is $t->worksheet, $ws->title;
    is $t->header, 1;
    is $t->start_row, 2;
    is scalar @{$t->columns}, 3;
    ok grep {$_->name eq 'name' && $_->index eq 'A'} @{$t->columns};
    ok grep {$_->name eq 'mail address' && $_->index eq 'B'} @{$t->columns};
    ok grep {$_->name eq 'nick' && $_->index eq 'C'} @{$t->columns};
}

{
    ok my $t = $ss->table;
    isa_ok $t, 'Net::Google::Spreadsheets::Table';

    ok $t->delete;
    my @t = $ss->tables;
    is scalar @t, $previous_table_count;
}

ok $ws->delete, 'delete worksheet';

done_testing;
