#!/bin/sh -xe

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
export GYP_DEFINES="build_with_libjingle=1 build_with_chromium=0 libjingle_objc=1"
export GYP_GENERATORS="ninja"
export GYP_DEFINES="$GYP_DEFINES OS=ios target_arch=armv7"
export GYP_GENERATOR_FLAGS="output_dir=out_ios"
export GYP_CROSSCOMPILE=1
gclient runhooks
ninja -C out_ios/Debug libjingle_peerconnection_objc_test

