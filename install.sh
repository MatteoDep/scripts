#!/bin/sh

dest_dir="$HOME/.local/bin"

for f in $(ls -A "$PWD"); do
    if [ -f "$f" -a -x "$f" -a ! -e "$PWD/$f" ]; then
        echo "linking $f"
        ln -srf "$PWD/$f" "$dest_dir/$f"
    fi
done
