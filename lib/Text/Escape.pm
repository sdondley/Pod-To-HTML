use v6;
module Text::Escape;

sub escape($str as Str, Str $how) is export {
    given $how.lc {
        when 'none'         { $str }
        when 'html'         { escape_html($str) }
        when 'uri' | 'url'  { escape_uri($str)  }
        default { fail "Don't know how to escape format $how yet" }
    }
}

sub escape_html(Str $str) returns Str is export {
    $str.subst(q{&}, q{&amp;}, :g)\
        .subst(q{<}, q{&lt;}, :g)\
        .subst(q{>}, q{&gt;}, :g)\
        .subst(q{"}, q{&quot;}, :g)\
        .subst(q{'}, q{&#39;}, :g);
}

sub escape_uri(Str $str) returns Str is export {
    my Str $allowed = 'abcdefghijklmnopqrstuvwxyz'
                    ~ 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
                    ~ '0123456789'
                    ~ q{-_.!~*'()};

    return [~] $str.comb.map(-> $char {
        given $char {
            when q{ }                           { q{+} }
            when defined $allowed.index($char)  { $char }
            # TODO: each char should be UTF-8 encoded, then its bytes %-encoded
            default                             { q{%} ~ ord($char).fmt('%x') }
        }
    });
}

# vim:ft=perl6
