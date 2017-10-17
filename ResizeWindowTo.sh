#!/bin/bash

W=$1
H=$2
WID=`xdotool getactivewindow`

# offset xdotool always applies this
DISPLAY_OFFSET_X=1
DISPLAY_OFFSET_Y=35

# This is a limit to account for the taskbar
TASKBAR_OFFSET_X=0
TASKBAR_OFFSET_Y=0
TASKBAR_OFFSET_W=20
TASKBAR_OFFSET_H=0

T_OFFSET_X=`expr "$DISPLAY_OFFSET_X" "+" "$TASKBAR_OFFSET_X"`
T_OFFSET_Y=`expr "$DISPLAY_OFFSET_Y" "+" "$TASKBAR_OFFSET_Y"`

#xdotool doesn't support a percentage properly
#for the windowsize command, so we need to calculate it manually

# Get the display size
DISPLAY_SIZE=`xwininfo -root | grep geometry | grep -oE "[0-9]+x[0-9]+"`
DISPLAY_SIZE_W=`echo $DISPLAY_SIZE | sed -e 's@x[0-9]*@@g'`
DISPLAY_SIZE_H=`echo $DISPLAY_SIZE | sed -e 's@[0-9]*x@@g'`

# Moving a window always ends up applying an offset after the move command of
# (DISPLAY_OFFSET_X,DISPLAY_OFFSET_Y)
# so make sure our display sizes account for it
DISPLAY_SIZE_W=`expr "$DISPLAY_SIZE_W" "-" "$T_OFFSET_X" "-" "$TASKBAR_OFFSET_W"`
DISPLAY_SIZE_H=`expr "$DISPLAY_SIZE_H" "-" "$T_OFFSET_Y" "-" "$TASKBAR_OFFSET_H"`

# Is it a percentage?
if [[ $W = *% ]] ; then
    W=`echo "$W" | sed -e 's@%@@g'`
    W=`expr "${DISPLAY_SIZE_W}" "*" "$W" "/" "100"`
fi

# Is it a percentage?
if [[ $H = *% ]] ; then
    H=`echo "$H" | sed -e 's@%@@g'`
    H=`expr "${DISPLAY_SIZE_H}" "*" "$H"  "/" "100"`
fi

# Save our current position
X=`xdotool getwindowgeometry --shell $WID | grep "X=" | grep -oE '[0-9]+'`
Y=`xdotool getwindowgeometry --shell $WID | grep "Y=" | grep -oE '[0-9]+'`

# Make sure our width and height don't exceed the desktop size
if [ $W -gt $DISPLAY_SIZE_W ] ; then
    W=$DISPLAY_SIZE_W
fi
if [ $H -gt $DISPLAY_SIZE_H ] ; then
    H=$DISPLAY_SIZE_H
fi

# Get the opposite edge positions of the window
X_RIGHT=`expr "$X" "+" "$W"`
Y_BOTTOM=`expr "$Y" "+" "$H"`

# Move the window to make sure the edges of the window don't go off the
# desktop
if [ $X_RIGHT -gt $DISPLAY_SIZE_W ] ; then
    X=`expr "$X" "-" "(" "$X_RIGHT" "-" "$DISPLAY_SIZE_W" ")"`
    SET_POS=true
fi
if [ $Y_BOTTOM -gt $DISPLAY_SIZE_H ] ; then
    Y=`expr "$Y" "-" "(" "$Y_BOTTOM" "-" "$DISPLAY_SIZE_H" ")"`
    SET_POS=true
fi

# Force account for the display offset that's going to be applied
if [ $X -lt $T_OFFSET_X ] ; then
    X=$T_OFFSET_X
fi

if [ $Y -lt $T_OFFSET_Y ] ; then
    Y=$T_OFFSET_Y
fi

# windowmove command applies a fixed offset to whatever we give it, we've already accounted for it
MY_USED_X=`expr "$X" "-" "$DISPLAY_OFFSET_X"`
MY_USED_Y=`expr "$Y" "-" "$DISPLAY_OFFSET_Y"`

# The windowsize command frequently doesn't work right, and won't actually set to the requested
# size.  We need to loop checking the actual size until it matches what we requested
# WARNING: sometimes this never works until the window loses focus
echo "--------------Resizing window $WID" >> ~/.resize_log
while true ; do
    # In case we need to move the window to keep the new size on the desktop,
    # do so first.  If it didn't need to be moved, it won't be
    xdotool windowmove --sync $WID $MY_USED_X $MY_USED_Y windowsize --sync $WID $W $H exec sleep 1
    CUR_X=`xdotool getwindowgeometry --shell $WID | grep "X=" | grep -oE '[0-9]+'`
    CUR_Y=`xdotool getwindowgeometry --shell $WID | grep "Y=" | grep -oE '[0-9]+'`
    CUR_W=`xdotool getwindowgeometry --shell $WID | grep "WIDTH=" | grep -oE '[0-9]+'`
    CUR_H=`xdotool getwindowgeometry --shell $WID | grep "HEIGHT=" | grep -oE '[0-9]+'`

    echo "Desired: ($X,$Y)($W,$H) Actual: ($CUR_X,$CUR_Y)($CUR_W,$CUR_H)" >> ~/.resize_log
    
    if [ $CUR_X -eq $X ] && [ $CUR_Y -eq $Y ] && [ $CUR_W -eq $W ] && [ $CUR_H -eq $H ] ; then
        break
    fi
done


