#!/bin/bash -xe

#
# This script automates the build process described by webrtc:
# https://code.google.com/p/webrtc/source/browse/trunk/talk/app/webrtc/objc/README
#

gclient config http://webrtc.googlecode.com/svn/trunk
echo "target_os = ['mac']" >> .gclient
gclient sync
perl -i -wpe "s/target\_os \= \[\'mac\'\]/target\_os \= \[\'ios\', \'mac\']/g" .gclient
gclient sync
cd trunk
export GYP_DEFINES="build_with_libjingle=1 build_with_chromium=0 libjingle_objc=1 OS=ios target_arch=armv7 enable_tracing=1"
export GYP_GENERATORS="ninja"
export GYP_GENERATOR_FLAGS="output_dir=out_ios"
export GYP_CROSSCOMPILE=1
gclient runhooks
ninja -C out_ios/Debug -t clean
ninja -C out_ios/Debug libjingle_peerconnection_objc_test

AR=`xcrun -f ar`
PWD=`pwd`
ROOT=$PWD
LIBS_OUT=`find $PWD/out_ios/Debug -d 1 -name '*.a'`
FATTYCAKES_OUT=out.huge
rm -rf $FATTYCAKES_OUT || echo "clean $FATTYCAKES_OUT"
mkdir -p $FATTYCAKES_OUT
cd $FATTYCAKES_OUT
for LIB in $LIBS_OUT
do
    $AR -x $LIB
done
$AR -q libfattycakes.a *.o
cd $ROOT

ARTIFACT=out_ios/artifact
rm -rf $ARTIFACT || echo "clean $ARTIFACT"
mkdir -p $ARTIFACT/lib
mkdir -p $ARTIFACT/include
cp $FATTYCAKES_OUT/libfattycakes.a out_ios/artifact/lib
HEADERS_OUT=`find net talk third_party webrtc -name *.h`
for HEADER in $HEADERS_OUT
do
    HEADER_DIR=`dirname $HEADER`
    mkdir -p $ARTIFACT/include/$HEADER_DIR
    cp $HEADER $ARTIFACT/include/$HEADER
done

cd $ROOT
REVISION=`svn info $BRANCH | grep Revision | cut -f2 -d: | tr -d ' '`
echo "WEBRTC_REVISION=$REVISION" > build.properties

cd $ARTIFACT
tar cjf fattycakes-$REVISION.tar.bz2 lib include


