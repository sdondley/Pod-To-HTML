use Test; # -*- mode: perl6 -*-
use Pod::To::HTML;
plan 9;

my $example-path = "multi.pod6".IO.e??"multi.pod6"!!"t/multi.pod6";

my $a-pod = $example-path.IO.slurp;
my $rendered= Pod::To::HTML.render($example-path.IO);
say $rendered.perl;
like( $rendered, /magicians/, "Is including the whole file" );

