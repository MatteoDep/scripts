#!/bin/sh

dest_dir="$HOME/.local/bin"

for f in $(ls -A "$PWD"); do
    if [ -f "$f" ] &&
        [ -x "$f" ] &&
        [ ! -e "$dest_dir/$f" ] &&
        [ "$f" != "$(basename "$0")" ]; then
        echo "linking $f"
        ln -srf "$PWD/$f" "$dest_dir/$f"
    fi
done
