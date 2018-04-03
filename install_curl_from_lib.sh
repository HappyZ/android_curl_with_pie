#!/usr/bin/env bash

echo "Make sure /system/ is writable"

PREFIX=./android_curl_lib

function adbpush() {
    if [ -f "$1" ] ; then
        adb push $1 /sdcard
        adb shell "su -c 'mv /sdcard/$1 /system/lib/'"
    else
         echo "'$1' is not a valid file"
    fi
}

cd $PREFIX/bin
adb push curl /sdcard/
adb shell "su -c 'mv /sdcard/curl /system/bin/ && chown root:shell /system/bin/curl && chmod +x /system/bin/curl'"
adb push openssl /sdcard/
adb shell "su -c 'mv /sdcard/openssl /system/bin/ && chown root:shell /system/bin/openssl && chmod +x /system/bin/openssl'"

cd ../../

cd $PREFIX/lib
adbpush libcurl.so
adbpush libssl.so.1.0.0
adbpush libcrypto.so.1.0.0
