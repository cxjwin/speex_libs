#!/bin/sh

#  build_speex_ios.sh
#  
#
#  Created by cxjwin on 15-4-19.
#

set -xe

DEVELOPER=`xcode-select -print-path`
ROOTDIR=`pwd`
OGG=${ROOTDIR}/../speexLibrary/libogg-1.3.2
DEST=${ROOTDIR}/../speexLibrary/speex-1.2rc2

ARCHS="i386 x86_64 armv7 armv7s arm64"
LIBS="libspeex.a"

for arch in $ARCHS;
do
    mkdir -p $DEST/$arch
done

# --with-ogg是关联之前得libogg库
for arch in $ARCHS;
do  
    make clean
    IOSMV="-miphoneos-version-min=5.0"
    case $arch in
    arm*)  
        echo "Building opencore-amr for iPhoneOS $arch ****************"
        if [ $arch == "arm64" ]
        then
            IOSMV="-miphoneos-version-min=7.0"
        fi
        PATH=`xcodebuild -version -sdk iphoneos PlatformPath`"/Developer/usr/bin:$PATH" \
        SDK=`xcodebuild -version -sdk iphoneos Path` \
        CC="xcrun --sdk iphoneos clang -arch $arch $IOSMV --sysroot=$SDK -isystem $SDK/usr/include" \
        CXX="xcrun --sdk iphoneos clang++ -arch $arch $IOSMV --sysroot=$SDK -isystem $SDK/usr/include" \
        LDFLAGS="-Wl,-syslibroot,$SDK" \
        ./configure \
        --host=arm-apple-darwin \
        --prefix=$DEST/$arch \
        --with-ogg=${OGG}/$arch
        ;;
    *)
        echo "Building opencore-amr for iPhoneSimulator $arch *****************"
        PATH=`xcodebuild -version -sdk iphonesimulator PlatformPath`"/Developer/usr/bin:$PATH" \
        CC="xcrun --sdk iphonesimulator clang -arch $arch $IOSMV" \
        CXX="xcrun --sdk iphonesimulator clang++ -arch $arch $IOSMV" \
        ./configure \
        --prefix=$DEST/$arch \
        --with-ogg=${OGG}/$arch
        ;;
    esac
    make -j
    make install
done

make clean

echo "Merge into universal binary."

for i in $LIBS; 
do
    input=""
    for arch in $ARCHS; 
    do
        input="$input $DEST/$arch/lib/$i"
    done
    lipo -create $input -output $DEST/$i 
done 