#!/bin/bash

SOURCE_DIR="$(pwd)"
CROSSARCH="arm"
CROSSCC="$CROSSARCH-eabi-"
NRJOBS=$(( $(nproc) * 2 ))
TOOLCHAIN_D="$(pwd)/../tc/"
TOOLCHAIN="$(pwd)/../tc/4.7/bin"
USERCCDIR="$HOME/.ccache"
OUT_DIR="$(pwd)/out"

OUT_ENABLED=1;
if [ ! -d "$OUT_DIR" ]; then
    echo "[BUILD]: Directory '$OUT_DIR' which is configure as output 
directory does not exist!";
    VALID=0;
    while [[ $VALID -eq 0 ]]
    do
        echo "[Y|y] Create it.";
        echo "[N|n] Don't create it, this will disable the output 
directory.";
        echo "Choose an option:";
        read DECISION;
        case "$DECISION" in
            y|Y)
            VALID=1;
            echo "Creating directory $OUT_DIR...";
            mkdir $OUT_DIR
            mkdir $OUT_DIR/kernel
            mkdir $OUT_DIR/modules
            ;;
            n|N)
            VALID=1;
            OUT_ENABLED=0;
            echo "Disabling output directory...";
            ;;
            *)
            echo "Error: Unknown input ($DECISION), try again.";
        esac
    done
else
    if [ ! -d "$OUT_DIR/kernel" ]; then
        echo "Creating directory $OUT_DIR/kernel...";
        mkdir $OUT_DIR/kernel
    fi
    if [ ! -d "$OUT_DIR/modules" ]; then
        echo "Creating directory $OUT_DIR/modules...";
        mkdir $OUT_DIR/modules
    fi
fi

###CCACHE CONFIGURATION STARTS HERE, DO NOT MESS WITH IT!!!
TOOLCHAIN_CCACHE="$TOOLCHAIN/../bin-ccache"
gototoolchain() {
  echo "[BUILD]: Changing directory to $TOOLCHAIN/../ ...";
  cd $TOOLCHAIN/../
}

gototoolchaind() {
  echo "[BUILD]: Changing directory to $TOOLCHAIN_D ...";
  cd $TOOLCHAIN_D
}

gotocctoolchain() {
  echo "[BUILD]: Changing directory to $TOOLCHAIN_CCACHE...";
  cd $TOOLCHAIN_CCACHE
}

#check ccache configuration
#if not configured, do that now.
if [ ! -d "$TOOLCHAIN_CCACHE" ]; then
    echo "[BUILD]: CCACHE: not configured! Doing it now...";
    gototoolchain
    mkdir bin-ccache
    gotocctoolchain
    ln -s $(which ccache) "$CROSSCC""gcc"
    ln -s $(which ccache) "$CROSSCC""g++"
    ln -s $(which ccache) "$CROSSCC""cpp"
    ln -s $(which ccache) "$CROSSCC""c++"
    ln -s $(which ccache) "$CROSSCC""strip"
    gototoolchain
    chmod -R 777 bin-ccache
    echo "[BUILD]: CCACHE: Done...";
fi
export CCACHE_DIR=$USERCCDIR
###CCACHE CONFIGURATION ENDS HERE, DO NOT MESS WITH IT!!!

echo "[BUILD]: Setting cross compile env vars...";
SAVEDPATH=$PATH;
SAVEDCROSS_COMPILE=$CROSS_COMPILE;
SAVEDARCH=$ARCH;
export ARCH=$CROSSARCH
export CROSS_COMPILE=$CROSSCC
export PATH=$TOOLCHAIN_CCACHE:${PATH}:$TOOLCHAIN

gotosource() {
  echo "[BUILD]: Changing directory to $SOURCE_DIR...";
  cd $SOURCE_DIR
}

gotoout() {
    if [[ ! $OUT_ENABLED -eq 0 ]]; then
        echo "[BUILD]: Changing directory to $OUT_DIR...";
        cd $OUT_DIR;
    fi
}


gotosource
	
#build the kernel
echo "[BUILD]: Cleaning kernel (make mrproper)...";
make mrproper

echo "[BUILD]: Using defconfig: afyon...";
make boosted_defconfig VARIANT_DEFCONFIG=msm8926-sec_afyonltetmo_defconfig
echo "[BUILD]: Bulding the kernel...";
time make -j$NRJOBS || { return 1; }
echo "[BUILD]: Done with kernel!...";

    gotosource

    #copy stuff for our zip
    echo "[BUILD]: Copying kernel (zImage) to $OUT_DIR/kernel/...";
    cp arch/arm/boot/zImage $OUT_DIR/kernel/
    echo "[BUILD]: Copying modules (*.ko) to $OUT_DIR/modules/...";
    find $SOURCE_DIR/ -name \*.ko -exec cp '{}' $OUT_DIR/modules/ ';'
    echo "[BUILD]: Stripping modules";
    "$CROSSCC""strip" --strip-unneeded $OUT_DIR/modules/*.ko;
    echo "[BUILD]: Done!...";

echo "[BUILD]: All done!...";
gotosource
export PATH=$SAVEDPATH 
export CROSS_COMPILE=$SAVEDCROSS_COMPILE;
export ARCH=$SAVEDARCH;
