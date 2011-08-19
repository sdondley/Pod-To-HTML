module Pod::To::HTML;
use Text::Escape;

my $title;
my @meta;
my @indexes;
my @body;

sub pod2html($pod) is export {
    @body.push: node2html($pod);

    my $title_html = $title // 'Pod document';

    # TODO: make this look nice again when q:to"" gets implemented
    my $prelude = qq[<!doctype html>
<html>
<head>
  <title>{$title_html}</title>
  <meta charset="UTF-8" />
  <link rel="stylesheet" href="http://perlcabal.org/syn/perl.css">
  {metadata()}
</head>
<body class="pod" id="___top">
];

    return $prelude
        ~ ($title.defined ?? "<h1>{$title_html}</h1>\n" !! '')
        ~ buildindexes()
        ~ @body.join
        ~ "</body>\n</html>";
}

sub metadata {
    @meta.map(-> $p {
        qq[<meta name="{escape_html($p.key)}" value="{escape_html($p.value)}" />\n]
    }).join;
}

sub buildindexes {
    my $r = qq[<nav class="indexgroup">\n];

    my $indent = q{ } x 2;
    my @opened;
    for @indexes -> $p {
        my $lvl  = $p.key;
        my %head = $p.value;
        if +@opened {
            while @opened[*-1] > $lvl {
                $r ~= $indent x @opened - 1
                    ~ "</ul>\n";
                @opened.pop;
            }
        }
        my $last = @opened[*-1] // 0;
        if $last < $lvl {
            $r ~= $indent x $last
                ~ qq[<ul class="indexList indexList{$lvl}">\n];
            @opened.push($lvl);
        }
        $r ~= $indent x $lvl
            ~ qq[<li class="indexItem indexItem{$lvl}">]
            ~ qq[<a href="#{%head<uri>}">{%head<html>}</a>\n];
    }
    for ^@opened {
        $r ~= $indent x @opened - 1 - $^left
            ~ "</ul>\n";
    }

    return $r ~ "</nav>\n";
}

sub prose2html($pod, $sep = '') {
    escape_html($pod.content.join($sep));
}

sub twine2text($twine) {
    return '' unless $twine.elems;
    my $r = $twine[0];
    for $twine[1..*] -> $f, $s {
        $r ~= twine2text($f.content);
        $r ~= $s;
    }
    return $r;
}


multi sub node2html($node) {
    note "{:$node.perl} is missing a node2html multi";
    $node.Str;
}

multi sub node2html(Pod::Block::Code $node) {
    '<pre>' ~ prose2html($node) ~ "</pre>\n"
}

multi sub node2html(Pod::Block::Comment $node) {
}

multi sub node2html(Pod::Block::Named $node) {
    given $node.name {
        when 'pod'  { node2html($node.content)     }
        when 'para' { node2html($node.content[0])      }
        when 'defn' { node2html($node.content[0]) ~ "\n"
                    ~ node2html($node.content[1..*-1]) }
        when 'config' { }
        when 'nested' { }
        default     {
            if $node.name eq 'TITLE' {
                $title = prose2html($node.content[0]);
            }
            elsif $node.name ~~ any(<VERSION DESCRIPTION AUTHOR COPYRIGHT SUMMARY>)
              and $node.content[0] ~~ Pod::Block::Para {
                @meta.push: Pair.new(
                    key => $node.name.lc,
                    value => twine2text($node.content[0].content)
                );
            }

            '<section>'
                ~ "<h1>{$node.name}</h1>\n"
                ~ node2html($node.content)
                ~ "</section>\n"
        }
    }
}

multi sub node2html(Pod::Block::Para $node) {
    '<p>' ~ escape_html(twine2text($node.content)) ~ "</p>\n"
}

multi sub node2html(Pod::Block::Table $pod) {
    my @r = '<table>';

    if $pod.caption {
        @r.push("<caption>{escape_html($pod.caption)}</caption>");
    }

    if $pod.headers {
        @r.push(
            '<thead><tr>',
            $pod.headers.map(-> $cell {
                "<th>{node2html($cell)}</th>"
            }),
            '</tr></thead>'
        );
    }

    @r.push(
        '<tbody>',
        $pod.content.map(-> $line {
            '<tr>',
            $line.list.map(-> $cell {
                "<td>{node2html($cell)}</td>"
            }),
            '</tr>'
        }),
        '</tbody>',
        '</table>'
    );

    return @r.join("\n");
}

multi sub node2html(Pod::Heading $node) {
    my $lvl = min($node.level, 6);
    my $plaintext = twine2text($node.content[0].content);
    my %escaped = (
        uri => escape_uri($plaintext),
        html => escape_html($plaintext),
    );
    @indexes.push: Pair.new(key => $lvl, value => %escaped);

    return
        sprintf('<h%d id="%s">', $lvl, %escaped<uri>)
            ~ qq[<a class="u" href="#___top" title="go to top of document">]
                ~ %escaped<html>
            ~ qq[</a>]
        ~ qq[</h{$lvl}>\n];
}

# FIXME
multi sub node2html(Pod::Item $node) {
    '<ul><li>' ~ node2html($node.content) ~ "</li></ul>\n"
}

multi sub node2html(Positional $node) {
    $node.map({ node2html($_) }).join
}

multi sub node2html(Str $node) {
    escape_html($node);
}
