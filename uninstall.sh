#!/bin/sh

bin_dir="$HOME/.local/bin"
if [ $# -eq 0 ]; then
    set -- $(ls -A "$PWD")
fi

for f in "$@"; do
    if [ -h "$bin_dir/$f" ]; then
        echo "unlinking $f"
        rm "$bin_dir/$f"
    fi
done
