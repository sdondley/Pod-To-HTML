use Test; # -*- mode: perl6 -*-
use Pod::To::HTML;
plan 2;

use MONKEY-SEE-NO-EVAL;

# XXX Need a module to walk HTML trees

my $example-path = "test.pod6".IO.e??"test.pod6"!!"t/test.pod6";

my $a-pod = $example-path.IO.slurp;
my $pod = (EVAL ($a-pod ~ "\n\$=pod")); # use proved pod2onebigpage method
my $r = node2html $pod;
ok( $r, "Converting external" );
unlike( $r, /Pod\:\:To/, "Is not prepending class name" );
