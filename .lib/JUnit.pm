package JUnit;
use 5.26.0;
use warnings FATAL => 'all';
use feature qw(signatures);
no warnings "experimental::signatures";

use XML::Parser;

sub list_reports() {
    my @files = glob("target/surefire-reports/TEST-*.xml");
    return map { path_to_name($_) } @files;
}

sub require_report_count($count) {
    my @xs = list_reports();
    my $nn = scalar @xs;
    if ($nn == 0) {
        say "# No test reports";
        say "# run 'mvn verify'";
        say "# If that doesn't help, you've probably";
        say "# got a build error.";
        exit(0);
    }
    if ($nn != $count) {
        say "# Wrong number of test reports";
        say "# Expected $count";
        say "# Saw $count";
        exit(0);
    }
}

sub path_to_name($text) {
    $text =~ s|^target/surefire-reports/TEST-||;
    $text =~ s/\.xml$//;
    return $text;
}

sub name_to_path($text) {
    return "target/surefire-reports/TEST-$text.xml";
}

sub read_report($name) {
    my $path = name_to_path($name);
    my $par = XML::Parser->new(Style => 'Objects', Pkg => 'JX');
    my $tree = $par->parsefile($path);
    return JUnit::Report->new($tree);
}

sub merge_summaries($_c, $aa, $bb) {
    return {
        tests => ($aa->{tests}||0) + ($bb->{tests}||0),
        fails => ($aa->{fails}||0) + ($bb->{fails}||0),
        errors => ($aa->{errors}||0) + ($bb->{errors}||0),
    };
}

package JUnit::Report;

sub new($class, $tree) {
    return bless({tree => $tree}, $class);
}

sub java_version($self) {
    for my $kid (@{$self->{tree}}) {
        my $jv = $kid->java_version();
        if ($jv) {
            return $jv;
        }
    }
    return undef;
}

sub summary($self) {
    my $yy = {};
    for my $kid (@{$self->{tree}}) {
        my $xx = $kid->summary();
        $yy = JUnit->merge_summaries($yy, $xx);
    }
    return $yy;
}

package JX::Base;

sub java_version($self) {
    for my $kid (@{$self->{Kids}}) {
        my $rv = $kid->java_version();
        if ($rv) {
            return $rv;
        }
    }
    return undef;
}

sub summary($self) {
    my $yy = {};
    for my $kid (@{$self->{Kids}}) {
        my $xx = $kid->summary();
        $yy = JUnit->merge_summaries($yy, $xx);
    }
    return $yy;
}

package JX::testsuite;
our @ISA = qw(JX::Base);

sub summary($self) {
    my $tests = $self->{tests};
    my $fails = $self->{failures};
    my $errors = $self->{errors};

    return {tests => $tests, fails => $fails, errors => $errors};
}

package JX::properties;
our @ISA = qw(JX::Base);

package JX::property;
our @ISA = qw(JX::Base);

sub java_version($self) {
    my $name = $self->{name};
    my $value = $self->{value};

    if ($name eq 'java.runtime.version') {
        return $value;
    }
    else {
        return undef;
    }
}

package JX::testcase;
our @ISA = qw(JX::Base);

use Test::Simple;

sub visit($self) {
    my $name = $self->{name};
    my $fails = $self->count_fails();
    ok($fails == 0, $name);
    if ($fails > 0) {
        say $self->get_comment();
    }
}

sub count_fails($self) {
    my $fails = 0;
    for my $kid (@{$self->{Kids}}) {
        $fails += $kid->count_fails();
    }
    return $fails;
}

sub get_comment($self) {
    my $text = "";
    for my $kid (@{$self->{Kids}}) {
        $text .= $kid->get_comment();
    }
    return $text;
}

package JX::failure;
our @ISA = qw(JX::Base);

use Data::Dumper;

sub count_fails($self) {
    return 1;
}

sub get_comment($self) {
    my $text = "";
    for my $kid (@{$self->{Kids}}) {
        $text .= $kid->get_comment();
    }
    return $text;
}

package JX::error;
our @ISA = qw(JX::Base);

use Data::Dumper;

sub count_fails($self) {
    return 1;
}

sub get_comment($self) {
    my $text = "";
    for my $kid (@{$self->{Kids}}) {
        $text .= $kid->get_comment();
    }
    return $text;
}

package JX::Characters;
our @ISA = qw(JX::Base);

sub visit($self) {
    # do nothing
}

sub count_fails($self) {
    # Text isn't a fail
    return 0;
}

sub get_comment($self) {
    my $text = $self->{Text};
    if ($text =~ /^\s*$/) {
        return "";
    }
    else {
        $text = "\n$text\n";
        $text =~ s/^/# /mg;
        $text =~ s/\n+$//;
        return $text;
    }
}

1;
