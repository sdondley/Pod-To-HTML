use v6;
use Pod::To::HTML;

put render(
    './markdown-guide.pod'.IO,
    template => '.',
    site-title => 'A page',
    css => $*CWD.add('css').dir.map(*.Str),
    menus => (
        %(name => "About"),
        %(name => "Posts"),
    ),
);

