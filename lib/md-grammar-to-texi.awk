#!/usr/bin/awk -f
#
# md-grammar-to-texi.awk -- Convert GRAMMAR.md to a texinfo @example block.
#
# Usage:
#   awk -f md-grammar-to-texi.awk GRAMMAR.md > lib/grammar.texi
#   awk -v out=lib/grammar.texi -f md-grammar-to-texi.awk GRAMMAR.md
#
# When -v out=FILE is set the script writes to FILE; otherwise stdout.
# The latter form avoids relying on shell redirection (needed by CMake's
# add_custom_command, which does not invoke a shell).
#
# Conventions assumed about the input:
#   - The opening paragraph is plain prose (skipped; the texi already has it).
#   - Section dividers are lines at column 0 starting with "// ".
#   - Grammar rules are indented with exactly 4 spaces (markdown code block).
#   - Non-terminals are written as _Name_ (underscores), starting with an
#     uppercase letter, containing letters and hyphens only.
#

function emit(s) {
    if (out != "") print s > out
    else           print s
}

BEGIN {
    emit("@c -*- texinfo -*-")
    emit("@c Generated from GRAMMAR.md -- DO NOT EDIT.")
    emit("@example")
    in_intro = 1
}

# Skip the leading intro paragraph until first blank line or section divider.
in_intro {
    if (/^$/ || /^\/\//) { in_intro = 0 }
    else                 { next }
}

# Section dividers at column 0 -> texinfo comments.
/^\/\/ / {
    sub(/^\/\/ /, "@c ")
    emit($0)
    next
}

# Blank lines pass through.
/^$/ { emit(""); next }

# Grammar-rule lines.
{
    line = $0
    sub(/^    /, "", line)               # strip markdown 4-space indent

    # Escape texinfo specials that come from the SOURCE.  Do this BEFORE we
    # introduce @emph{...}, otherwise the braces we generate would be escaped.
    gsub(/@/, "@@", line)
    gsub(/\{/, "@{", line)
    gsub(/\}/, "@}", line)

    # _Name_  ->  @emph{Name}
    result = ""
    rest = line
    while (match(rest, /_[A-Z][A-Za-z-]*_/)) {
        name   = substr(rest, RSTART+1, RLENGTH-2)
        result = result substr(rest, 1, RSTART-1) "@emph{" name "}"
        rest   = substr(rest, RSTART+RLENGTH)
    }
    result = result rest

    # NOTE: the output contains UTF-8 bytes (diacritics, arrows, +/- sign)
    # from the markdown comments.  Ensure udunits2lib.texi declares
    # `@documentencoding UTF-8' near the top.

    emit(result)
}

END {
    emit("@end example")
}

