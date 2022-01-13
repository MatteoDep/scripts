#!/bin/sh

bin_dir="$HOME/.local/bin"
if [ "$@" ]; then
    args=$@
else
    args=$(ls -A "$PWD")
fi


for f in $args; do
    if [ -h "$bin_dir/$f" ]; then
        echo "unlinking $f"
        rm "$bin_dir/$f"
    fi
done
