#!/bin/bash

set -x
set -o errexit 

KERNELSRC=""
CFLAGS="-Werror"
EXTRA_OPTS=""

function install_kernel()
{
    if [[ "$1" =~ ^3.* ]]; then
        PREFIX="v3.x"
    else
        PREFIX="v2.6/longterm/v2.6.32"
    fi

    wget https://www.kernel.org/pub/linux/kernel/${PREFIX}/linux-${1}.tar.gz
    tar xzvf linux-${1}.tar.gz > /dev/null
    cd linux-${1}
    make allmodconfig

    # Older kernels do not include openvswitch
    if [ -d "net/openvswitch" ]; then
        make net/openvswitch/
    else
        make net/bridge/
    fi

    KERNELSRC=$(pwd)
    if [ ! "$DPDK" ]; then
        EXTRA_OPTS="--with-linux=$(pwd)"
    fi
    echo "Installed kernel source in $(pwd)"
    cd ..
}

function install_dpdk()
{
    if [ -n "$DPDK_GIT" ]; then
	git clone $DPDK_GIT dpdk-$1
	cd dpdk-$1
	git checkout v$1
    else
        wget http://www.dpdk.org/browse/dpdk/snapshot/dpdk-$1.tar.gz
        tar xzvf dpdk-$1.tar.gz > /dev/null
        cd dpdk-$1
    fi
    find ./ -type f | xargs sed -i 's/max-inline-insns-single=100/max-inline-insns-single=400/'
    sed -ri 's,(CONFIG_RTE_BUILD_COMBINE_LIBS=).*,\1y,' config/common_linuxapp
    sed -ri '/CONFIG_RTE_LIBNAME/a CONFIG_RTE_BUILD_FPIC=y' config/common_linuxapp
    sed -ri '/EXECENV_CFLAGS  = -pthread -fPIC/{s/$/\nelse ifeq ($(CONFIG_RTE_BUILD_FPIC),y)/;s/$/\nEXECENV_CFLAGS  = -pthread -fPIC/}' mk/exec-env/linuxapp/rte.vars.mk
    make config CC=gcc T=x86_64-native-linuxapp-gcc
    make CC=gcc RTE_KERNELDIR=$KERNELSRC
    echo "Installed DPDK source in $(pwd)"
    cd ..
}

function configure_ovs()
{
    ./boot.sh && ./configure $*
}

if [ "$KERNEL" ] || [ "$DPDK" ]; then
    install_kernel $KERNEL
fi

if [ "$DPDK" ]; then
    if [ -z "$DPDK_VER" ]; then
	    DPDK_VER="1.7.1"
    fi
    install_dpdk $DPDK_VER
    # Disregard bad function cassts until DPDK is fixed
    CFLAGS="$CFLAGS -Wno-error=bad-function-cast -Wno-error=cast-align"
    EXTRA_OPTS+="--with-dpdk=./dpdk-$DPDK_VER/build"
    if [ "$CC" != "clang" ]; then
        # DPDK headers currently trigger sparse errors
        CFLAGS="$CFLAGS -Wsparse-error"
    fi
fi

if [ "$TRAVIS_OS_NAME" = "osx" ]; then
    EXTRA_OPTS="--with-openssl=/usr/local/opt/openssl/lib"
fi

configure_ovs $EXTRA_OPTS $*

# Only build datapath if we are testing kernel w/o running testsuite
if [ "$KERNEL" ] && [ ! "$TESTSUITE" ] && [ ! "$DPDK" ]; then
    cd datapath
fi

if [ "$CC" = "clang" ]; then
    make CFLAGS="$CFLAGS -Wno-error=unused-command-line-argument"
elif [ "$TRAVIS_OS_NAME" = "osx" ]; then
    # OSX doesn't have sparse so don't use C=1
    make CFLAGS="$CFLAGS"
else
    make CFLAGS="$CFLAGS" C=1
fi

if [ "$TESTSUITE" ] && [ "$CC" != "clang" ]; then
    if ! make distcheck; then
        # testsuite.log is necessary for debugging.
        cat */_build/tests/testsuite.log
        exit 1
    fi
fi

exit 0
