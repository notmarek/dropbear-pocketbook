#!/bin/sh

# export ARCH=mips
export HOST="arm-pocketbook-linux-gnueabi"
COMP="$HOME/x-tools/arm-pocketbook-linux-gnueabi/bin/arm-pocketbook-linux-gnueabi"
TARGET="multi"
# export MULTI=1
# export STATIC=1
# Sets up toolchain environment variables for various mips toolchain
# cd dropbear_src && patch -p1 < ../pb_dropbear_2022.83.patch && cd ..
warn()
{
	echo "$1" >&2
}

if [ ! -z $(which $COMP-gcc) ];
then
	export CC=$(which $COMP-gcc)
else
	warn "Not setting CC: can't locate $COMP-gcc."
fi

if [ ! -z $(which $COMP-ld) ];
then
	export LD=$(which $COMP-ld)
else
	warn "Not setting LD: can't locate $COMP-ld."
fi

if [ ! -z $(which $COMP-ar) ];
then
	export AR=$(which $COMP-ar)
else
	warn "Not setting AR: can't locate $COMP-ar."
fi


if [ ! -z $(which $COMP-strip) ];
then
	export STRIP=$(which $COMP-strip)
else
	warn "Not setting STRIP: can't locate $COMP-strip."
fi

if [ ! -z $(which $COMP-nm) ];
then
	export NM=$(which $COMP-nm)
else
	warn "Not setting NM: can't lcoate $COMP-nm."
fi


make $TARGET || exit $?


# cd dropbear_src && patch -p1 -R < ../pb_dropbear_2022.83.patch
