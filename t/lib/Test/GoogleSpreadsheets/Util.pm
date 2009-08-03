package Test::GoogleSpreadsheets::Util;
use strict;
use warnings;
use utf8;
use Test::More;
use Net::Google::Spreadsheets;

BEGIN {
    my $builder = Test::More->builder;
    binmode($builder->output, ':utf8');
    binmode($builder->failure_output, ':utf8');
    binmode($builder->todo_output, ':utf8');
}

sub import {
    my ($class, %args) = @_;

    strict->import;
    warnings->import;
    utf8->import;

    check_env(qw(TEST_NET_GOOGLE_SPREADSHEETS)) or exit;
    {
        no warnings;
        check_use(qw(Config::Pit)) or exit;
    }
    my $config = check_config('google.com') or exit;
    if (my $title = $args{spreadsheet_title}) {
        check_spreadsheet_exists(
            {title => $title, config => $config}
        ) or exit;
    }
}

sub check_env {
    my (@env) = @_;
    for (@env) {
        unless ($ENV{$_}) {
            plan skip_all => "set $_ to run this test";
            return;
        }
    }
    return 1;
}

sub check_use {
    my (@module) = @_;
    for (@module) {
        eval "use $_";
        if ($@) {
            plan skip_all => "this test needs $_";
            return;
        }
    }
    1;
}

sub check_config {
    my ($key) = @_;
    my $config = Config::Pit::get($key);
    unless ($config->{username} && $config->{password}) {
        plan skip_all 
            => "set username and password for google.com via 'ppit set $key'";
        return;
    }
    return $config;
}

sub check_spreadsheet_exists {
    my ($args) = @_;
    $args->{title} or return 1;
    my $service = Net::Google::Spreadsheets->new(
        {
            username => $args->{config}->{username},
            password => $args->{config}->{password},
        }
    ) or die;
    my $sheet = $service->spreadsheet({title => $args->{title}});
    unless ($sheet) {
        plan skip_all => "spreadsheet named '$args->{title}' doesn't exist";
        return;
    }
    return $sheet;
}

1;
