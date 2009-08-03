package Test::GoogleSpreadsheets::Cell;
use Moose;
use namespace::clean -except => 'meta';
BEGIN {extends 'Test::GoogleSpreadsheets::Worksheet'};
use Test::More;

has worksheet => (
    is => 'ro',
    isa => 'Net::Google::Spreadsheets::Worksheet',
    required => 1,
    lazy_build => 1,
);

__PACKAGE__->meta->make_immutable;

sub _build_worksheet {
    my ($self) = @_;
    return $self->spreadsheet->add_worksheet;
}

sub edit_cell :Test :Plan(3) {
    my ($self, $args) = @_;
    my $cell = $self->worksheet->cell({col => $args->{col}, row => $args->{row}});
    isa_ok $cell, 'Net::Google::Spreadsheets::Cell';
    my $prev = $cell->content;
    ok $cell->input_value($args->{input_value});
    is $cell->content, $args->{input_value};
}

sub batchupdate_cell {
    my ($self, $args) = @_;
    my @cells = $self->worksheet->batchupdate_cell($args);
}

sub check_value :Test {
    my ($self, $args, $content) = @_;
    is $self->worksheet->cell($args)->content, $content;
}

1;
