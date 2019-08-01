#!/bin/sh

# /etc/X11/xinit/xinitrc
#
# global xinitrc file, used by all X sessions started by xinit (startx)

compton -b --config ~/.config/compton/compton.conf &
(mkdir -p /tmp/keyboard_info/ && touch /tmp/keyboard_info/kill &&
  sleep 1.0 && keyboard_setup) &
low_battery_notify &
notify_setup &
default_monitor &
auto_default_monitor &
flashfocus &
# if [ -f ~/.video_bg ]; then
#   (sleep 1 && run_xwin_vid ~/.video_bg) &
# fi
unclutter -idle 1.0 -root &
hsetroot -solid "#1d2021"

# invoke global X session script
. /etc/X11/Xsession