#!/bin/sh
scriptsdir=$(dirname "$(dirname "$(whereis $0 | awk '{print $2}')")")
echo "$scriptsdir"
ln -s "$scriptsdir"/resources/icons ~/.local/share/
sudo ln -sf "$scriptsdir"/fzfmenu /usr/bin/dmenu
sudo ln -sf "$scriptsdir"/fzfmenu_run /usr/bin/dmenu_run
