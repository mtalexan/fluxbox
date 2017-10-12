#!/bin/sh
# Extracts the current desktop name and echos it to an xargs wrapping any
# command line arguments provided.  If no command line arguments are provided
# it will simply print the desktop name

xprop -root _NET_CURRENT_DESKTOP _NET_NUMBER_OF_DESKTOPS _NET_DESKTOP_NAMES | awk '
         # use the equals sign (with optional spaces around it) as the separator
         BEGIN { FS="[[:space:]]*=[[:space:]]*"; }

         # the number returned is a 0 based index and we need a 1 based index
         /_NET_CURRENT_DESKTOP/ { current=$2+1; }
         /_NET_NUMBER_OF_DESKTOPS/ { no_wspaces=$2; }
         /_NET_DESKTOP_NAMES/ {
            # workspaces are double quoted and separated by commas, so split into array (indexed from 1)
            split($2,names,",[[:space:]]*");
            # cleanup the names to remove problematic characters
            for (i=1; i < no_wspaces; i++) {
               gsub("\"|,","", names[i]);
            };
         }

         # the actual printing fo what we want to output
         END { print "\""names[current]"\"" };' | xargs "$@"


