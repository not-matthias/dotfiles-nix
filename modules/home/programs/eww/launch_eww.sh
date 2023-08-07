#!/usr/bin/env bash

eww kill
eww daemon

# for i in $(xrandr --listactivemonitors| tail -n +2| cut -d':' -f 1); do
#     hyprctl dispatch focusmonitor "$i"
#     eww open bar  --screen "$i"
# done
# echo eww restarted

monitors=$(hyprctl monitors -j | jq '.[] | .id')
for monitor in ${monitors}; do
    eww open bar${monitor}
done
