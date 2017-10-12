#!/bin/bash
#
# This uses the osd_cat tool from package xosd-bin.
# That's what underlies the osdsh, but this works consistently
# Only the final argument is taken as a quoted string to pass to the osd_cat,
# all others are taken as arguments to the osd_cat command itself
#
# Supports pass thru of most osd_cat options, but sets defaults from a
# config file: osdcat_font.config


# pull the defaults from the file, they're passed to getopt first, so they
# can be overridden on the command line
DEFAULT_ARGS="$(cat $(dirname ${BASH_SOURCE})/osdcat_font.config)"

TEMP=`getopt --options p:A:f:c:d:l:s:S:O:u:b:P:T: --longoptions pos:,align:,font:,color:,delay:,lines:,shadow:,shadowcolor:,outline:,outlinecolor:,barmode:,percentage:,text: -n "my_osd_cat" -- ${DEFAULT_ARGS} "$@"`

OUTPUTSTR=
FINAL=false
BARMODE=false
MYARGS=()
eval set -- "${TEMP}"
while [ -n "$1" ]  ; do
    case $1 in
        -b|--barmode)
            BARMODE=true
            MYARGS+=($1 $2)
            shift 2
            ;;
        -p|--pos|-A|--align|-f|--font|-c|--color|-d|--delay|-l|--lines|-s|--shadow|-S|--shadowcolor|-O|--outline|-u|--outlinecolour|-P|--percentage|-T|--text)
            MYARGS+=($1 $2)
            shift 2
            ;;
        --)
            FINAL=true
            shift 1
            ;;
        *)
            if ${FINAL} ; then
                OUTPUTSTR="$1"
            else
                #should never get here, this is a getopt error
                echo >&2 "Error, bad string parsing"
                exit 1
            fi
            shift 1
            break
            ;;
    esac
done

# didn't have a "--" or got an empty string
if ! ${BARMODE} ; then
    if [ -z "${OUTPUTSTR}" ] || ! ${FINAL} ; then
        echo >&2 "Empty String"
        exit 1
    elif [ ${#OUTPUTSTR} -ge 7 ] ; then
        # The input buffer for osd_cat seems to be really small, so at large
        # text sizes we have to tell it to wait on new text lines or it will
        # simply not print anything at all
        MYARGS+=(-w)
    fi
fi

echo -e "${OUTPUTSTR}" | osd_cat ${MYARGS[@]} ${TEMP_FILE} &

