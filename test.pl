#!/usr/bin/perl
use 5.26.0;
use warnings FATAL => 'all';
use feature qw(signatures);
no warnings "experimental::signatures";
use lib './.lib';

use Test::Simple tests => 5;
use Data::Dumper;

our %EXPECT_TESTS = (
    ExprShould => 2,
);

if (-e "./target") {
    say "#\n#";
    say "#      You must run 'mvn clean' before submitting.";
    say "#\n#";
    exit(1);
}

run_mvn_quiet("verify");
run_mvn_quiet("checkstyle:checkstyle");

use JUnit;

my @reports = JUnit::list_reports();

my %seen = map { $_ => 1 } @reports;
for my $xx (sort keys %EXPECT_TESTS) {
    my $name = "hw06.$xx";
    unless (exists($seen{$name})) {
        say "# Test report missing: $name";
        say "# Giving up";
        exit(0);
    }

    ok(1, "Test output exists for $name");

    my $report = JUnit::read_report($name);

    my $jvers = $report->java_version();
    say "# Java VM: $jvers";

    my $summary = $report->summary();
    my $expect = $EXPECT_TESTS{$xx};
    my $ran = $summary->{tests};
    my $passed = $ran - ($summary->{fails} + $summary->{errors});
    for (my $ii = 0; $ii < $expect; ++$ii) {
        ok($passed > $ii, "In $name, passed > $ii tests.");
        ok($passed > $ii, "In $name, passed > $ii tests.");
    }
}

use CheckStyle;

my @errors = CheckStyle->list_errors();
my $count = scalar @errors;

#ok($count < 10, "Less than 10 style errors");
#ok($count == 0, "No style errors");

if (0 && $count > 0) {
    say "#";
    say "# You had some style errors, here they are:";
    for my $err (@errors) {
        my $file = $err->{file};
        $file =~ s/^.*\///;
        my $line = $err->{line};
        my $text = $err->{text};
        say "#   $file:$line => $text";
    }
}

run_mvn_quiet("clean");

sub run_mvn_quiet($action) {
    say "# mvn $action ...";
    #my $env = "MAVEN_OPTS='-Xms384M -Xmx512M'";
    my $cmd = qq{mvn $action -q -B 2>&1 || true};
    my $output = `$cmd`;
    $output =~ s/^/# /mg;
    say $output;
}
