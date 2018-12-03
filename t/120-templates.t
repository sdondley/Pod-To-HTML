use Test;
use Test::Output;
use Pod::To::HTML;
plan 3;
my $r;

=begin pod
The seven suspects are:

=item  Happy
=item  Dopey
=item  Sleepy
=item  Bashful
=item  Sneezy
=item  Grumpy
=item  Keyser Soze
=end pod

stderr-like {$r = pod2html $=pod[0], :templates<templates>}, /'does not contain required templates'/, 'Complains when required templates not found';
ok $r ~~ ms[[
    '<p>' 'The seven suspects are:' '</p>'
    '<ul>'
        '<li>' '<p>' Happy '</p>' '</li>'
        '<li>' '<p>' Dopey '</p>' '</li>'
        '<li>' '<p>' Sleepy '</p>' '</li>'
        '<li>' '<p>' Bashful '</p>' '</li>'
        '<li>' '<p>' Sneezy '</p>' '</li>'
        '<li>' '<p>' Grumpy '</p>' '</li>'
        '<li>' '<p>' Keyser Soze '</p>' '</li>'
    '</ul>'
]], 'Uses default templates';

$r = pod2html $=pod[0], :templates("t/templates");
ok $r ~~ ms[[  '<meta description="This is a new template"/>' ]], 'Gets text from new template';
