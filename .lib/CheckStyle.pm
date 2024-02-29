package CheckStyle;

use 5.26.0;
use warnings FATAL => 'all';
use feature qw(signatures);
no warnings "experimental::signatures";

use XML::Parser;

sub list_errors($class) {
    my $par = XML::Parser->new(Style => 'Objects', Pkg => 'CX');
    my $tree = $par->parsefile("target/checkstyle-result.xml");
    my $self = bless({Kids => $tree}, $class);
    return $self->errors();
}

sub errors($self) {
    my @ys = ();
    for my $kid (@{$self->{Kids}}) {
        push @ys, $kid->errors();
    }
    return @ys;
}

package CX::checkstyle;
our @ISA = qw(CheckStyle);

package CX::file;
our @ISA = qw(CheckStyle);

use Data::Dumper;

sub errors($self) {
    my @ys = ();
    for my $kid (@{$self->{Kids}}) {
        push @ys, $kid->errors();
    }
    for my $yy (@ys) {
        $yy->{file} = $self->{name};
    }
    return @ys;
}

package CX::error;
our @ISA = qw(CheckStyle);

use Data::Dumper;

sub errors($self) {
    #say Dumper(\$self);
    return {
        line => $self->{line},
        text => $self->{message},
    };
}

package CX::Characters;
our @ISA = qw(CheckStyle);

1;
