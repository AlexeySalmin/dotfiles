#!/bin/bash

BACKUP="$PWD/.bak/$(date -Iseconds)"
DOTFILES="dotfiles"
RUN=

if [ "z$1" = "z--dry-run" ] ; then
    RUN=echo
    shift
fi

if [ ! -z "$1" ] ; then
    DOTFILES="$1"
fi

die() {
    echo "$*"
    exit 1
}

src_name() {
    echo "$1" | sed -e "s/\.\//$DOTFILES\//"
}

dst_name() {
    echo "$1" | sed -e 's/\.\//./' | sed -e 's/\.append$//'
}

link_file() {
    src=$1 ; shift
    dst=$1 ; shift
    if [ -h "$dst" ] ; then
        return
    fi
    if [ -f "$dst" ] ; then
        $RUN rm -f "$BACKUP/$dst"
        $RUN mv "$dst" "$BACKUP/"
    fi
    d=`dirname "$dst"`
    [ -d "$d" ] || $RUN mkdir "$d"
    $RUN ln -r -s "$src" "$dst"
}

cmp_tail() {
    shorter=$1 ; shift
    longer=$1 ; shift
    lines=`cat "$shorter" | wc -l`
    tail -n "$lines" "$longer" | cmp -s $shorter
}

append_file() {
    what=$1 ; shift
    to=$1 ; shift
    [ -f "$to" ] || die "Cannot append to '$to': file doesn't exist"
    $RUN cp -f "$to" "$BACKUP/"
    $RUN sh -c "cat \"$what\" >> \"$to\""
}

[ -d "$DOTFILES" ] || die "'$DOTFILES' is not a directory"
[ -d "$BACKUP" ] || $RUN mkdir -p "$BACKUP"

( cd "$DOTFILES" && find . -type f ! -path '*/.git/*' ) | while read f ; do
    src=`src_name "$f"`
    dst=`dst_name "$f"`
    if echo "$f" | grep -q '\.sh$' ; then
        continue
    fi
    if echo "$f" | grep -q '\.append$' ; then
        cmp_tail "$src" "$dst" || append_file "$src" "$dst"
    else
        link_file "$src" "$dst"
    fi
done
