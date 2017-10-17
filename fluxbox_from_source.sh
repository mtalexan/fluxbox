#!/bin/bash

# clone it
if [ ! -e fluxbox ] ; then
    git clone git://git.fluxbox.org/fluxbox.git
    if [ $? -ne 0 ] ; then
        echo "Unable to clone git://git.fluxbox.org/fluxbox.git"
        exit 1
    fi
fi

# go into it
cd fluxbox

# get the commit hash from the master branch
COMMIT_HASH=`git log -n 1 --oneline | awk '{print $1}'`

# Make sure we have the dependencies
sudo apt-get -y libxinerama-dev libxpm-dev libxft-dev libimlib2 libimlib2-dev libx11-dev
if [ $? -ne 0 ] ; then
    echo "Error getting development packages"
    exit 1
fi

# This is newer and creates the configure file
./autogen.sh
if [ $? -ne 0 ] ; then
    echo "Couldn't autogen"
    exit 1
fi

# The last release version is in the configure --help output
VERSION=`./configure --help=short | head -n1 | awk '{print $NF}' | sed -e "s@:@@g"`

# Configure with everything enabled and writing to /usr/local/bin
./configure --enable-xpm --enable-xmb --enable-xinerama --enable-xft --enable-randr --enable--toolbar --enable-systemtray --enable-slit --enable-shape --enable-render --enable-remember --enable-nls --enable-imlib2 --enable-ewmh --enable-bidi --program-suffix=-${VERSION}_${COMMIT_HASH}
if [ $? -ne 0 ] ; then
    echo "Configure failed"
    exit 1
fi

make
if [ $? -ne 0 ] ; then
    echo "build failed"
    exit 1
fi

DEFAULT_INSTALL=`which fluxbox`
if [ -n "${DEFAULT_INSTALL}" ] ; then
    DEFAULT_INSTALL=$(dirname $(readlink -e ${DEFAULT_INSTALL})/)
fi

sudo make install
if [ $? -ne 0 ] ; then
    echo "Unable to install"
    exit 1
fi

TOOLS=(fbsetroot fluxbox-remote fluxbox-update_configs fbrun fbsetbg fluxbox-generate_menu startfluxbox)

LINK_LOCATION=/usr/local/bin

# Don't have it setup for our alternatives currently?
if [ -z "$(update-alternatives --list fluxbox)" ] && [ -n "${DEFAULT_INSTALL}" ] ; then
    SLAVE_LIST=()
    for T in "${TOOLS[@]}" ; do
        SLAVE_LIST+=("--slave ${LINK_LOCATION}/$T $T ${DEFAULT_INSTALL}/$T")
    done

    sudo update-alternatives --install ${LINK_LOCATION}/fluxbox fluxbox ${DEFAULT_INSTALL}/$T 50 ${SLAVE_LIST[@]}
fi

NEW_INSTALL=/usr/local/bin

#Add our build to the update-alternatives list
SLAVE_LIST=()
for T in "${TOOLS[@]}" ; do
    SLAVE_LIST+=("--slave ${LINK_LOCATION}/$T $T ${NEW_INSTALL}/$T-${VERSION}_${COMMIT_HASH}")
done
sudo update-alternatives --install ${LINK_LOCATION}/fluxbox fluxbox ${NEW_INSTALL}/$T-${VERSION}_${COMMIT_HASH} 50 ${SLAVE_LIST[@]}
