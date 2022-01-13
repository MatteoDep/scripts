#!/bin/sh

bin_dir="$HOME/.local/bin"
if [ "$@" ]; then
    args=$@
else
    args=$(ls -A "$PWD")
fi

for f in $args; do
    if [ -f "$f" ] &&
        [ -x "$f" ] &&
        [ ! -e "$bin_dir/$f" ] &&
        [ "$f" != "$(basename "$0")" ]; then
        echo "linking $f"
        ln -srf "$PWD/$f" "$bin_dir/$f"
    fi
done
