module Pod::To::HTML;
use Text::Escape;

my $title;
my @meta;
my @indexes;
my @body;

#= Converts a Pod tree to a HTML document.
sub pod2html($pod) is export returns Str {
    @body.push: node2html($pod);

    my $title_html = $title // 'Pod document';

    # TODO: make this look nice again when q:to"" gets implemented
    my @prelude = (
        '<!doctype html>',
        '<html>',
        '<head>',
        '  <title>' ~ $title_html ~ '</title>',
        '  <meta charset="UTF-8" />',
        #'  <link rel="stylesheet" href="http://perlcabal.org/syn/perl.css">',
           ( do-metadata() // () ),
        '</head>',
        '<body class="pod" id="___top">',
    );

    return join(qq{\n},
        @prelude,
        ( $title.defined ?? "<h1>{$title_html}</h1>"
                         !! () ),
        ( do-toc() // () ),
        @body,
        '</body>',
        "</html>\n"
    );
}

#= Returns accumulated metadata as a string of C«<meta>» tags
sub do-metadata returns Str {
    return @meta.map(-> $p {
        qq[<meta name="{escape_html($p.key)}" value="{escape_html($p.value)}" />]
    }).join("\n");
}

#= Turns accumulated headings into a nested-C«<ol>» table of contents
sub do-toc returns Str {
    my $r = qq[<nav class="indexgroup">\n];

    my $indent = q{ } x 2;
    my @opened;
    for @indexes -> $p {
        my $lvl  = $p.key;
        my %head = $p.value;
        if +@opened {
            while @opened[*-1] > $lvl {
                $r ~= $indent x @opened - 1
                    ~ "</ol>\n";
                @opened.pop;
            }
        }
        my $last = @opened[*-1] // 0;
        if $last < $lvl {
            $r ~= $indent x $last
                ~ qq[<ol class="indexList indexList{$lvl}">\n];
            @opened.push($lvl);
        }
        $r ~= $indent x $lvl
            ~ qq[<li class="indexItem indexItem{$lvl}">]
            ~ qq[<a href="#{%head<uri>}">{%head<html>}</a>\n];
    }
    for ^@opened {
        $r ~= $indent x @opened - 1 - $^left
            ~ "</ol>\n";
    }

    return $r ~ '</nav>';
}

sub prose2html($pod, $sep = '') returns Str {
    return escape_html($pod.content.join($sep));
}

sub twine2text($twine) returns Str {
    return '' unless $twine.elems;
    my $r = $twine[0];
    for $twine[1..*] -> $f, $s {
        $r ~= twine2text($f.content);
        $r ~= $s;
    }
    return $r;
}

#= block level or below
multi sub node2html($node) returns Str {
    say "Generic node2html called for {$node.perl}";
    return node2inline($node);
}

multi sub node2html(Array $node) returns Str {
    return $node.map({ node2html($_) }).join
}

multi sub node2html(Pod::Block::Declarator $node) returns Str {
    given $node.WHEREFORE {
        when Sub {
            "<article>\n"
                ~ '<code>'
                    ~ node2text($node.WHEREFORE.name ~ $node.WHEREFORE.signature.perl)
                ~ "</code>:\n"
                ~ node2html($node.content)
            ~ "\n</article>\n";
        }
        default {
            say "I don't know what {$node.WHEREFORE.perl} is";
            node2html([$node.WHEREFORE.perl, q{: }, $node.content]);
        }
    }
}

multi sub node2html(Pod::Block::Code $node) returns Str {
    say "Code node2html called for {$node.perl}";
    return '<pre>' ~ prose2html($node) ~ "</pre>\n"
}

multi sub node2html(Pod::Block::Comment $node) returns Str {
    say "Comment node2html called for {$node.perl}";
    return '';
}

multi sub node2html(Pod::Block::Named $node) returns Str {
    say "Named Block node2html called for {$node.perl}";
    given $node.name {
        when 'config' { return '' }
        when 'nested' { return '' }
        when 'pod'  { return node2html($node.content); }
        when 'para' { return node2html($node.content[0]); }
        when 'defn' {
            return node2html($node.content[0]) ~ "\n"
                    ~ node2html($node.content[1..*-1]);
        }
        default {
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

            return '<section>'
                ~ "<h1>{$node.name}</h1>\n"
                ~ node2html($node.content)
                ~ "</section>\n";
        }
    }
}

multi sub node2html(Pod::Block::Para $node) returns Str {
    say "Para node2html called for {$node.perl}";
    return '<p>' ~ node2inline($node.content) ~ "</p>\n";
}

multi sub node2html(Pod::Block::Table $node) returns Str {
    say "Table node2html called for {$node.perl}";
    my @r = '<table>';

    if $node.caption {
        @r.push("<caption>{escape_html($node.caption)}</caption>");
    }

    if $node.headers {
        @r.push(
            '<thead><tr>',
            $node.headers.map(-> $cell {
                "<th>{node2html($cell)}</th>"
            }),
            '</tr></thead>'
        );
    }

    @r.push(
        '<tbody>',
        $node.content.map(-> $line {
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

multi sub node2html(Pod::Config $node) returns Str {
    say "Config node2html called for {$node.perl}";
    return '';
}

multi sub node2html(Pod::Heading $node) returns Str {
    say "Heading node2html called for {$node.perl}";
    my $lvl = min($node.level, 6); #= HTML only has 6 levels of numbered headings
    my $plaintext = twine2text($node.content[0].content);
    my %escaped = (
        uri => escape_uri($plaintext),
        html => escape_html($plaintext),
    );
    @indexes.push: Pair.new(key => $lvl, value => %escaped);

    return sprintf('<h%d id="%s">', $lvl, %escaped<uri>)
                ~ qq[<a class="u" href="#___top" title="go to top of document">]
                    ~ %escaped<html>
                ~ qq[</a>]
            ~ qq[</h{$lvl}>\n];
}

# FIXME
multi sub node2html(Pod::Item $node) returns Str {
    say "List Item node2html called for {$node.perl}";
    return '<ul><li>' ~ node2html($node.content) ~ "</li></ul>";
}

multi sub node2html(Str $node) returns Str {
    return escape_html($node);
}

#= inline level or below
multi sub node2inline($node) returns Str {
    say "{$node.perl} is missing a node2inline multi";
    return node2text($node);
}

multi sub node2inline(Array $node) returns Str {
    return $node.map({ node2inline($_) }).join;
}

multi sub node2inline(Pod::FormattingCode $node) returns Str {
    given $node.type {
        when 'B' { return '<b>' ~ node2inline($node.content) ~ '</b>' }
        when 'C' { return '<code>' ~ node2inline($node.content) ~ '</code>' }
        default {
            return $node.type ~ q{=} ~ node2inline($node.content);
        }
    }
}

multi sub node2inline(Str $node) returns Str {
    return escape_html($node);
}

#= text only
multi sub node2text($node) returns Str {
    say "{$node.perl} is missing a node2text multi";
    return twine2text($node);
}

multi sub node2text(Str $node) returns Str {
    return escape_html($node);
}

DOC INIT {
    say pod2html($=POD);
    exit;
}
