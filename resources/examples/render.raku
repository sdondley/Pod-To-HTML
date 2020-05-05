#!/usr/bin/env raku

use v6;
use MONKEY-SEE-NO-EVAL;
use Pod::To::HTML;

my %*SUB-MAIN-OPTS = :named-anywhere;

sub MAIN(
    $file = "../../doc/Pod/To/HTML.rakudoc", #= Pod file to convert to HTML.
    Str :t(:$template),                      #= Path to Mustache template to render Pod file.
) {
    my $file-content = $file.IO.slurp;
    die "No pod here" if not $file-content ~~ /\=begin \s+ pod/;

    my $pod;
    try $pod = EVAL($file-content ~ "\n\$=pod");
    die "Pod fails: $!" if $!;

    put render(
        $pod,
        :$template,
    );
}

