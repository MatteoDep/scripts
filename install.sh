#!/bin/sh

bin_dir="$HOME/.local/bin"
mkdir -p "$bin_dir"
if [ $# -eq 0 ]; then
    set -- $(ls -A "$PWD")
fi

for f in "$@"; do
    if [ -f "$f" ] &&
        [ -x "$f" ] &&
        [ ! -e "$bin_dir/$f" ] &&
        [ "$f" != "$(basename "$0")" ]; then
        echo "linking $f"
        ln -srf "$PWD/$f" "$bin_dir/$f"
    fi
done
