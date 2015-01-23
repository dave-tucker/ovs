How to Install Open vSwitch on Mac OSX
======================================

This document describes how to build and install Open vSwitch on a Apple
Mac OSX host. 

> NOTE: Mac OS X support is limited to the ovs ctl commands only
> There is currently no support for an OSX netdev

We have tested this on OSX 10.10 Yosemite

Building Open vSwitch for OSX
------------------------------

Prerequisties
-------------

You MUST have the Xcode Command Line utilties installed.

Additionally you should have either Homebrew or MacPorts on your system.
These instructions assume the former.

Install GCC, Autoconf, Automake, Libtool and OpenSSL with the following
command:

    brew install gcc autoconf automake libtool openssl

Installing
----------

    ./boot.sh
    # You must set CC to whichever version of GCC Homebrew installed
    ./configure CC=gcc4.9 --with-openssl=/usr/local/opt/openssl
    make
    sudo make install

Usage
-----

You may manage an Open vSwitch on a remote system providing that it's
been configured to listen on `ptcp:6640`.

    ovs-vsctl set-manager ptcp:6640

From your OSX machine, you can configure a bridge and configure OpenFlow
to listen on port 6653:

    ovs-vsctl --db=tcp:192.168.59.103:6640 show
    ovs-vsctl --db=tcp:192.168.59.103:6640 add-br br0
    ovs-vsctl --db=tcp:192.168.59.103:6640 set-manager br0 ptcp:6653

To view the flows installed on your bridge, you can use the following command:

    ovs-ofctl -OOpenFlow13 dump-flows tcp:192.168.59.103:6653
