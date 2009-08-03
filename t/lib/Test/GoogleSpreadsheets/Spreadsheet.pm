package Test::GoogleSpreadsheets::Spreadsheet;
use Moose;
use namespace::clean -except => 'meta';
use Test::More;
use Digest::MD5 qw(md5_hex);
BEGIN {extends 'Test::GoogleSpreadsheets::Fixture'};

sub get_spreadsheets :Test :Plan(5) {
    my ($self) = @_;
    my @sheets = $self->service->spreadsheets;
    ok scalar @sheets;
    isa_ok $sheets[0], 'Net::Google::Spreadsheets::Spreadsheet';
    ok $sheets[0]->title;
    ok $sheets[0]->key;
    ok $sheets[0]->etag;
}

sub get_a_spreadsheet :Test :Plan(11) {
    my ($self, $title) = @_;
    ok(my $ss = $self->service->spreadsheet({title => $title}));
    isa_ok $ss, 'Net::Google::Spreadsheets::Spreadsheet';
    is $ss->title, $title;
    like $ss->id, qr{^http://spreadsheets.google.com/feeds/spreadsheets/};
    isa_ok $ss->author, 'XML::Atom::Person';
    is $ss->author->email, $self->config->{username};
    my $key = $ss->key;
    ok length $key, 'key defined';
    my $ss2 = $self->service->spreadsheet({key => $key});
    ok $ss2;
    isa_ok $ss2, 'Net::Google::Spreadsheets::Spreadsheet';
    is $ss2->key, $key;
    is $ss2->title, $title;
    return $ss;
}

sub get_nonexisting_spreadsheet :Test :Plan(2) {
    my ($self) = @_;
    my @existing = map {$_->title} $self->service->spreadsheets;
    my $title;
    while (1) {
        $title = md5_hex(time, $$, rand, @existing);
        grep {$_ eq $title} @existing or last; 
    }
    
    my $ss = $self->service->spreadsheet({title => $title});
    is $ss, undef, "spreadsheet named '$title' shouldn't exit";
    my @ss = $self->service->spreadsheets({title => $title});
    is scalar @ss, 0;
}

__PACKAGE__->meta->make_immutable;

1;
