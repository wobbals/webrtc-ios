#!/bin/bash -xe

#
# This script automates the build process described by webrtc:
# https://code.google.com/p/webrtc/source/browse/trunk/talk/app/webrtc/objc/README
#
PWD=`pwd`
ROOT=$PWD
WEBRTC_ROOT=$ROOT/trunk

if [ -z $CONFIGURATION ]; then
    CONFIGURATION=Release
fi
gclient config http://webrtc.googlecode.com/svn/trunk
echo "target_os = ['mac']" >> .gclient
gclient revert
gclient sync
perl -i -wpe "s/target\_os \= \[\'mac\'\]/target\_os \= \[\'ios\', \'mac\']/g" .gclient
gclient sync
export OUTPUT_DIR=out_sim
cd $WEBRTC_ROOT
export GYP_DEFINES="\
build_with_libjingle=1 \
build_with_chromium=0 \
libjingle_objc=1 \
OS=ios \
target_arch=ia32 \
enable_tracing=1"
export GYP_GENERATORS="ninja"
export GYP_GENERATOR_FLAGS="output_dir=$OUTPUT_DIR"
export GYP_CROSSCOMPILE=1
if [ -d $OUTPUT_DIR ]; then
    rm -rf $OUTPUT_DIR
fi
if [ -d out.huge ]; then
    rm -rf out.huge
fi
# hop up one level and apply patches before continuing
cd $ROOT
PATCHES=`find $PWD/patches -name *.diff`
for PATCH in $PATCHES; do
    git apply $PATCH || { echo "patch $PATCH failed to patch! panic and die!" ; exit 1; }
done

cd $WEBRTC_ROOT
gclient runhooks
ninja -v -C $OUTPUT_DIR/$CONFIGURATION AppRTCDemo || { echo "ninja build failed. booooooooo."; }

AR=`xcrun -f ar`

LIBS_OUT=`find $PWD/$OUTPUT_DIR/$CONFIGURATION -d 1 -name '*.a'`
FATTYCAKES_OUT=out.huge
rm -rf $FATTYCAKES_OUT || echo "clean $FATTYCAKES_OUT"
mkdir -p $FATTYCAKES_OUT
cd $FATTYCAKES_OUT
for LIB in $LIBS_OUT
do
    $AR -x $LIB
done
$AR -q libfattycakes.a *.o
cd $WEBRTC_ROOT

ARTIFACT=$OUTPUT_DIR/artifact
rm -rf $ARTIFACT || echo "clean $ARTIFACT"
mkdir -p $ARTIFACT/lib
mkdir -p $ARTIFACT/include
cp $FATTYCAKES_OUT/libfattycakes.a $OUTPUT_DIR/artifact/lib
HEADERS_OUT=`find net talk third_party webrtc -name *.h`
for HEADER in $HEADERS_OUT
do
    HEADER_DIR=`dirname $HEADER`
    mkdir -p $ARTIFACT/include/$HEADER_DIR
    cp $HEADER $ARTIFACT/include/$HEADER
done

cd $WEBRTC_ROOT
REVISION=`svn info $BRANCH | grep Revision | cut -f2 -d: | tr -d ' '`
echo "WEBRTC_REVISION=$REVISION" > build.properties

cd $ARTIFACT
tar cjf fattycakes-$REVISION.tar.bz2 lib include
