#!/bin/sh
if sudo 2>/dev/null; then
    sudo_cmd="sudo"
else
    sudo_cmd="doas"
fi

scriptsdir=$(dirname "$(dirname "$(whereis $0 | awk '{print $2}')")")
bindir="/usr/bin"
datadir="${XDG_DATA_HOME:-"$HOME/.local/share"}"

if [ "$1" = "-f" ]; then
    rm "$datadir/icons"
    $sudo_cmd rm "$bindir/dmenu"
    $sudo_cmd rm "$bindir/dmenu_run"
    $sudo_cmd rm /usr/lib/elogind/system-sleep/lock-at-suspend.sh
fi

cp "$scriptsdir"/resources/icons "$datadir"
$sudo_cmd cp "$scriptsdir"/fzfmenu "$bindir"/dmenu
$sudo_cmd cp "$scriptsdir"/fzfmenu_run "$bindir"/dmenu_run
$sudo_cmd cp "$scriptsdir"/resources/lock-at-suspend.sh /usr/lib/elogind/system-sleep/
