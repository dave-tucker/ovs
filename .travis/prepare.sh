#!/bin/bash

if [ "$TRAVIS_OS_NAME" = "osx" ]; then
    brew install coreutils openssl md5sha1sum
    if [ "$CC" = "clang" ]; then
        brew install llvm --with-clang
	sudo mv /usr/bin/clang /usr/bin/clang.old
	sudo ln -s /usr/local/opt/llvm/bin/clang /usr/bin/clang
    else
        brew install gcc
	sudo mv /usr/bin/gcc /usr/bin/gcc.old
	sudo ln -s /usr/local/bin/gcc-4.9 /usr/bin/gcc
    fi
    exit 0
fi

sudo apt-get update -qq
sudo apt-get install -qq libssl-dev llvm-dev

git clone git://git.kernel.org/pub/scm/devel/sparse/chrisl/sparse.git
cd sparse && make && sudo make install PREFIX=/usr && cd ..
