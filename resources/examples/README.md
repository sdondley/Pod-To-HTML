# Example usage

## General script

From this directory:

    RAKUDOLIB=../../lib raku render.raku

which uses the module's local documentation and the
default `main.mustache` template.

To use the local `main.mustache` template, run:

    RAKUDOLIB=../../lib raku render.raku --template=.

Run `raku render.raku -h` to output the script's help message.

## Specific script

In the directory `with-partials`, you can find a script using
`Pod::To::HTML` to generate HTML with a template that uses partials.
