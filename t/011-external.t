use Test; # -*- mode: perl6 -*-
use Pod::To::HTML;
plan 6;

use MONKEY-SEE-NO-EVAL;

# XXX Need a module to walk HTML trees

for <test class> -> $base {
    test-files( $base ~ ".pod6" );
}

sub test-files( $possible-file-path ) {
    
    my $example-path = $possible-file-path.IO.e??$possible-file-path!!"t/$possible-file-path";

    my $a-pod = $example-path.IO.slurp;
    my $rendered= Pod::To::HTML.render($example-path.IO);
    say $rendered;
    my $pod = (EVAL ($a-pod ~ "\n\$=pod")); # use proved pod2onebigpage method
    say $pod.perl;
    my $r = node2html $pod;
    ok( $r, "Converting external" );
    unlike( $r, /Pod\:\:To/, "Is not prepending class name" );
    $r = pod2html($pod, :header(''), :footer(''), :head(''), :default-title(''), :lang('en'));
    unlike( $r, /Pod\:\:To/, "Is not prepending class name" );
}
