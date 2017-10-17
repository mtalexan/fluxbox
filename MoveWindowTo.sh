#!/bin/bash

X=$1
Y=$2

DISPLAY_OFFSET_X=1
DISPLAY_OFFSET_Y=35

#xdotool doesn't support a percentage
#for the windowmove command, so we need to calculate it

# Get the display size
DISPLAY_SIZE=`xwininfo -root | grep geometry | grep -oE "[0-9]+x[0-9]+"`
DISPLAY_SIZE_W=`echo $DISPLAY_SIZE | sed -e 's@x[0-9]*@@g'`
DISPLAY_SIZE_H=`echo $DISPLAY_SIZE | sed -e 's@[0-9]*x@@g'`

# Moving a window always ends up applying an offset after the move command of
# (DISPLAY_OFFSET_X,DISPLAY_OFFSET_Y)
# so make sure our display sizes account for it
DISPLAY_SIZE_W=`expr "$DISPLAY_SIZE_W" "-" "$DISPLAY_OFFSET_X"`
DISPLAY_SIZE_H=`expr "$DISPLAY_SIZE_H" "-" "$DISPLAY_OFFSET_Y"`


# Is it a percentage?
if [[ $X = *% ]] ; then
    X=`echo "$X" | sed -e 's@%@@g'`
    X=`expr "${DISPLAY_SIZE_W}" "*" "$X" "/" "100"`
fi

# Is it a percentage?
if [[ $Y = *% ]] ; then
    Y=`echo "$Y" | sed -e 's@%@@g'`
    Y=`expr "${DISPLAY_SIZE_H}" "*" "$Y"  "/" "100"`
fi

# Force account for the display offset that's going to be applied
if [ $X -lt $DISPLAY_OFFSET_X ] ; then
    X=$DISPLAY_OFFSET_X
fi

if [ $Y -lt $DISPLAY_OFFSET_Y ] ; then
    Y=$DISPLAY_OFFSET_Y
fi

# windowmove command applies a fixed offset to whatever we give it, we've already accounted for it
MY_USED_X=`expr "$X" "-" "$DISPLAY_OFFSET_X"`
MY_USED_Y=`expr "$Y" "-" "$DISPLAY_OFFSET_Y"`

#echo "Moving to $X $Y"
xdotool getactivewindow windowmove --sync $MY_USED_X $MY_USED_Y
