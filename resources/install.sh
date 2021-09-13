#!/bin/sh
scriptsdir=$(dirname "$(dirname "$(whereis $0 | awk '{print $2}')")")
ln -s "$scriptsdir"/resources/icons ~/.local/share/
sudo ln -sf "$scriptsdir"/fzfmenu /usr/bin/dmenu
sudo ln -sf "$scriptsdir"/fzfmenu_run /usr/bin/dmenu_run
sudo ln -sf "$scriptsdir"/resources/lock-at-suspend.sh /usr/lib/elogind/system-sleep/
