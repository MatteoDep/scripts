#!/bin/sh
# Lock before suspend integration with elogind

username=matteo
userhome=/home/$username
export XAUTHORITY="/run/user/1000/Xauthority"
export DISPLAY=":1"
case "${1}" in
    pre)
        su $username -c "$userhome/.local/bin/scripts/lock"
        sleep 1s
        ;;
esac
