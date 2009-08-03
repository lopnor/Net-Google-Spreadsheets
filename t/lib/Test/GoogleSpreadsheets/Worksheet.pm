package Test::GoogleSpreadsheets::Worksheet;
use Moose;
use namespace::clean -except => 'meta';
BEGIN {extends 'Test::GoogleSpreadsheets::Fixture'};
use Test::More;

has spreadsheet_title => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has spreadsheet => (
    is => 'ro',
    isa => 'Net::Google::Spreadsheets::Spreadsheet',
    required => 1,
    lazy_build => 1,
);

sub _build_spreadsheet {
    my ($self) = @_;
    return $self->service->spreadsheet( {title => $self->spreadsheet_title} );
}

sub get_worksheets :Test :Plan(2) {
    my ($self) = @_;
    my @ws = $self->spreadsheet->worksheets;
    ok scalar @ws;
    isa_ok($ws[0], 'Net::Google::Spreadsheets::Worksheet');
}

sub add_worksheet :Test :Plan(10) {
    my ($self, $args) = @_;
    my $before = scalar $self->spreadsheet->worksheets;

    my $ws = $self->spreadsheet->add_worksheet($args);
    isa_ok $ws, 'Net::Google::Spreadsheets::Worksheet';
    is $ws->title, $args->{title};
    is $ws->row_count, $args->{row_count};
    is $ws->col_count, $args->{col_count};

    my @ws = $self->spreadsheet->worksheets;
    is scalar @ws, $before + 1;
    ok grep {$_->title eq $args->{title} } @ws;

    my $ws2 = $self->spreadsheet->worksheet({title => $args->{title}});
    isa_ok $ws2, 'Net::Google::Spreadsheets::Worksheet';
    is $ws2->title, $args->{title};
    is $ws2->row_count, $args->{row_count};
    is $ws2->col_count, $args->{col_count};
}

sub delete_worksheet :Test :Plan(4) {
    my ($self, $args) = @_;

    my $before = scalar $self->spreadsheet->worksheets;
    my $ws = $self->spreadsheet->worksheet($args);
    ok $ws->delete;
    my @ws = $self->spreadsheet->worksheets;
    is scalar @ws, $before - 1;
    ok ! grep {$_->id eq $ws->id} @ws;
    ok ! grep {$_->id eq $ws->title} @ws;
}

sub edit_title :Test :Plan(2) {
    my ($self, $args) = @_;
    my $ws = $self->spreadsheet->worksheet({title => $args->{from}});
    $ws->title($args->{to});
    is $ws->title, $args->{to};
    is $ws->atom->title, $args->{to};
}

sub edit_rowcount :Test :Plan(12) {
    my ($self, $args) = @_;
    my $ws = $self->spreadsheet->worksheet({title => $args->{title}});
    for (1 .. 2) {
        my $col_count = $ws->col_count + 1;
        my $row_count = $ws->row_count + 1;
        is $ws->col_count($col_count), $col_count;
        is $ws->atom->get($ws->gsns, 'colCount'), $col_count;
        is $ws->col_count, $col_count;
        is $ws->row_count($row_count), $row_count;
        is $ws->atom->get($ws->gsns, 'rowCount'), $row_count;
        is $ws->row_count, $row_count;
    }
}

__PACKAGE__->meta->make_immutable;

1;
